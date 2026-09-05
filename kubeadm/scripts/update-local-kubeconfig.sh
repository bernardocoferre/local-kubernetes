#!/bin/bash
# Rebuilds the local@kubeadm cluster/user/context in ~/.kube/config from the admin.conf the master node generated.
# kubeadm init mints a fresh CA on every recreation, so entries always need to be updated.

set -euo pipefail

CONTEXT_NAME="local@kubeadm"
MASTER_MACHINE="$1"
KUBECONFIG_PATH="$HOME/.kube/config"

ADMIN_CONF=$(vagrant ssh "$MASTER_MACHINE" -c "sudo cat /etc/kubernetes/admin.conf" \
    -- -i "$HOME/.vagrant.d/insecure_private_key" -o IdentitiesOnly=yes 2>/dev/null) || {
  echo "WARNING: could not fetch admin.conf from $MASTER_MACHINE -- skipping kubeconfig update"
  exit 0
}

# kubeadm always names these the same way, so a straight rename covers the whole file -- no need to pick apart individual cert/key fields.
# The current-context line is dropped so the master's context doesn't hijack whatever context was selected locally.
RENAME_RULES=(
  -e "s/name: kubernetes-admin@kubernetes/name: $CONTEXT_NAME/"
  -e "s/name: kubernetes-admin$/name: $CONTEXT_NAME/"
  -e "s/name: kubernetes$/name: $CONTEXT_NAME/"
  -e "s/cluster: kubernetes$/cluster: $CONTEXT_NAME/"
  -e "s/user: kubernetes-admin$/user: $CONTEXT_NAME/"
  -e "/^current-context:/d"
)
RENAMED_YAML=$(printf '%s\n' "$ADMIN_CONF" | sed "${RENAME_RULES[@]}")

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT
printf '%s\n' "$RENAMED_YAML" > "$WORKDIR/renamed.conf"

MERGED=$(KUBECONFIG="$WORKDIR/renamed.conf:$KUBECONFIG_PATH" kubectl config view --flatten) || {
  echo "WARNING: failed to merge kubeconfig -- leaving ~/.kube/config untouched"
  exit 0
}

mkdir -p "$(dirname "$KUBECONFIG_PATH")"
printf '%s\n' "$MERGED" > "$KUBECONFIG_PATH"
chmod 600 "$KUBECONFIG_PATH"

echo "Updated ~/.kube/config: $CONTEXT_NAME refreshed"
