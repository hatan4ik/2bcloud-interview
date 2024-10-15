#!/bin/bash

set -euo pipefail

# Set environment variables for Jenkins
JENKINS_URL="http://localhost:8080"
ADMIN_USER="admin"
ADMIN_PASSWORD_FILE=$(cat /var/lib/jenkins/secrets/initialAdminPassword)

# Update system packages and install dependencies
echo "Updating system packages and installing dependencies..."
sudo apt-get update && sudo apt-get install -y openjdk-11-jdk docker.io git jq curl apt-transport-https ca-certificates

# Add Jenkins repository and GPG key
echo "Adding Jenkins repository and GPG key..."
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# Install and start Jenkins
echo "Installing and starting Jenkins..."
sudo apt-get update && sudo apt-get install -y jenkins
sudo systemctl enable jenkins && sudo systemctl start jenkins

# Wait for Jenkins to start up
echo "Waiting for Jenkins to start..."
timeout 300 bash -c 'until curl -s -o /dev/null http://localhost:8080; do sleep 5; done'

# Retrieve Jenkins admin password
if [ ! -f "$ADMIN_PASSWORD_FILE" ]; then
  echo "Jenkins password file not found at: $ADMIN_PASSWORD_FILE" >&2
  exit 1
fi

ADMIN_PASSWORD=$(sudo cat "$ADMIN_PASSWORD_FILE")

# Install Jenkins plugins and generate API token
echo "Installing Jenkins plugins and generating API token..."
sudo jenkins-plugin-cli --plugins workflow-aggregator git docker-workflow azure-credentials
JENKINS_API_TOKEN=$(curl -s -X POST -u "$ADMIN_USER:$ADMIN_PASSWORD" \
  -H "Content-Type: application/json" \
  -d '{"authenticityToken":"","username":"admin","password":"'"$ADMIN_PASSWORD"'","credentialDescription":"initial-token"}' \
  "$JENKINS_URL/me/descriptorByName/jenkins.security.ApiTokenProperty/generateNewToken" | jq -r .data.token)

echo "Jenkins API token: $JENKINS_API_TOKEN"

# Create Groovy script for additional plugin installation
cat <<EOF | sudo tee /var/lib/jenkins/init.groovy.d/plugins.groovy > /dev/null
import jenkins.model.*
import hudson.model.*
import jenkins.install.*

def instance = Jenkins.getInstance()
instance.setInstallState(InstallState.INITIAL_SETUP_COMPLETED)

def pluginManager = instance.getPluginManager()
def updateCenter = instance.getUpdateCenter()

["workflow-aggregator", "git", "docker-workflow", "azure-credentials"].each { pluginName ->
    if (!pluginManager.getPlugin(pluginName)) {
        def plugin = updateCenter.getPlugin(pluginName)
        if (plugin) {
            println("Installing plugin: ${pluginName}")
            plugin.deploy()
        }
    }
}

instance.save()
EOF

# Restart Jenkins and wait for it to come back up
echo "Restarting Jenkins..."
sudo systemctl restart jenkins
timeout 300 bash -c 'until curl -s -o /dev/null http://localhost:8080; do sleep 5; done'

# Clone repository and create pipeline job
echo "Creating Jenkins pipeline job..."
GIT_REPO_URL="https://github.com/hatan4ik/2bcloud-interview.git"
git clone "$GIT_REPO_URL" repo-temp

if [ ! -f "repo-temp/jenkins-pipeline.xml" ]; then
  echo "jenkins-pipeline.xml not found in the cloned repository." >&2
  exit 1
fi

curl -X POST "${JENKINS_URL}/createItem?name=app-deployment-pipeline" \
  --user "${ADMIN_USER}:${ADMIN_PASSWORD}" \
  --header "Content-Type: application/xml" \
  --data-binary @repo-temp/jenkins-pipeline.xml

rm -rf repo-temp

echo "Jenkins setup and pipeline job creation complete."
