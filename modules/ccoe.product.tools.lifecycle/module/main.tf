resource "null_resource" "lifecycle_event" {
  count = contains(["Production", "Global"], var.environment) ? 1 : 0

  triggers = {
    workload_name = var.workload_name
    resource_id   = var.resource_id
  }

  provisioner "local-exec" {
    interpreter = ["pwsh", "-Command"]
    command     = <<EOF
    ${path.module}/files/add-queue-message.ps1 -ResourceId ${var.resource_id} `
      -WorkloadName ${var.workload_name} `
      -Action "apply"
EOF
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["pwsh", "-Command"]
    command     = <<EOF
    ${path.module}/files/add-queue-message.ps1 -ResourceId ${self.triggers.resource_id} `
      -WorkloadName ${self.triggers.workload_name} `
      -Action "destroy"
EOF
  }
}
