#!/bin/bash

# Set dynamic variables using az CLI and kubectl
echo "Fetching resource group and AKS cluster information..."

# Fetch the current AKS cluster context
AKS_CLUSTER_NAME=$(kubectl config current-context)

# Fetch resource group for the current AKS cluster
RESOURCE_GROUP=$(az aks list --query "[?name=='$AKS_CLUSTER_NAME'].resourceGroup" -o tsv)

# Fetch VNET and subnet associated with the AKS cluster
VNET_NAME=$(az aks show --resource-group "$RESOURCE_GROUP" --name "$AKS_CLUSTER_NAME" --query "nodeResourceGroup" -o tsv | xargs -I {} az network vnet list --resource-group {} --query "[].name" -o tsv)

# Fetch the subnet used by the AKS node pool
SUBNET_NAME=$(az aks show --resource-group "$RESOURCE_GROUP" --name "$AKS_CLUSTER_NAME" --query "agentPoolProfiles[0].vnetSubnetId" -o tsv | awk -F'/' '{print $NF}')

# Fetch the NSG associated with the subnet
NSG_NAME=$(az network vnet subnet show --resource-group "$RESOURCE_GROUP" --vnet-name "$VNET_NAME" --name "$SUBNET_NAME" --query "networkSecurityGroup.id" -o tsv | awk -F'/' '{print $NF}')

# Print the dynamically fetched variables
echo "Resource Group: $RESOURCE_GROUP"
echo "AKS Cluster: $AKS_CLUSTER_NAME"
echo "VNET: $VNET_NAME"
echo "Subnet: $SUBNET_NAME"
echo "NSG: $NSG_NAME"

# Helper function to display section headers
function section {
  echo "----------------------------------------"
  echo "$1"
  echo "----------------------------------------"
}

# 1. Check AKS Network Profile
section "Checking AKS Network Profile"
az aks show --resource-group "$RESOURCE_GROUP" --name "$AKS_CLUSTER_NAME" --query "networkProfile" --output table

# 2. Check VNET and Subnet Association
section "Checking VNET and Subnet IP Range"
az network vnet subnet show --resource-group "$RESOURCE_GROUP" --vnet-name "$VNET_NAME" --name "$SUBNET_NAME" --query "addressPrefix" --output table

# 3. Check Network Policies
section "Checking Network Policies in AKS"
kubectl get networkpolicies -A

# 4. Check NSG Rules
section "Checking NSG Rules for AKS Subnet"
az network nsg rule list --resource-group "$RESOURCE_GROUP" --nsg-name "$NSG_NAME" --output table

# 5. Check if there is enough IP space in the subnet for pods
section "Checking IP Space in Subnet"
az network vnet subnet show --resource-group "$RESOURCE_GROUP" --vnet-name "$VNET_NAME" --name "$SUBNET_NAME" --query "addressPrefix"

# 6. Check Load Balancer for NGINX Ingress
section "Checking Load Balancer Service for NGINX Ingress"
kubectl get services -n ingress-nginx -o wide | grep LoadBalancer

# 7. Check DNS Resolution for Ingress
section "Checking DNS Resolution"
kubectl get ingresses -A
echo "If external DNS is used, verify if the external IP of the load balancer matches the DNS records."

# 8. Check Service Endpoints (Azure Service Endpoints)
section "Checking Azure Service Endpoints for Subnet"
az network vnet subnet list-service-endpoints --resource-group "$RESOURCE_GROUP" --vnet-name "$VNET_NAME" --name "$SUBNET_NAME"

# 9. Check Firewall Rules if Azure Firewall is present
section "Checking Azure Firewall Rules (if applicable)"
FIREWALL_NAME=$(az network firewall list --resource-group "$RESOURCE_GROUP" --query "[0].name" -o tsv)
if [ -n "$FIREWALL_NAME" ]; then
  az network firewall network-rule list --resource-group "$RESOURCE_GROUP" --firewall-name "$FIREWALL_NAME" --output table
else
  echo "No firewall configured, skipping..."
fi

# 10. Check Route Tables (if custom routes are in use)
section "Checking Route Tables (if applicable)"
ROUTE_TABLE_NAME=$(az network route-table list --resource-group "$RESOURCE_GROUP" --query "[0].name" -o tsv)
if [ -n "$ROUTE_TABLE_NAME" ]; then
  az network route-table show --resource-group "$RESOURCE_GROUP" --name "$ROUTE_TABLE_NAME" --output table
else
  echo "No custom route table found, skipping..."
fi

# 11. Check AKS Node and Pod IPs
section "Checking AKS Node and Pod IPs"
kubectl get nodes -o wide
kubectl get pods -n ingress-nginx -o wide

# 12. Checking NGINX Ingress Controller Logs
section "Checking NGINX Ingress Controller Logs"
kubectl logs -n ingress-nginx --selector app.kubernetes.io/name=ingress-nginx -c nginx-ingress-controller

# 13. Checking DNS Configurations in Pods (Optional)
section "Checking DNS Configurations in Pods"
kubectl exec -n ingress-nginx $(kubectl get pods -n ingress-nginx --selector app.kubernetes.io/name=ingress-nginx -o jsonpath='{.items[0].metadata.name}') -- cat /etc/resolv.conf

# End of the script
echo "Script execution completed. Review the output for potential issues."
