#!/bin/bash

# Ensure we exit on errors
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

# Set context to AKS cluster
echo "Setting Kubernetes context..."
az aks get-credentials --resource-group "$MAIN_RESOURCE_GROUP" --name "$CLUSTER_NAME" --overwrite-existing --admin

# Get all namespaces
echo "Listing namespaces..."
NAMESPACES=$(kubectl get namespaces -o jsonpath="{.items[*].metadata.name}")

# Detect the namespace with an application service (skipping system namespaces)
echo "Searching for application services across namespaces..."
APP_NAMESPACE=""
for NS in $NAMESPACES; do
  if [[ "$NS" != "default" && "$NS" != kube-* ]]; then
    SERVICE_OUTPUT=$(kubectl get svc -n "$NS" 2>&1)
    if [[ ! "$SERVICE_OUTPUT" =~ "No resources found" ]] && echo "$SERVICE_OUTPUT" | grep -q -E "LoadBalancer|ClusterIP"; then
      APP_NAMESPACE="$NS"
      echo "Application service found in namespace: $APP_NAMESPACE"
      break
    fi
  fi
done

# Fallback to 'default' if no other namespace has services
if [[ -z "$APP_NAMESPACE" ]]; then
  if kubectl get svc -n "default" | grep -q -E "LoadBalancer|ClusterIP"; then
    APP_NAMESPACE="default"
    echo "No application-specific namespaces found; using default namespace."
  else
    echo "Error: No application services found in any namespace."
    exit 1
  fi
fi

# Identify application service details (assumes the app service has a ClusterIP or LoadBalancer type)
APP_SERVICE_NAME=$(kubectl get svc -n "$APP_NAMESPACE" -o jsonpath="{.items[0].metadata.name}")
APP_SERVICE_PORT=$(kubectl get svc "$APP_SERVICE_NAME" -n "$APP_NAMESPACE" -o jsonpath="{.spec.ports[0].port}")

# Perform internal connectivity test using a temporary pod with curl
echo "Testing internal connectivity in namespace $APP_NAMESPACE..."

kubectl run internal-test --image=alpine:3.13 -n "$APP_NAMESPACE" --restart=Never -- sh -c "
  apk add --no-cache curl >/dev/null &&
  echo 'Testing internal connectivity to ClusterIP ($APP_SERVICE_NAME.$APP_NAMESPACE.svc.cluster.local:$APP_SERVICE_PORT)...' &&
  curl -s -o /dev/null -w \"%{http_code}\" http://$APP_SERVICE_NAME.$APP_NAMESPACE.svc.cluster.local:$APP_SERVICE_PORT || echo 'Error: Internal connectivity to the application failed.'
" && kubectl delete pod internal-test -n "$APP_NAMESPACE"

# Check if service has a LoadBalancer IP
APP_LB_IP=$(kubectl get svc "$APP_SERVICE_NAME" -n "$APP_NAMESPACE" -o jsonpath="{.status.loadBalancer.ingress[0].ip}" 2>/dev/null || echo "")

if [[ -n "$APP_LB_IP" ]]; then
  echo "External LoadBalancer IP detected: $APP_LB_IP"

  # Test external connectivity to LoadBalancer IP
  echo "Testing external connectivity to LoadBalancer IP ($APP_LB_IP)..."
  curl -v "http://$APP_LB_IP:$APP_SERVICE_PORT"

  # Verify DNS if FQDN is set for the application
  APP_FQDN=$(kubectl get ingress -n "$APP_NAMESPACE" -o jsonpath="{.items[0].spec.rules[0].host}" 2>/dev/null || echo "")
  if [[ -n "$APP_FQDN" ]]; then
    echo "Application FQDN detected: $APP_FQDN"
    echo "Testing external connectivity to FQDN ($APP_FQDN)..."
    curl -v "http://$APP_FQDN"
  else
    echo "No FQDN found in Ingress configuration for the application."
  fi
else
  echo "No LoadBalancer IP assigned to the application service ($APP_SERVICE_NAME) in namespace $APP_NAMESPACE."
fi

echo "AKS application availability debugging completed."