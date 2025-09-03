#!/bin/bash
set -euo pipefail

# -----------------------------
# bootstrap-raspberrypi4.sh
# -----------------------------
# Installs containerd, kubeadm, kubelet, kubectl
# Prepares Raspberry Pi 4 to join a Kubernetes cluster
# -----------------------------

echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

echo "Installing required dependencies..."
sudo apt install -y curl apt-transport-https gnupg lsb-release software-properties-common

echo "Adding Kubernetes apt repository..."
sudo curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/kubernetes-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

echo "Updating package list..."
sudo apt update

echo "Installing kubelet, kubeadm, kubectl..."
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

echo "Installing containerd..."
sudo apt install -y containerd

echo "Configuring containerd..."
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

echo "Disabling swap (required by Kubernetes)..."
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

echo "Ensuring br_netfilter module is loaded..."
sudo modprobe br_netfilter
echo 'br_netfilter' | sudo tee /etc/modules-load.d/k8s.conf
sudo sysctl net.bridge.bridge-nf-call-iptables=1
sudo sysctl net.bridge.bridge-nf-call-ip6tables=1

echo "Bootstrap setup complete. You can now run 'worker-reset-and-join.sh' to join the cluster."

