# kind cluster

Single-node control-plane + 2 workers, running in Docker via [kind](https://kind.sigs.k8s.io/).
Ports 80/443/8080 are mapped to the host for ingress testing.

## Prerequisites

- Docker (or a Docker-compatible runtime)
- `brew install kind kubectl`

## Usage

```sh
kind create cluster --config config.yaml --name kind
kubectl config rename-context kind-kind <context>
kubectl config use-context <context>
```

## Teardown

```sh
kind delete cluster --name kind
```
