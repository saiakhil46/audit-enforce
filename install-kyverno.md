# 🛡️ Installing Kyverno — The Kubernetes Policy Engine (Gatekeeper)

Kyverno (Greek for "govern") is a cloud native policy engine designed for
Kubernetes. It validates, mutates, generates, and cleans up resources using
policies written in YAML with CEL expressions.

---

## What Kyverno Does

- **Validate** — Block resources that violate policies (e.g., no `:latest` tag)
- **Mutate** — Automatically modify resources (e.g., add default labels)
- **Generate** — Create resources when others are created (e.g., NetworkPolicies)
- **Cleanup** — Remove resources based on conditions
- **Verify Images** — Validate container image signatures and attestations
- Policies are written in **YAML + CEL** — no new language to learn
- Produces **Policy Reports** for visibility

---

## Prerequisites

- A running Kubernetes cluster (kind, minikube, EKS, GKE, AKS, etc.)
- **Helm 3** installed
- **kubectl** configured to talk to your cluster

### Install Helm (if needed)

```bash
# macOS
brew install helm

# Linux
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify
helm version
```

---

## Installation

### Option 1: Helm (Recommended)

#### Non-Production / Demo Install

```bash
# Add the Kyverno Helm repo
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update

# Install Kyverno
helm install kyverno kyverno/kyverno -n kyverno --create-namespace
```

#### High Availability Install (Production)

```bash
helm install kyverno kyverno/kyverno -n kyverno --create-namespace \
  --set admissionController.replicas=3 \
  --set backgroundController.replicas=2 \
  --set cleanupController.replicas=2 \
  --set reportsController.replicas=2
```

### Option 2: YAML Manifest

```bash
kubectl create -f https://github.com/kyverno/kyverno/releases/download/v1.16.2/install.yaml
```

---

## Verify Installation

```bash
# Check pods are running
kubectl get pods -n kyverno

# Expected output (non-production install):
# NAME                                             READY   STATUS    AGE
# kyverno-admission-controller-xxxxx               1/1     Running   60s
# kyverno-background-controller-xxxxx              1/1     Running   60s
# kyverno-cleanup-controller-xxxxx                 1/1     Running   60s
# kyverno-reports-controller-xxxxx                 1/1     Running   60s
```

Wait for all pods to be ready:

```bash
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=kyverno -n kyverno --timeout=120s
```

---

## Kyverno Components

| Component | Role |
|-----------|------|
| **Admission Controller** | Intercepts API requests, enforces validate/mutate policies |
| **Background Controller** | Handles generate and mutate-existing rules |
| **Reports Controller** | Creates and manages Policy Reports |
| **Cleanup Controller** | Processes cleanup policies |

---

## Quick Start — Your First Policy

### Validate: Require a label

```yaml
apiVersion: policies.kyverno.io/v1alpha1
kind: ValidatingPolicy
metadata:
  name: require-team-label
spec:
  validationActions:
    - Deny
  matchConstraints:
    resourceRules:
      - apiGroups: [""]
        apiVersions: ["v1"]
        operations: ["CREATE", "UPDATE"]
        resources: ["pods"]
  validations:
    - message: "The label 'team' is required."
      expression: >-
        has(object.metadata.labels) &&
        has(object.metadata.labels.team) &&
        object.metadata.labels.team != ''
```

Apply it:

```bash
kubectl apply -f policy.yaml
```

Test it:

```bash
# This will be BLOCKED ❌
kubectl run test-pod --image=nginx

# This will PASS ✅
kubectl run test-pod --image=nginx --labels team=backend
```

---

## Policy Types

| Type | API Kind | Purpose |
|------|----------|---------|
| Validate | `ValidatingPolicy` | Block non-compliant resources |
| Mutate | `MutatingPolicy` | Auto-modify resources |
| Generate | `GeneratingPolicy` | Auto-create resources |
| Delete | `DeletingPolicy` | Auto-delete resources |
| Image Verify | `ImageValidatingPolicy` | Verify image signatures |

---

## Useful Commands

| Command | Description |
|---------|-------------|
| `kubectl get validatingpolicy` | List validation policies |
| `kubectl get mutatingpolicy` | List mutation policies |
| `kubectl get policyreport -A` | View policy reports across all namespaces |
| `kubectl get policyreport -o wide` | Detailed policy report with pass/fail counts |
| `kubectl describe validatingpolicy <name>` | Policy details |

---

## Policy Reports

Kyverno generates Policy Reports showing pass/fail results:

```bash
# View reports
kubectl get policyreport -A -o wide

# Example output:
# NAMESPACE   NAME                   KIND         PASS   FAIL   WARN   ERROR
# audit-enforce    polr-audit-enforce-xxxxx    Pod          3      0      0      0
```

---

## Validation Actions

| Action | Behavior |
|--------|----------|
| `Deny` | Block the resource (enforcement mode) |
| `Warn` | Allow but show a warning to the user |
| `Audit` | Allow silently, record in Policy Reports only |

---

## For This Demo

### Install

```bash
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update
helm install kyverno kyverno/kyverno -n kyverno --create-namespace
```

### Apply Demo Policies

```bash
kubectl apply -f 02-kyverno-policies.yaml
```

### Verify Policies

```bash
kubectl get validatingpolicy,mutatingpolicy
```

### Check Policy Reports (after deploying workloads)

```bash
kubectl get policyreport -n audit-enforce -o wide
```

---

## Uninstall

```bash
helm uninstall kyverno -n kyverno
kubectl delete namespace kyverno
```

---

## References

- [Kyverno Official Website](https://kyverno.io/)
- [Kyverno Documentation](https://kyverno.io/docs/)
- [Kyverno Quick Start](https://kyverno.io/docs/introduction/quick-start/)
- [Kyverno Policy Library (600+ policies)](https://kyverno.io/policies/)
- [Kyverno GitHub](https://github.com/kyverno/kyverno)
- [Kyverno Slack — #kyverno](https://slack.k8s.io/)
