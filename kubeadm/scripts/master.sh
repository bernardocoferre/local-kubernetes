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

kubeadm token create --print-join-command > /vagrant/generated/join-command.sh
chmod +x /vagrant/generated/join-command.sh

# Install Flannel as the CNI, but patch it with --iface=eth1.
# Flannel otherwise picks the VM's NAT adapter (eth0) instead of the private network (eth1) the nodes
# actually use to reach each other, so pods would only be able to talk to other pods on the same node.
FLANNEL_VERSION=v0.28.1
curl -fsSL "https://raw.githubusercontent.com/flannel-io/flannel/${FLANNEL_VERSION}/Documentation/kube-flannel.yml" \
  | sed '/--kube-subnet-mgr/a\        - --iface=eth1' \
  | kubectl apply -f -

# Install local-path-provisioner so PVCs work out of the box, and mark its StorageClass as the cluster default.
LOCAL_PATH_PROVISIONER_VERSION=v0.0.37
kubectl apply -f "https://raw.githubusercontent.com/rancher/local-path-provisioner/refs/tags/${LOCAL_PATH_PROVISIONER_VERSION}/deploy/local-path-storage.yaml"
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'