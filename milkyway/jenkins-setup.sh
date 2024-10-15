#!/bin/bash

# Install Azure CLI
sudo apt-get update

apt-get install -y docker.io git jq curl

curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install kubectl
sudo az aks install-cli

# Install Docker
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
#sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update

# Install Java (required for Jenkins)
 sudo   apt-get install -y openjdk-11-jdk

    # Install Jenkins
 sudo  wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | apt-key add -
 sudo  sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
 sudo  apt-get update
 sudo  apt-get install -y jenkins

    # Start and enable Jenkins
 sudo   systemctl enable jenkins
 sudo   systemctl start jenkins

    # Wait for Jenkins to start up
    sleep 60
# Install Jenkins plugins
sudo jenkins-plugin-cli --plugins workflow-aggregator:2.6 git:4.7.1 docker-workflow:1.26 azure-credentials:1.8.1

# Configure Azure credentials
jenkins_url="http://localhost:8080"
admin_password=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)

# Create Jenkins job
jenkins_url="http://localhost:8080"
admin_password=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)

# Create credential for GitHub if needed
# curl -X POST "${jenkins_url}/credentials/store/system/domain/_/createCredentials" \
#   --user "admin:${admin_password}" \
#   --data-urlencode 'json={
#     "": "0",
#     "credentials": {
#       "scope": "GLOBAL",
#       "id": "github-credentials",
#       "username": "your-github-username",
#       "password": "your-github-password-or-token",
#       "description": "GitHub Credentials",
#       "$class": "com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl"
#     }
#   }'

# Create the pipeline job
curl -X POST "${jenkins_url}/createItem?name=app-deployment-pipeline" \
  --user "admin:${admin_password}" \
  --header "Content-Type: application/xml" \
  --data-binary @./jenkins-pipeline.xml

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
