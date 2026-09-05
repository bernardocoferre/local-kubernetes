# manifests

`kube-flannel-v0.28.1.yml` is vendored (not applied straight from GitHub) because it needs one manual change: `--iface=eth1` added to the `kube-flannel` container args.

Without it, Flannel picks the VM's default interface (`eth0`, the NAT adapter) instead of the private network (`eth1`, `172.16.0.0/24`) the nodes actually use to reach each other. Pods can then only communicate with other pods on the same node — cross-node pod traffic silently fails.

If you bump the Flannel version, re-pull the upstream manifest and re-add `--iface=eth1` to the same container args block.
