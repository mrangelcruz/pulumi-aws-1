#!/bin/bash
# controller-ip-recovery.sh
# Bash playbook to recover a Kubernetes controller after IP change

set -euo pipefail

# === CONFIGURE THESE VARIABLES ===
OLD_IP="192.168.1.99"         # Old IP of the controller
NEW_IP="192.168.1.98"         # New IP of the controller
K8S_VERSION="1.33.4"          # Kubernetes version (optional)

# --- Step 1: Backup manifests and PKI ---
echo "[INFO] Backing up manifests and certificates..."
sudo mkdir -p /etc/kubernetes/manifests/backup
sudo mkdir -p /etc/kubernetes/pki/backup
sudo cp -r /etc/kubernetes/manifests/* /etc/kubernetes/manifests/backup/ || true
sudo cp -r /etc/kubernetes/pki/* /etc/kubernetes/pki/backup/ || true

# --- Step 2: Update manifests ---
echo "[INFO] Updating kube-apiserver manifest with new IP..."
KUBE_API_MANIFEST="/etc/kubernetes/manifests/kube-apiserver.yaml"
sudo sed -i "s/${OLD_IP}/${NEW_IP}/g" $KUBE_API_MANIFEST

# --- Step 3: Update kube-controller-manager and scheduler manifests ---
echo "[INFO] Updating controller-manager and scheduler manifests..."
for FILE in controller-manager scheduler; do
    MANIFEST="/etc/kubernetes/manifests/${FILE}.yaml"
    sudo sed -i "s/${OLD_IP}/${NEW_IP}/g" $MANIFEST
done

# --- Step 4: Regenerate etcd certificates ---
echo "[INFO] Regenerating etcd certificates for new IP..."
sudo kubeadm init phase certs etcd-server --apiserver-advertise-address $NEW_IP
sudo kubeadm init phase certs etcd-peer
sudo kubeadm init phase certs etcd-healthcheck-client
sudo kubeadm init phase certs apiserver-etcd-client

# --- Step 5: Regenerate API server certificates (if needed) ---
echo "[INFO] Regenerating apiserver certificates for new IP..."
sudo kubeadm init phase certs apiserver
sudo kubeadm init phase certs apiserver-kubelet-client

# --- Step 6: Restart control plane pods ---
echo "[INFO] Restarting kubelet to pick up new manifests..."
sudo systemctl restart kubelet

# --- Step 7: Generate new bootstrap token ---
echo "[INFO] Creating new bootstrap token for workers..."
JOIN_CMD=$(sudo kubeadm token create --print-join-command)
echo "[INFO] New worker join command: $JOIN_CMD"

echo "[INFO] Controller IP recovery complete. Verify nodes and pods:"
echo "kubectl get nodes"
echo "kubectl get pods -A"

