resource "null_resource" "jenkins_job_config" {
  provisioner "local-exec" {
    command = <<EOT
      # Define the Jenkins Job using dynamic IP from Terraform output
      curl -X POST "http://${azurerm_public_ip.jenkins_public_ip.ip_address}/createItem?name=hello-world-deployment" \
      --user "admin:<jenkins-token>" \
      --header "Content-Type:application/xml" \
      --data-binary @- <<EOF
      <project>
        <builders>
          <hudson.tasks.Shell>
            <command>kubectl apply -f /var/lib/jenkins/workspace/hello-world-deployment/deployment.yaml</command>
          </hudson.tasks.Shell>
        </builders>
        <triggers/>
        <disabled>false</disabled>
      </project>
      EOF

      # Push deployment.yaml to Jenkins workspace
      curl -X POST --user "admin:<jenkins-token>" \
        -F "file=@deployment.yaml" \
        "http://${azurerm_public_ip.jenkins_public_ip.ip_address}/job/hello-world-deployment/ws/deployment.yaml"
    EOT
  }

  depends_on = [
    azurerm_linux_virtual_machine.jenkins,  # Ensure Jenkins VM is created before executing this
    azurerm_public_ip.jenkins_public_ip
  ]
}
