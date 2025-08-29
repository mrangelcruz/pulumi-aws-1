# Kubernetes Cluster with Terraform and Ansible

We will use Terraform and Ansible files to follow the best practice of separating infrastructure provisioning from configuration management for a single-node, on-premise Kubernetes cluster.

## Some common Ansible command lines

> ansible-playbook: passing in password file

Note: when a PlayBook has a 'become' line (root), you need to provide a password for sudo.  One way is to pass in password file and add the '--vault-password-file' parameter.<br>

For example:<br>

    ansible-playbook install_helm.yaml -i inventory.ini --vault-password-file my_pw.txt
