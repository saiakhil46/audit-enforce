# 🔍 Installing Popeye — The Kubernetes Cluster Auditor

Popeye is a read-only utility that scans live Kubernetes clusters and reports
potential issues with deployed resources and configurations.

---

## What Popeye Does

- Scans **live clusters** (not static YAML files)
- Detects misconfigurations, stale resources, and anti-patterns
- Checks resource requests/limits configuration
- Reports missing probes, resource limits, security issues, unused resources
- Generates reports in multiple formats (console, HTML, JSON, YAML, Prometheus)
- **Read-only** — never modifies any cluster resources

---

## Installation

### macOS (Homebrew) — Recommended

```bash
brew install derailed/popeye/popeye
```

### Linux (Homebrew/Linuxbrew)

```bash
brew install derailed/popeye/popeye
```

### Binary Download (macOS / Linux / Windows)

Download the latest release from [GitHub Releases](https://github.com/derailed/popeye/releases):

```bash
# macOS Apple Silicon
curl -Lo popeye.tar.gz https://github.com/derailed/popeye/releases/download/v0.22.1/popeye_darwin_arm64.tar.gz
tar xzf popeye.tar.gz
sudo mv popeye /usr/local/bin/
rm popeye.tar.gz

# macOS Intel
curl -Lo popeye.tar.gz https://github.com/derailed/popeye/releases/download/v0.22.1/popeye_darwin_amd64.tar.gz
tar xzf popeye.tar.gz
sudo mv popeye /usr/local/bin/
rm popeye.tar.gz

# Linux amd64
curl -Lo popeye.tar.gz https://github.com/derailed/popeye/releases/download/v0.22.1/popeye_linux_amd64.tar.gz
tar xzf popeye.tar.gz
sudo mv popeye /usr/local/bin/
rm popeye.tar.gz
```

### Go Install

```bash
go install github.com/derailed/popeye@latest
```

### Docker

```bash
docker run --rm -it \
  -v $HOME/.kube:/root/.kube \
  quay.io/derailed/popeye
```

### kubectl Plugin (Krew)

```bash
kubectl krew install popeye
kubectl popeye
```

---

## Verify Installation

```bash
popeye version
```

---

## Terminal Setup

Popeye uses 256 colors. Ensure your terminal supports it:

```bash
export TERM=xterm-256color
```

---

## Quick Start — Basic Scan

### Scan current namespace

```bash
popeye
```

### Scan a specific namespace

```bash
popeye -n audit-enforce
```

### Scan all namespaces

```bash
popeye -A
```

### Scan specific resource types

```bash
popeye -n audit-enforce -s pod,svc,deploy
```

### Use a specific kubeconfig context

```bash
popeye --context kind-auditor-gatekeeper
```

---

## Output Formats

| Format | Flag | Saveable | Description |
|--------|------|----------|-------------|
| `standard` | (default) | — | Colorized console output with icons |
| `jurassic` | `-o jurassic` | — | No colors, no icons |
| `html` | `-o html` | ✅ | HTML report (great for presentations!) |
| `json` | `-o json` | ✅ | JSON format |
| `yaml` | `-o yaml` | ✅ | YAML format |
| `junit` | `-o junit` | ✅ | JUnit XML |
| `score` | `-o score` | — | Single score number (0-100) |

### Save report to file

```bash
# Save HTML report
POPEYE_REPORT_DIR=$(pwd) popeye -n audit-enforce --save --out html --output-file report.html

# Save JSON report
POPEYE_REPORT_DIR=$(pwd) popeye -n audit-enforce --save --out json --output-file report.json
```

---

## Understanding the Report

### Severity Levels

| Icon | Level | Color | Meaning |
|------|-------|-------|---------|
| ✅ | OK | Green | All good |
| 🔊 | Info | Blue-Green | FYI — informational |
| 😱 | Warn | Yellow | Potential issue |
| 💥 | Error | Red | Action required |

### Common Issue Codes

| Code | Description |
|------|-------------|
| `POP-100` | No liveness probe defined |
| `POP-101` | No readiness probe defined |
| `POP-106` | No resource limits defined / Using `:latest` tag |
| `POP-107` | No resource requests defined |
| `POP-302` | Container runs as root |
| `POP-1207` | Pod not secured by a NetworkPolicy |

Full list: [Popeye Codes Documentation](https://github.com/derailed/popeye/blob/master/docs/codes.md)

---

## What Popeye Scans

| Resource | Checks |
|----------|--------|
| **Nodes** | Conditions, taints, CPU/MEM utilization |
| **Pods** | Status, probes, resources, images, security |
| **Services** | Endpoints, label matching, ports |
| **Deployments** | Pod template, utilization |
| **ConfigMaps** | Unused ConfigMaps |
| **Secrets** | Unused Secrets |
| **ServiceAccounts** | Unused ServiceAccounts |
| **PVs / PVCs** | Bound status, errors |
| **Ingress** | Validity |
| **NetworkPolicies** | Validity, coverage |
| **RBAC** | Unused Roles, ClusterRoles, Bindings |
| **HPA** | Utilization, max burst |
| **PDB** | MinAvailable config |

---

## For This Demo

```bash
# Scan before fixing (expect low score)
popeye -n audit-enforce

# Save HTML for presentation
POPEYE_REPORT_DIR=$(pwd) popeye -n audit-enforce --save --out html --output-file popeye-BEFORE.html --force-exit-zero

# Scan after fixing (expect high score)
popeye -n audit-enforce
POPEYE_REPORT_DIR=$(pwd) popeye -n audit-enforce --save --out html --output-file popeye-AFTER.html --force-exit-zero
```

> **Note:** Use `--force-exit-zero` to prevent non-zero exit codes when issues are found (useful in scripts).

---

## References

- [Popeye GitHub](https://github.com/derailed/popeye)
- [Popeye Codes](https://github.com/derailed/popeye/blob/master/docs/codes.md)
- [Spinach Configuration](https://github.com/derailed/popeye#spinachyaml)
