
# resource "azurerm_public_ip" "jenkins_public_ip" {
#   name                = "jenkins-public-ip"
#   resource_group_name = data.azurerm_resource_group.main
#   location            = data.azurerm_resource_group.main.location
#   sku                 =  "Standard"
#   allocation_method   = "Dynamic"
# }

# resource "azurerm_network_interface" "jenkins_nic" {
#   name                = "jenkins-nic"
#   location            = data.azurerm_resource_group.main.location
#   resource_group_name = data.azurerm_resource_group.main

#   ip_configuration {
#     name                          = "internal"
#     subnet_id                     = module.subnets.subnet_ids["jenkins"]
#     private_ip_address_allocation = "Dynamic"
#     public_ip_address_id          = azurerm_public_ip.jenkins_public_ip.id
#   }
# }

# resource "azurerm_network_interface_security_group_association" "jenkins_nic_nsg_assoc" {
#   network_interface_id      = azurerm_network_interface.jenkins_nic.id
#   network_security_group_id = module.network_security_groups.security_group_ids["jenkins"]
# }

# resource "azurerm_linux_virtual_machine" "jenkins_vm" {
#   name                = "jenkins-machine"
#   resource_group_name = data.azurerm_resource_group.main
#   location            = data.azurerm_resource_group.main.location
#   size                = "Standard_D2s_v3"
#   admin_username      = "adminuser"
#   network_interface_ids = [
#     azurerm_network_interface.jenkins_nic.id,
#   ]

#   admin_ssh_key {
#     username   = "adminuser"
#     public_key = file("~/.ssh/id_rsa.pub")
#   }

#   os_disk {
#     caching              = "ReadWrite"
#     storage_account_type = "Standard_LRS"
#   }

#   source_image_reference {
#     publisher = "Canonical"
#     offer     = "UbuntuServer"
#     sku       = "18.04-LTS"
#     version   = "latest"
#   }

# # Cloud-init script for Jenkins setup and configuration
#   custom_data = base64encode(<<-EOF
#     #!/bin/bash
#     set -e

#     # Logging setup
#     LOG_FILE="/var/log/jenkins_install.log"
#     exec > >(tee -a $LOG_FILE) 2>&1
#     echo "Starting Jenkins installation script"

#     # System update and install dependencies
#     apt-get update -y
#     apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg2

#     # Install Docker
#     curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
#     add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
#     apt-get update -y
#     apt-get install -y docker-ce docker-ce-cli containerd.io

#     # Start and enable Docker
#     systemctl start docker
#     systemctl enable docker

#     # Add Jenkins to Docker group for Docker access
#     usermod -aG docker jenkins

#     # Install Java for Jenkins
#     apt-get install -y openjdk-11-jdk

#     # Install Jenkins
#     curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
#     sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
#     apt-get update -y
#     apt-get install -y jenkins

#     # Start and enable Jenkins
#     systemctl start jenkins
#     systemctl enable jenkins

#     # Wait for Jenkins to be accessible
#     echo "Waiting for Jenkins to start..."
#     until $(curl --output /dev/null --silent --head --fail http://localhost:8080); do
#       printf '.'
#       sleep 5
#     done

#     # Get initial admin password and store it in a safe location
#     JENKINS_PASSWORD=$(cat /var/lib/jenkins/secrets/initialAdminPassword)
#     echo "Jenkins initial admin password: $JENKINS_PASSWORD" > /home/adminuser/jenkins_password.txt
#     chown adminuser:adminuser /home/adminuser/jenkins_password.txt
#     chmod 600 /home/adminuser/jenkins_password.txt

#     # Test Jenkins is up
#     echo "Testing Jenkins status..."
#     if curl -s http://localhost:8080 | grep -q "Jenkins"; then
#       echo "Jenkins is up and operational" > /home/adminuser/jenkins_status.txt
#     else
#       echo "Jenkins failed to start properly" > /home/adminuser/jenkins_status.txt
#     fi
#     EOF
#   )
# }

# output "jenkins_public_ip" {
#   value = azurerm_public_ip.jenkins_public_ip.ip_address
# }
