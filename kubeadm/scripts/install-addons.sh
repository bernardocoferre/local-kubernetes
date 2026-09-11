#!/bin/bash
# Installs cluster addons that require the full cluster, including worker nodes, to be available.
# Runs on master-1 (where kubectl/admin.conf actually work), invoked remotely over SSH by post-provision.sh.

set -euo pipefail

export KUBECONFIG=/etc/kubernetes/admin.conf

# Install MetalLB as the load balancer for the cluster in FRR-K8s mode.
# However, because we're using kube-proxy in IPVS mode, we need first to enable strict ARP mode.
# MetalLB preparation: https://metallb.io/installation/#preparation
# MetalLB installation: https://metallb.io/installation/#installation-by-manifest
kubectl get configmap kube-proxy -n kube-system -o yaml | \
  sed -e "s/strictARP: false/strictARP: true/" | \
  kubectl apply -f - -n kube-system

METALLB_VERSION=v0.16.1
kubectl apply -f "https://raw.githubusercontent.com/metallb/metallb/${METALLB_VERSION}/config/manifests/metallb-frr-k8s.yaml"

# Wait for MetalLB to be running before proceeding with the configuration.
kubectl wait --namespace metallb-system --for=condition=available deployment --all --timeout=120s
kubectl apply -f /vagrant/manifests/metallb-ip-pool.yaml
