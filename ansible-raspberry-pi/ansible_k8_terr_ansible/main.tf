# main.tf

resource "local_file" "ansible_inventory" {
  filename = "ansible_inventory.ini"
  content = templatefile("${path.module}/inventory.tmpl", {
    # Assuming your resource is named 'k8_controller'
    k8_controller_ip = "192.168.1.99"
  })
}

# Defin ethe local provider to execute commands
provider "local" {
  # This provider is a placeholder, as the actual work is done
  # by calling Ansible from the local machine.
}

# Use a null_resource to provision and set up the cluster
resource "null_resource" "k8s_node_setup" {
  # Add a trigger to re-run this resource if the IP changes
  triggers = {
    k8_controller_ip = "192.168.1.99"
  }

  depends_on = [
    local_file.ansible_inventory
  ]

  provisioner "local-exec" {
    command = "ansible-playbook -i ${local_file.ansible_inventory.filename} playbook.yml"
  }
}
