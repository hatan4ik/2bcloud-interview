#!/bin/bash

# Exit on errors
set -euo pipefail

# Fetch the current subscription ID
SUBSCRIPTION_ID=$(az account show --query "id" -o tsv)

# Retrieve all AKS clusters in the current subscription
AKS_CLUSTERS=($(az aks list --subscription "$SUBSCRIPTION_ID" --query "[].{name:name, resourceGroup:resourceGroup}" -o tsv))

# Check if any AKS clusters exist
if [ ${#AKS_CLUSTERS[@]} -eq 0 ]; then
  echo "Error: No AKS clusters found in the current subscription."
  exit 1
fi

# Automatically select if only one AKS cluster is present
if [ ${#AKS_CLUSTERS[@]} -eq 2 ]; then
  CLUSTER_NAME="${AKS_CLUSTERS[0]}"
  MAIN_RESOURCE_GROUP="${AKS_CLUSTERS[1]}"
else
  echo "Multiple AKS clusters found. Please select one:"
  for ((i=0; i<${#AKS_CLUSTERS[@]}; i+=2)); do
    echo "$((i/2+1)). Cluster: ${AKS_CLUSTERS[i]}, Resource Group: ${AKS_CLUSTERS[i+1]}"
  done
  read -rp "Enter the number of the AKS cluster you want to troubleshoot: " selection
  CLUSTER_NAME="${AKS_CLUSTERS[((selection-1)*2)]}"
  MAIN_RESOURCE_GROUP="${AKS_CLUSTERS[((selection-1)*2+1)]}"
fi

echo "Selected AKS Cluster: $CLUSTER_NAME"
echo "Main AKS Resource Group: $MAIN_RESOURCE_GROUP"

# Fetch the AKS node resource group (prefixed with MC_)
MC_RESOURCE_GROUP=$(az aks show --name "$CLUSTER_NAME" --resource-group "$MAIN_RESOURCE_GROUP" --query "nodeResourceGroup" -o tsv)
echo "Using AKS Node Resource Group: $MC_RESOURCE_GROUP"

# Check connectivity to the AKS cluster
echo "Checking AKS connectivity..."
kubectl cluster-info || { echo "Error: Unable to connect to AKS cluster"; exit 1; }

# Define the namespaces to inspect for NGINX Ingress
NAMESPACES=("default" "kube-system" "myapp" "monitoring")

# Check NGINX Ingress Controller status and LoadBalancer IP
for NS in "${NAMESPACES[@]}"; do
  echo "Checking NGINX Ingress Controller in namespace: $NS"
  kubectl get pods -n "$NS" -l app.kubernetes.io/name=ingress-nginx || echo "No NGINX Ingress pods found in $NS."
done

# Fetch LoadBalancer IP for NGINX Ingress
echo "Checking NGINX Ingress service in namespace: myapp"
LB_IP=$(kubectl get svc -n myapp -l app.kubernetes.io/name=ingress-nginx -o jsonpath='{.items[?(@.spec.type=="LoadBalancer")].status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
if [[ -z "$LB_IP" ]]; then
  echo "Warning: No LoadBalancer IP assigned to NGINX Ingress in namespace myapp."
else
  echo "NGINX Ingress LoadBalancer IP in myapp: $LB_IP"
fi

# Check static IP address association in Azure
STATIC_IP="52.166.53.86"  # Replace with your expected static IP
echo "Verifying static IP $STATIC_IP in Azure..."
az network public-ip list --query "[?ipAddress=='$STATIC_IP'].ipAddress" -o tsv | grep -q "$STATIC_IP" || echo "Error: Static IP $STATIC_IP does not match any public IP in Azure."

# Check if NGINX Ingress has the required 'nginx' ingressClassName
for NS in "${NAMESPACES[@]}"; do
  echo "Inspecting Ingress resources in namespace: $NS"
  INGRESS_CLASSES=$(kubectl get ingress -n "$NS" -o=jsonpath='{range .items[*]}{.metadata.name}{" - ingressClassName: "}{.spec.ingressClassName}{"\n"}{end}')
  echo "$INGRESS_CLASSES"
  echo "$INGRESS_CLASSES" | grep -q "nginx" || echo "Warning: No ingressClassName set to 'nginx' in namespace $NS."
done

# Verify application service availability on port 3000 in specific namespaces
echo "Checking if application services are available on port 3000 in the myapp namespace..."
kubectl get svc -n myapp | grep ':3000' && echo "Service on port 3000 found in namespace myapp." || echo "No service found on port 3000 in namespace myapp."

# Check if port 80 is open on the NGINX Ingress Controller
echo "Checking if port 80 is open on NGINX Ingress Controller in namespace myapp..."
INGRESS_POD=$(kubectl get pods -n myapp -l app.kubernetes.io/name=ingress-nginx -o jsonpath="{.items[0].metadata.name}" 2>/dev/null || echo "")
if [[ -n "$INGRESS_POD" ]]; then
  kubectl exec -n myapp "$INGRESS_POD" -- netstat -an | grep -q ':80' && echo "Port 80 is open on $INGRESS_POD." || echo "Error: Port 80 is not open on $INGRESS_POD in namespace myapp."
fi

# Validate NSG rules for port 80 in MC and Main Resource Groups
echo "Validating NSG rules for port 80..."
NSG_NAME="jenkins-nsg"  # Replace with your NSG name

# Check NSG rules in both resource groups
for RG in "$MC_RESOURCE_GROUP" "$MAIN_RESOURCE_GROUP"; do
  echo "Checking NSG rules in resource group: $RG"
  NSG_RULE=$(az network nsg rule list --nsg-name "$NSG_NAME" --resource-group "$RG" --query "[?destinationPortRange=='80' && access=='Allow'].{Name:name}" -o tsv || echo "")
  if [[ -n "$NSG_RULE" ]]; then
    echo "NSG rule allowing port 80 found in $RG: $NSG_RULE"
  else
    echo "Warning: No NSG rule found allowing inbound traffic on port 80 in $RG."
  fi
done

# Check endpoints and network policies in each namespace
echo "Checking endpoints and network policies in each namespace..."
for NS in "${NAMESPACES[@]}"; do
  kubectl get endpoints -n "$NS" || echo "No endpoints found in namespace $NS."
  kubectl get networkpolicies -n "$NS" || echo "No network policies found in namespace $NS."
done

# Simulate traffic to verify application reachability via NGINX Ingress
echo "Testing traffic flow to application on port 3000 via NGINX Ingress..."
if [[ -n "$LB_IP" ]]; then
  curl -I "http://$LB_IP" || echo "Error: Unable to reach the application via NGINX Ingress in namespace myapp."
fi

echo "AKS and NGINX Ingress troubleshooting completed."
