# Kubernetes Cluster with Terraform and Ansible

We will use Terraform and Ansible files to follow the best practice of separating infrastructure provisioning from configuration management for a single-node, on-premise Kubernetes cluster.

## Some common Ansible command lines

> ansible-playbook: passing in password file

Note: when a PlayBook has a 'become' line (root), you need to provide a password for sudo.  One way is to pass in password file and add the '--vault-password-file' parameter.<br>

For example:<br>

    ansible-playbook install_helm.yaml -i inventory.ini --vault-password-file my_pw.txt


## Install Prometheus on the K8 Controller

Bash

    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

    helm repo update

    helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace

I want to turn this into Ansible playbook instead

Ansible

    ---
    - name: Install kube-prometheus-stack using Helm
    hosts: k8_controller
    become: yes

    tasks:
        - name: Add Prometheus Helm repository
        ansible.builtin.command: helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
        changed_when: true

        - name: Update Helm repositories
        ansible.builtin.command: helm repo update
        changed_when: true

        - name: Install kube-prometheus-stack
        ansible.builtin.command: helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace
        changed_when: true

### Explanation of the Playbook

> ansible.builtin.command: 

This module is used to run shell commands directly on the remote host. It's the most straightforward way to execute your helm commands.

> changed_when: true: 

This is a crucial line for this playbook. By default, Ansible marks a task as "changed" only if the command's output or exit code suggests a change was made. However, helm repo add and helm repo update might not always report a change, even though the command ran successfully. By setting changed_when: true, you are telling Ansible to always consider this task as having made a change, which prevents it from being skipped and ensures the playbook always proceeds.
