#!/bin/bash
# Host-side entry point for the post-provisioning cluster-addons trigger.
# The Vagrant trigger that invokes this runs on the host, so we need first to hop over SSH to run the real logic on master.

set -euo pipefail

MASTER_MACHINE="$1"

vagrant ssh "$MASTER_MACHINE" -c "bash /vagrant/scripts/install-addons.sh" \
  -- -i "$HOME/.vagrant.d/insecure_private_key" -o IdentitiesOnly=yes
