#!/bin/bash
set -e

NEW_IP="192.168.1.99"

echo "Step 1: Backup existing PKI..."
sudo mkdir -p /etc/kubernetes/pki/backup
sudo rsync -av --exclude backup /etc/kubernetes/pki/ /etc/kubernetes/pki/backup/

echo "Step 2: Update etcd static pod manifest with new IP..."
ETCD_MANIFEST="/etc/kubernetes/manifests/etcd.yaml"
sudo sed -i "s/--initial-advertise-peer-urls=.*$/--initial-advertise-peer-urls=https:\/\/$NEW_IP:2380/" $ETCD_MANIFEST
sudo sed -i "s/--listen-peer-urls=.*$/--listen-peer-urls=https:\/\/$NEW_IP:2380/" $ETCD_MANIFEST
sudo sed -i "s/--advertise-client-urls=.*$/--advertise-client-urls=https:\/\/$NEW_IP:2379/" $ETCD_MANIFEST
sudo sed -i "s/--listen-client-urls=.*$/--listen-client-urls=https:\/\/127.0.0.1:2379,https:\/\/$NEW_IP:2379/" $ETCD_MANIFEST
sudo sed -i "s/kubeadm.kubernetes.io\/etcd.advertise-client-urls:.*$/kubeadm.kubernetes.io\/etcd.advertise-client-urls: https:\/\/$NEW_IP:2379/" $ETCD_MANIFEST

echo "Step 3: Remove old certificates..."
sudo rm -f /etc/kubernetes/pki/etcd/server.* \
             /etc/kubernetes/pki/etcd/peer.* \
             /etc/kubernetes/pki/etcd/healthcheck-client.* \
             /etc/kubernetes/pki/apiserver-etcd-client.* \
             /etc/kubernetes/pki/apiserver.*

echo "Step 4: Regenerate etcd certificates..."
sudo kubeadm init phase certs etcd-server
sudo kubeadm init phase certs etcd-peer
sudo kubeadm init phase certs etcd-healthcheck-client
sudo kubeadm init phase certs apiserver-etcd-client

echo "Step 5: Regenerate apiserver certificate with new IP..."
sudo kubeadm init phase certs apiserver --apiserver-cert-extra-sans $NEW_IP

echo "Step 6: Restart kubelet so static pods pick up new manifests and certs..."
sudo systemctl restart kubelet

echo "Step 7: Wait for etcd and kube-apiserver to start..."
sleep 15

echo "Step 8: Verify components..."
echo "Etcd:"
sudo crictl ps | grep etcd

echo "Kube-apiserver:"
sudo crictl ps | grep kube-apiserver

echo "Cluster nodes:"
kubectl get nodes

echo "Kube-system pods:"
kubectl get pods -n kube-system

echo "Step 9: Update kubeconfig with new IP..."
sudo sed -i "s/https:\/\/192\.168\.1\.[0-9]\+:6443/https:\/\/$NEW_IP:6443/" /etc/kubernetes/admin.conf
mkdir -p ~/.kube
sudo cp /etc/kubernetes/admin.conf ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
