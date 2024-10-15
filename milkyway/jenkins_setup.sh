#!/bin/bash

# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install kubectl
sudo az aks install-cli

# Install Docker
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install -y docker-ce

# Install Jenkins plugins
jenkins-plugin-cli --plugins workflow-aggregator:2.6 git:4.7.1 docker-workflow:1.26 azure-credentials:1.8.1

# Configure Azure credentials
jenkins_url="http://localhost:8080"
admin_password=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)

curl -X POST "${jenkins_url}/credentials/store/system/domain/_/createCredentials" \
  --user "admin:${admin_password}" \
  --data-urlencode 'json={
    "": "0",
    "credentials": {
      "scope": "GLOBAL",
      "id": "azure-credentials",
      "description": "Azure Service Principal",
      "subscriptionId": "'$4'",
      "clientId": "'$2'",
      "clientSecret": "'$3'",
      "tenantId": "'$5'",
      "$class": "com.microsoft.azure.util.AzureCredentials"
    }
  }'

# Configure ACR credentials
curl -X POST "${jenkins_url}/credentials/store/system/domain/_/createCredentials" \
  --user "admin:${admin_password}" \
  --data-urlencode 'json={
    "": "0",
    "credentials": {
      "scope": "GLOBAL",
      "id": "acr-credentials",
      "username": "'$6'",
      "password": "'$7'",
      "description": "ACR Credentials",
      "$class": "com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl"
    }
  }'
