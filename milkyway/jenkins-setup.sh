#!/bin/bash

set -e

# Set environment variables for Jenkins
export JENKINS_URL="http://localhost:8080"
export ADMIN_USER="admin"
export ADMIN_PASSWORD_FILE="/var/lib/jenkins/secrets/initialAdminPassword"

# Update system packages
echo "Updating system packages..."
sudo apt-get update

# Install required dependencies: Java, Docker, Git, jq, curl
echo "Installing required dependencies..."
sudo apt-get install -y openjdk-11-jdk docker.io git jq curl apt-transport-https ca-certificates

# Add Jenkins repository and GPG key
echo "Adding Jenkins repository and GPG key..."
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# Install Jenkins
echo "Installing Jenkins..."
sudo apt-get update
sudo apt-get install -y jenkins

# Start and enable Jenkins service
echo "Starting and enabling Jenkins service..."
sudo systemctl enable jenkins
sudo systemctl start jenkins

# Wait for Jenkins to start up
echo "Waiting for Jenkins to start..."
sleep 60

# Retrieve Jenkins admin password
if [ ! -f "$ADMIN_PASSWORD_FILE" ]; then
  echo "Jenkins password file not found at: $ADMIN_PASSWORD_FILE"
  exit 1
fi

ADMIN_PASSWORD=$(sudo cat "$ADMIN_PASSWORD_FILE")

# Install Jenkins plugins using jenkins-plugin-cli
echo "Installing Jenkins plugins using jenkins-plugin-cli..."
sudo jenkins-plugin-cli --plugins workflow-aggregator git docker-workflow azure-credentials

# Generate Jenkins API Token for admin user
echo "Generating Jenkins API token for the admin user..."
JENKINS_API_TOKEN=$(curl -s -X POST -u "$ADMIN_USER:$ADMIN_PASSWORD" \
  -d 'json={"authenticityToken":"","username":"admin","password":"'"$ADMIN_PASSWORD"'","credentialDescription":"initial-token"}' \
  "$JENKINS_URL/me/descriptorByName/jenkins.security.ApiTokenProperty/generateNewToken" | jq -r .data.token)

# Output the generated token
echo "Jenkins API token: $JENKINS_API_TOKEN"

# Create Groovy script to install additional plugins if needed
echo "Creating Groovy script to install additional plugins at startup..."
cat <<EOF | sudo tee /var/lib/jenkins/init.groovy.d/plugins.groovy > /dev/null
import jenkins.model.*
import hudson.model.*
import jenkins.install.*

def instance = Jenkins.getInstance()

// Skip initial setup wizard if not already completed
if (instance.installState.isSetupComplete() == false) {
    instance.setInstallState(InstallState.INITIAL_SETUP_COMPLETED)
}

def plugins = [
    "workflow-aggregator",  // Pipeline plugin
    "git",                  // Git plugin
    "docker-workflow",      // Docker plugin for workflows
    "azure-credentials"     // Azure credentials plugin
]

def pluginManager = instance.getPluginManager()
def updateCenter = instance.getUpdateCenter()

plugins.each { pluginName ->
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

# Restart Jenkins to apply plugin changes
echo "Restarting Jenkins to apply changes..."
sudo systemctl restart jenkins

# Wait for Jenkins to restart and initialize
echo "Waiting for Jenkins to restart..."
sleep 60

# Clone the Git repository to retrieve jenkins-pipeline.xml
echo "Cloning Git repository to retrieve jenkins-pipeline.xml..."
GIT_REPO_URL="https://github.com/hatan4ik/2bcloud-interview.git"  # Replace with your actual Git repository URL
git clone "$GIT_REPO_URL" repo-temp

# Check if jenkins-pipeline.xml exists in the cloned repository
if [ ! -f "repo-temp/jenkins-pipeline.xml" ]; then
  echo "jenkins-pipeline.xml not found in the cloned repository. Please make sure the file exists in the repository."
  exit 1
fi

# Create the pipeline job in Jenkins
echo "Uploading Jenkins pipeline job configuration..."
curl -X POST "${JENKINS_URL}/createItem?name=app-deployment-pipeline" \
  --user "${ADMIN_USER}:${ADMIN_PASSWORD}" \
  --header "Content-Type: application/xml" \
  --data-binary @repo-temp/jenkins-pipeline.xml

# Clean up cloned repository
rm -rf repo-temp

echo "Jenkins setup and pipeline job creation complete."