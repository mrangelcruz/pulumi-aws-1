#!/bin/bash
set -euo pipefail

# -----------------------------
# worker-reset-and-join.sh
# -----------------------------
# Usage: ./worker-reset-and-join.sh <CONTROL_PLANE_IP> <JOIN_TOKEN> <DISCOVERY_HASH>
# Example:
# ./worker-reset-and-join.sh 192.168.1.98 t0u22o.2qmw5yqupr0poxle sha256:be2d7bde4f354f35ea9445a16247c5ac0b53d7c06645a901d70930927c78a7fb
# -----------------------------

CONTROL_PLANE_IP="$1"
JOIN_TOKEN="$2"
DISCOVERY_HASH="$3"

echo "Resetting existing Kubernetes state..."
sudo kubeadm reset -f
sudo systemctl stop kubelet
sudo rm -rf /etc/cni/net.d
sudo rm -rf /var/lib/kubelet/*
sudo rm -rf /var/lib/kubeadm/*
sudo rm -rf /etc/kubernetes

echo "Starting kubelet..."
sudo systemctl restart kubelet

# Join the node to the cluster
echo "Joining node to the cluster..."
sudo kubeadm join "${CONTROL_PLANE_IP}:6443" \
    --token "$JOIN_TOKEN" \
    --discovery-token-ca-cert-hash "$DISCOVERY_HASH" \
    --ignore-preflight-errors=all

# -----------------------------
# Fix Calico for architecture
# -----------------------------
NODE_NAME=$(hostname)
ARCH=$(uname -m)
echo "Detected architecture: $ARCH"

case "$ARCH" in
    aarch64)
        PAUSE_IMAGE="registry.k8s.io/pause:3.6-arm64"
        CALICO_NODE_IMAGE="docker.io/calico/node:v3.26.0-arm64"
        ;;
    armv7l)
        PAUSE_IMAGE="registry.k8s.io/pause:3.6-arm"
        CALICO_NODE_IMAGE="docker.io/calico/node:v3.26.0-arm"
        ;;
    x86_64)
        PAUSE_IMAGE="registry.k8s.io/pause:3.6"
        CALICO_NODE_IMAGE="docker.io/calico/node:v3.26.0"
        ;;
    *)
        echo "Warning: Unknown architecture $ARCH, defaulting to amd64 images"
        PAUSE_IMAGE="registry.k8s.io/pause:3.6"
        CALICO_NODE_IMAGE="docker.io/calico/node:v3.26.0"
        ;;
esac

# Pull the pause container to avoid CNI sandbox issues
echo "Pulling pause image: $PAUSE_IMAGE..."
sudo ctr image pull "$PAUSE_IMAGE"

# Patch Calico DaemonSet to use the correct image for this architecture
echo "Patching Calico DaemonSet for architecture $ARCH..."
kubectl -n kube-system patch daemonset calico-node \
  --type='json' \
  -p="[{
        \"op\": \"replace\",
        \"path\": \"/spec/template/spec/containers/0/image\",
        \"value\": \"$CALICO_NODE_IMAGE\"
      }]"

# Delete old Calico pods to force recreation
echo "Deleting old Calico pods..."
kubectl delete pods -n kube-system -l k8s-app=calico-node --force --grace-period=0 || true

# Wait for Calico pods to become Ready
echo "Waiting for Calico pods to be Ready..."
while true; do
    NOT_READY=$(kubectl get pods -n kube-system -l k8s-app=calico-node | grep -v "Running" || true)
    if [ -z "$NOT_READY" ]; then
        break
    fi
    echo "Calico pods still initializing..."
    sleep 5
done

echo "Calico networking is now up on node $NODE_NAME!"
echo "Worker node $NODE_NAME successfully joined the cluster."

