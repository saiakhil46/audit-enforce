# 🎬 The Auditor and the Gatekeeper

## A Two-Step Strategy for Healthy Kubernetes Clusters

> **Popeye** 🔍 (The Auditor) + **Kyverno** 🛡️ (The Gatekeeper)

---

## 📖 Story / Flow

| Step | What Happens | Tool |
|------|-------------|------|
| 1 | Create a kind cluster | `kind` |
| 2 | Deploy **intentionally bad** workloads | `kubectl` |
| 3 | **Scan** the cluster — find all the problems | 🔍 **Popeye** |
| 4 | Install Kyverno and apply **policies** | 🛡️ **Kyverno** |
| 5 | Try to deploy the **same bad workloads** — blocked! | 🛡️ **Kyverno** |
| 6 | Deploy **fixed workloads** — everything passes | ✅ Both tools |
| 7 | Re-scan with Popeye — clean report | 🔍 **Popeye** |

---

## 🛠️ Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) running
- [kind](https://kind.sigs.k8s.io/) — `brew install kind`
- [kubectl](https://kubernetes.io/docs/tasks/tools/) — `brew install kubectl`
- [Helm](https://helm.sh/) — `brew install helm`
- [Popeye](https://github.com/derailed/popeye) — `brew install derailed/popeye/popeye`

---

## 📁 Project Structure

```
audit-enforce/
├── README.md                  # This file — full walkthrough
├── 00-kind-cluster.yaml       # Kind cluster config
├── 00-metrics-server.yaml     # Metrics server (needed by Popeye)
├── 01-bad-workloads.yaml      # Intentionally misconfigured workloads
├── 02-kyverno-policies.yaml   # Kyverno policies (the gatekeeper)
├── 03-good-workloads.yaml     # Fixed workloads that pass everything
└── run-demo.sh                # One-click demo script (optional)
```

---

## 🚀 STEP-BY-STEP DEMO WALKTHROUGH

---

### STEP 0: Create the Kind Cluster

```bash
cd audit-enforce
kind create cluster --name audit-enforce --config 00-kind-cluster.yaml
```

Verify the cluster is running:
```bash
kubectl cluster-info
kubectl get nodes
```

Install **metrics-server** (required by Popeye for resource utilization checks):
```bash
kubectl apply -f 00-metrics-server.yaml
```

Wait for metrics-server to be ready:
```bash
kubectl wait --for=condition=ready pod -l k8s-app=metrics-server -n kube-system --timeout=120s
```

Verify metrics are flowing (wait ~60 seconds after install):
```bash
kubectl top nodes
```

> 💡 **Why metrics-server?** Popeye uses it to check if pods are over/under
> utilizing CPU and memory. Without it, Popeye shows a 💥 under MetricServer
> and skips all resource utilization checks.

---

### STEP 1: Deploy BAD Workloads (The Problem)

> "Let's see what happens when developers deploy without best practices..."

```bash
kubectl create namespace audit-enforce
kubectl apply -f 01-bad-workloads.yaml
```

Check they're running:
```bash
kubectl get pods -n audit-enforce
```

**What's wrong with these workloads?**

| Popeye Code | Issue | Why It's Bad |
|-------------|-------|-------------|
| `POP-101` | Using `:latest` image tag | Non-reproducible builds, unpredictable deployments |
| `POP-106` | No resource requests/limits | Can starve other pods or OOM the node |
| `POP-102` | No liveness/readiness probes | K8s can't detect unhealthy containers |
| `POP-302` | Pod running as root | Security vulnerability — container escape risk |
| `POP-306` | Container running as root | Same — at container level |
| `POP-300` | Uses "default" ServiceAccount | Overly permissive RBAC |
| `POP-108` | Unnamed container ports | Harder to reference in Services and policies |
| `POP-1102` | Service uses numeric targetPort | Should reference named port for clarity |
| `POP-1204` | No NetworkPolicy | Pod ingress/egress is completely open |
| `POP-206` | No PodDisruptionBudget | No availability guarantee during disruptions |
| — | Missing labels | Hard to manage, identify, and select resources |

---

### STEP 2: 🔍 Run Popeye — The Auditor Finds Problems

> "Now let's bring in our auditor to scan the cluster..."

**Scan the audit-enforce namespace:**
```bash
popeye -n audit-enforce
```

**Save an HTML report (great for presentations!):**
```bash
POPEYE_REPORT_DIR=$(pwd) popeye -n audit-enforce --save --out html --output-file popeye-before.html
```

**What Popeye will find:**
- 😱 `[POP-101]` Image tagged "latest" in use
- 😱 `[POP-106]` No resources requests/limits defined
- 😱 `[POP-102]` No probes defined
- 😱 `[POP-302]` Pod could be running as root user
- 😱 `[POP-306]` Container could be running as root user
- 😱 `[POP-300]` Uses "default" ServiceAccount
- 🔊 `[POP-108]` Unnamed port
- 🔊 `[POP-1102]` Service uses numeric target port instead of named port
- 😱 `[POP-1204]` Pod ingress/egress not secured by a network policy
- 🔊 `[POP-206]` Pod has no associated PodDisruptionBudget


> 💡 **Key Point**: Popeye found all the problems, but it's **read-only**.
> It can tell you what's wrong but **cannot prevent** bad deployments.
> That's where the Gatekeeper comes in!

---

### STEP 3: 🛡️ Install Kyverno — The Gatekeeper

> "Now let's install our gatekeeper to prevent these problems from happening again..."

```bash
# Add Kyverno Helm repo
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update

# Install Kyverno (non-production / demo mode)
helm install kyverno kyverno/kyverno -n kyverno --create-namespace
```

Wait for Kyverno to be ready:
```bash
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=kyverno -n kyverno --timeout=120s
```

Verify Kyverno is running:
```bash
kubectl get pods -n kyverno
```

---

### STEP 4: Apply Kyverno Policies

> "Let's set the rules — enforce best practices so bad workloads can never enter again..."

```bash
kubectl apply -f 02-kyverno-policies.yaml
```

Check the policies are active:
```bash
kubectl get clusterpolicy
```

**Policies we're enforcing:**

| # | Policy | What It Does | Mode |
|---|--------|-------------|------|
| 1 | `disallow-latest-tag` | Blocks images using `:latest` tag | **Enforce** |
| 2 | `require-resource-limits` | Blocks pods without CPU/memory limits | **Enforce** |
| 3 | `require-probes` | Blocks pods without liveness/readiness probes | **Enforce** |
| 4 | `require-run-as-non-root` | Blocks containers running as root | **Enforce** |
| 5 | `require-labels` | Blocks pods without `app` and `team` labels | **Enforce** |
| 6 | `add-default-resources` | Auto-adds default requests if missing | **Mutate** |

---

### STEP 5: Try to Deploy BAD Workloads Again — BLOCKED! 🚫

> "Watch what happens when someone tries to deploy the same bad workloads..."

First, clean up the old bad workloads:
```bash
kubectl delete -f 01-bad-workloads.yaml
```

Now try to re-deploy them:
```bash
kubectl apply -f 01-bad-workloads.yaml
```

**Expected Output:**
```
Error from server: error when creating "01-bad-workloads.yaml":
admission webhook "validate.kyverno.svc-fail" denied the request:

resource Deployment/audit-enforce/bad-nginx was blocked due to the following policies:
  disallow-latest-tag: ...
  require-resource-limits: ...
  require-probes: ...
```

> 🎉 **The Gatekeeper blocked the bad workloads!** Kyverno prevented
> every issue that Popeye flagged.

---

### STEP 6: Deploy GOOD Workloads — Everything Passes ✅

> "Now let's deploy workloads that follow best practices..."

```bash
kubectl apply -f 03-good-workloads.yaml
```

Verify they're running:
```bash
kubectl get pods -n audit-enforce
kubectl get pods -n audit-enforce --show-labels
```

**What's different about the good workloads?**

| Popeye Code | Before (Bad) | After (Good) |
|-------------|-------------|---------------|
| `POP-101` | `nginx:latest` | `nginx:1.27.3` (pinned tag) |
| `POP-106` | No resources | requests + limits set |
| `POP-102` | No probes | liveness + readiness defined |
| `POP-302/306` | Running as root | `runAsNonRoot: true` |
| `POP-300` | default ServiceAccount | Dedicated `app-service-account` |
| `POP-108` | Unnamed ports | Named ports (`http`, `redis`) |
| `POP-1102` | Numeric targetPort in Service | Named targetPort references |
| `POP-1204` | No NetworkPolicy | NetworkPolicy for each app |
| `POP-206` | No PDB | PodDisruptionBudget for nginx |
| — | No labels | `app` + `team` labels |

---

### STEP 7: 🔍 Re-scan with Popeye — Clean Report!

> "Let's ask our auditor to check again..."

```bash
popeye -n audit-enforce
```

**Save the after report:**
```bash
POPEYE_REPORT_DIR=$(pwd) popeye -n audit-enforce --save --out html --output-file popeye-after.html
```

**Expected Popeye Score: ~80-90 / 100** 📈

> 🎉 **The cluster is now healthy!**

---

## 🎯 Key Takeaway

```
┌──────────────────────────────────────────────────────────────┐
│                                                              │
│   🔍 Popeye (Auditor)    →  FINDS problems (read-only)      │
│   🛡️  Kyverno (Gatekeeper) →  PREVENTS problems (enforcing)  │
│                                                              │
│   Together = Healthy Kubernetes Clusters! 🏥                 │
│                                                              │
│   Audit ➜ Enforce ➜ Verify ➜ Repeat 🔄                      │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

| | Popeye 🔍 | Kyverno 🛡️ |
|---|---|---|
| **Role** | Auditor | Gatekeeper |
| **When** | After deployment | Before deployment |
| **Action** | Scan & Report | Validate, Mutate, Generate |
| **Modifies Cluster?** | No (read-only) | Yes (admission control) |
| **Use Case** | Find existing issues | Prevent future issues |
| **Together** | Find → Fix → Prevent → Verify |

---

## 🧹 Cleanup

```bash
# Delete everything
kind delete cluster --name audit-enforce
```

---

## 💡 Bonus Demo Ideas

1. **Show Policy Reports**: `kubectl get policyreport -A -o wide`
2. **Show HTML Popeye reports** side-by-side (before vs after)
3. **Live mutation demo**: Deploy a pod without labels → Kyverno auto-adds them
4. **Scan all namespaces**: `popeye -A` to show system namespace health too
