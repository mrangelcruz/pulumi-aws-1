#!/bin/bash
# worker-reset-and-join.sh
# Bash "playbook" to clean worker node and join a Kubernetes cluster

set -euo pipefail

# === CONFIGURE THESE VARIABLES ===
CONTROLLER_IP="192.168.1.98"             # Controller's new IP
TOKEN=pclqdm.gkxo98btdtn2ugqm         # e.g., output from kubeadm token create
DISCOVERY_HASH="sha256:19e75feb26c634b760bdddd6bce4cc8dc8a07fa0c7f2ea5efbaee53b14b93678"    # e.g., CA cert hash
K8S_VERSION="1.33.4-00"                  # Optional: specific kubeadm/kubelet version

# --- Step 1: Reset any previous kubeadm state ---
echo "[INFO] Resetting any existing kubeadm state..."
sudo kubeadm reset -f || true

# --- Step 2: Stop kubelet and container runtime ---
echo "[INFO] Stopping kubelet and containerd..."
sudo systemctl stop kubelet || true
sudo systemctl stop containerd || true

# --- Step 3: Clean directories ---
echo "[INFO] Cleaning Kubernetes directories..."
sudo rm -rf /etc/kubernetes /var/lib/kubelet /var/lib/etcd /var/lib/cni /etc/cni/net.d

# --- Step 4: Ensure container runtime is running ---
echo "[INFO] Starting containerd..."
sudo systemctl start containerd
sudo systemctl enable containerd

# --- Step 5: Install kubeadm/kubelet (optional) ---
# Uncomment if kubeadm/kubelet are not installed or need specific version
# echo "[INFO] Installing kubeadm/kubelet..."
# sudo apt-get update
# sudo apt-get install -y kubelet=$K8S_VERSION kubeadm=$K8S_VERSION kubectl=$K8S_VERSION
# sudo apt-mark hold kubelet kubeadm kubectl

# --- Step 6: Join the cluster ---
echo "[INFO] Joining the cluster..."
sudo kubeadm join ${CONTROLLER_IP}:6443 \
  --token ${TOKEN} \
  --discovery-token-ca-cert-hash ${DISCOVERY_HASH}

echo "[INFO] Worker node should now be joining the cluster."
echo "[INFO] Verify with: kubectl get nodes (on controller)"

