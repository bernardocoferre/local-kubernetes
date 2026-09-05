# kubeadm cluster

1 master + 2 workers, provisioned as VirtualBox VMs via Vagrant and bootstrapped with `kubeadm`.

## Prerequisites

- [Vagrant](https://www.vagrantup.com/) + [VirtualBox](https://www.virtualbox.org/)
- Your own SSH keypair at `~/.ssh/id_rsa[.pub]` (used for `vagrant ssh` access to the VMs)

## Usage

```sh
vagrant up
vagrant ssh master-1               # or worker-1 / worker-2
```

This also refreshes a `local@kubeadm` context in your `~/.kube/config` automatically (see "How it works" below) — no manual kubeconfig steps needed.

## Layout

- `Vagrantfile` — VM/network definitions and provisioning order
- `scripts/` — provisioning scripts (`common.sh` runs on every node; `master.sh`/`worker.sh` are role-specific)
- `generated/` — artifacts produced by a run (the kubeadm join command); gitignored, regenerated every `vagrant up`

## How it works

- `master.sh` runs `kubeadm init`, writes a join command to `generated/join-command.sh`, then installs Flannel as the cluster's CNI.
- `worker.sh` polls for that file and joins once it appears — so workers can provision in parallel with the master without racing it.
- After `vagrant up`, a trigger runs `scripts/update-local-kubeconfig.sh`, which fetches the master's `admin.conf` and rebuilds the `local@kubeadm` context in your local kubeconfig with the cluster's current CA/cert.
- If a full reset is needed, use `vagrant destroy && vagrant up`.
