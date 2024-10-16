#!/bin/bash

set -euo pipefail

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to wait for Jenkins to start
wait_for_jenkins() {
    echo "Waiting for Jenkins to start..."
    timeout 300 bash -c 'until curl -s -o /dev/null http://localhost:8080; do sleep 5; done'
}

# Set environment variables for Jenkins
JENKINS_URL="http://localhost:8080"
ADMIN_USER="admin"
JENKINS_HOME="/var/lib/jenkins"
ADMIN_PASSWORD_FILE="$JENKINS_HOME/secrets/initialAdminPassword"

# Update system packages and install dependencies
echo "Updating system packages and installing dependencies..."
sudo apt-get update
sudo apt-get install -y openjdk-11-jdk docker.io git jq curl apt-transport-https ca-certificates

# Add Jenkins repository and GPG key
echo "Adding Jenkins repository and GPG key..."
if ! command_exists jenkins; then
    curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo gpg --dearmor -o /usr/share/keyrings/jenkins-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.gpg] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
    sudo apt-get update
fi

# Install Jenkins
echo "Installing Jenkins..."
sudo apt-get install -y jenkins

# Ensure Jenkins is started and enabled
sudo systemctl enable jenkins
sudo systemctl start jenkins

# Wait for Jenkins to start up
wait_for_jenkins

# Retrieve Jenkins admin password
echo "Retrieving Jenkins admin password..."
for i in {1..30}; do
    if [ -f "$ADMIN_PASSWORD_FILE" ]; then
        ADMIN_PASSWORD=$(sudo cat "$ADMIN_PASSWORD_FILE")
        break
    fi
    echo "Waiting for Jenkins to generate admin password... (attempt $i/30)"
    sleep 10
done

if [ -z "${ADMIN_PASSWORD:-}" ]; then
    echo "Failed to retrieve Jenkins admin password" >&2
    exit 1
fi

# Install Jenkins plugins
echo "Installing Jenkins plugins..."
PLUGIN_INSTALLATION_TIMEOUT=600
sudo -u jenkins java -jar /usr/share/jenkins/jenkins-cli.jar -s $JENKINS_URL -auth $ADMIN_USER:$ADMIN_PASSWORD install-plugin workflow-aggregator git docker-workflow azure-credentials -deploy -restart

# Wait for Jenkins to restart
wait_for_jenkins

# Generate API token
echo "Generating Jenkins API token..."
JENKINS_API_TOKEN=$(curl -s -X POST -u "$ADMIN_USER:$ADMIN_PASSWORD" \
  -H "Content-Type: application/json" \
  -d '{"newTokenName":"initial-token"}' \
  "$JENKINS_URL/me/descriptorByName/jenkins.security.ApiTokenProperty/generateNewToken" | jq -r .data.tokenValue)

if [ -z "$JENKINS_API_TOKEN" ]; then
    echo "Failed to generate Jenkins API token" >&2
    exit 1
fi

echo "Jenkins API token: $JENKINS_API_TOKEN"

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
