#!/bin/bash

set -euo pipefail

# Trust the personal key the file provisioner staged, without dropping
# whatever authorized_keys already had (e.g. the Vagrant insecure key)
grep -qxFf /home/vagrant/.ssh/personal_key.pub /home/vagrant/.ssh/authorized_keys \
  || cat /home/vagrant/.ssh/personal_key.pub >> /home/vagrant/.ssh/authorized_keys

# Enable IPv4 packet forwarding
# https://kubernetes.io/docs/setup/production-environment/container-runtimes/#prerequisite-ipv4-forwarding-optional
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF
sysctl --system

# Install containerd
# https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository
apt update
apt install ca-certificates curl -y
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF
apt update
apt install containerd.io -y

# Configure containerd
mv /etc/containerd/config.toml /etc/containerd/config.toml.bak
containerd config default > /etc/containerd/config.toml
systemctl restart containerd

# Disable swap
# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#swap-configuration
swapoff -a
sed -i '/^\/swap\.img/s/^/#/' /etc/fstab

# Install kubeadm, kubelet and kubectl
# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#installing-kubeadm-kubelet-and-kubectl
apt-get install -y apt-transport-https ca-certificates curl gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
systemctl enable --now kubelet

# Enable br_netfilter module for flannel
echo "br_netfilter" >> /etc/modules-load.d/modules.conf
modprobe br_netfilter

# Add --node-ip to kubelet CNI configuration
IP=$(ip -4 -o addr show eth1 | awk '{print $4}' | cut -d/ -f1)

if [ -z "$IP" ]; then
  echo "Failed to get IP for eth1"
  exit 1
fi

cat <<EOF > /etc/default/kubelet
KUBELET_EXTRA_ARGS=--node-ip=${IP}
EOF

systemctl restart kubelet
