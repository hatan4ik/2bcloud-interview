#!/bin/bash

set -e

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

# Set environment variables for Jenkins
export JENKINS_URL="http://localhost:8080"
export ADMIN_USER="admin"
export ADMIN_PASSWORD_FILE=$(cat /var/lib/jenkins/secrets/initialAdminPassword)
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

# Create Jenkins job (pipeline) using the XML configuration
echo "Creating Jenkins pipeline job..."
cat <<EOF > jenkins-pipeline.xml
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@2.40">
  <actions/>
  <description>Pipeline for building and deploying the application</description>
  <keepDependencies>false</keepDependencies>
  <properties/>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition" plugin="workflow-cps@2.87">
    <script>
pipeline {
    agent any
    
    environment {
        GIT_REPO = '\${GIT_REPO_URL}'
        ACR_SERVER = '\${ACR_LOGIN_SERVER}'
        ACR_CREDENTIAL_ID = 'acr-credentials'
        AKS_RESOURCE_GROUP = '\${AKS_RESOURCE_GROUP}'
        AKS_CLUSTER_NAME = '\${AKS_CLUSTER_NAME}'
        AZURE_CREDENTIAL_ID = 'azure-credentials'
    }
    
    stages {
        stage('Checkout') {
            steps {
                git url: env.GIT_REPO
            }
        }
        
        stage('Build and Push Docker Image') {
            steps {
                script {
                    docker.withRegistry("https://\${env.ACR_SERVER}", env.ACR_CREDENTIAL_ID) {
                        def appImage = docker.build("\${env.ACR_SERVER}/myapp:\${env.BUILD_NUMBER}")
                        appImage.push()
                    }
                }
            }
        }
        
        stage('Deploy to AKS') {
            steps {
                withCredentials([azureServicePrincipal(env.AZURE_CREDENTIAL_ID)]) {
                    sh '''
                        az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET -t $AZURE_TENANT_ID
                        az aks get-credentials --resource-group $AKS_RESOURCE_GROUP --name $AKS_CLUSTER_NAME
                        kubectl set image deployment/myapp myapp=\${ACR_SERVER}/myapp:\${BUILD_NUMBER}
                    '''
                }
            }
        }
    }
}
    </script>
    <sandbox>true</sandbox>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
EOF

# Create the pipeline job in Jenkins
echo "Uploading Jenkins pipeline job configuration..."
curl -X POST "${JENKINS_URL}/createItem?name=app-deployment-pipeline" \
  --user "${ADMIN_USER}:${ADMIN_PASSWORD}" \
  --header "Content-Type: application/xml" \
  --data-binary @jenkins-pipeline.xml

echo "Jenkins setup and pipeline job creation complete."