#!/bin/bash

set -euo pipefail

cat > kubeadm-config.yml <<EOF
apiVersion: kubeadm.k8s.io/v1beta4
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: ${ADVERTISE_IP}
  bindPort: 6443
---
apiVersion: kubeadm.k8s.io/v1beta4
kind: ClusterConfiguration
networking:
  podSubnet: 10.244.0.0/16
---
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
EOF

kubeadm init --config kubeadm-config.yml

export KUBECONFIG=/etc/kubernetes/admin.conf
chmod 644 /etc/kubernetes/admin.conf
echo "KUBECONFIG=/etc/kubernetes/admin.conf" >> /etc/environment

kubectl apply -f /vagrant/manifests/kube-flannel-v0.28.1.yml

kubeadm token create --print-join-command > /vagrant/generated/join-command.sh
chmod +x /vagrant/generated/join-command.sh