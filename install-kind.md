# 🏗️ Installing Kind (Kubernetes in Docker)

Kind lets you run local Kubernetes clusters using Docker containers as nodes.

---

## Prerequisites

- **Docker Desktop** must be installed and running
  - [Download Docker Desktop](https://www.docker.com/products/docker-desktop/)
  - Verify: `docker --version`

---

## Installation

### macOS (Homebrew)

```bash
brew install kind
```

### macOS (Binary)

```bash
# For Apple Silicon (M1/M2/M3/M4)
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.25.0/kind-darwin-arm64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# For Intel Mac
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.25.0/kind-darwin-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

### Linux

```bash
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.25.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

### Windows (Chocolatey)

```powershell
choco install kind
```

### Go Install

```bash
go install sigs.k8s.io/kind@v0.25.0
```

---

## Verify Installation

```bash
kind --version
# Expected: kind v0.25.0
```

---

## Quick Start — Create a Cluster

### Default single-node cluster

```bash
kind create cluster
```

### Named cluster with config

```bash
kind create cluster --name my-cluster --config 00-kind-cluster.yaml
```

### Check the cluster

```bash
kubectl cluster-info --context kind-my-cluster
kubectl get nodes
```

---

## Useful Commands

| Command | Description |
|---------|-------------|
| `kind create cluster --name <name>` | Create a new cluster |
| `kind get clusters` | List all kind clusters |
| `kind delete cluster --name <name>` | Delete a cluster |
| `kind load docker-image <image> --name <name>` | Load a local Docker image into the cluster |
| `kind export logs --name <name>` | Export cluster logs for debugging |

---

## For This Demo

```bash
cd audit-enforce
kind create cluster --name auditor-gatekeeper --config 00-kind-cluster.yaml
```

Verify:

```bash
kubectl get nodes
# NAME                               STATUS   ROLES           AGE   VERSION
# auditor-gatekeeper-control-plane   Ready    control-plane   30s   v1.31.0
```

---

## Cleanup

```bash
kind delete cluster --name auditor-gatekeeper
```

---

## References

- [Kind Official Docs](https://kind.sigs.k8s.io/)
- [Kind GitHub](https://github.com/kubernetes-sigs/kind)
- [Kind Quick Start](https://kind.sigs.k8s.io/docs/user/quick-start/)
