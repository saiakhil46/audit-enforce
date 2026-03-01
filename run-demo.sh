#!/bin/bash
# =============================================================================
# 🎬 The Auditor and the Gatekeeper — Demo Script
# =============================================================================
# Run: chmod +x run-demo.sh && ./run-demo.sh
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Demo directory
DEMO_DIR="$(cd "$(dirname "$0")" && pwd)"

pause() {
  echo ""
  echo -e "${YELLOW}⏸  Press ENTER to continue...${NC}"
  read -r
}

header() {
  echo ""
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${BLUE}  $1${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
}

success() {
  echo -e "${GREEN}✅ $1${NC}"
}

error_msg() {
  echo -e "${RED}❌ $1${NC}"
}

info() {
  echo -e "${BLUE}ℹ️  $1${NC}"
}

# =============================================================================
header "🎬 THE AUDITOR AND THE GATEKEEPER"
echo -e "${BOLD}A Two-Step Strategy for Healthy Kubernetes Clusters${NC}"
echo ""
echo -e "  🔍 ${CYAN}Popeye${NC}  — The Auditor  (finds problems)"
echo -e "  🛡️  ${CYAN}Kyverno${NC} — The Gatekeeper (prevents problems)"
pause

# =============================================================================
header "STEP 0: Create Kind Cluster"
# =============================================================================

info "Creating kind cluster 'auditor-gatekeeper'..."

# Delete if exists
kind delete cluster --name auditor-gatekeeper 2>/dev/null || true

kind create cluster --name auditor-gatekeeper --config "$DEMO_DIR/00-kind-cluster.yaml"

success "Kind cluster created!"
echo ""
kubectl cluster-info
echo ""
kubectl get nodes
echo ""

info "Installing metrics-server (needed by Popeye for resource utilization checks)..."
kubectl apply -f "$DEMO_DIR/00-metrics-server.yaml"

echo ""
info "Waiting for metrics-server to be ready..."
kubectl wait --for=condition=ready pod -l k8s-app=metrics-server -n kube-system --timeout=120s

success "Metrics-server installed!"
echo ""
info "Waiting 30s for metrics to be collected..."
sleep 30
kubectl top nodes || true
pause

# =============================================================================
header "STEP 1: Deploy BAD Workloads 🚨"
# =============================================================================

info "Deploying intentionally misconfigured workloads..."
echo ""
echo -e "${RED}  ❌ Using :latest image tag"
echo "  ❌ No resource requests/limits"
echo "  ❌ No liveness/readiness probes"
echo "  ❌ Running as root"
echo -e "  ❌ Missing recommended labels${NC}"
echo ""

kubectl create namespace audit-enforce
kubectl apply -f "$DEMO_DIR/01-bad-workloads.yaml"

echo ""
info "Waiting for pods to start..."
sleep 10
kubectl get pods -n audit-enforce
pause

# =============================================================================
header "STEP 2: 🔍 Run Popeye — The Auditor Finds Problems"
# =============================================================================

info "Scanning the audit-enforce namespace with Popeye..."
echo ""
echo -e "${YELLOW}Watch the issues Popeye discovers...${NC}"
echo ""

popeye -n audit-enforce --force-exit-zero || true

echo ""
info "Saving HTML report..."
POPEYE_REPORT_DIR="$DEMO_DIR" popeye -n audit-enforce --save --out html --output-file popeye-BEFORE.html --force-exit-zero || true

echo ""
echo -e "${RED}📉 Popeye found many issues! But it's read-only — it can't prevent them.${NC}"
echo -e "${YELLOW}💡 That's where Kyverno (The Gatekeeper) comes in!${NC}"
pause

# =============================================================================
header "STEP 3: 🛡️ Install Kyverno — The Gatekeeper"
# =============================================================================

info "Installing Kyverno via Helm..."
echo ""

helm repo add kyverno https://kyverno.github.io/kyverno/ 2>/dev/null || true
helm repo update

helm install kyverno kyverno/kyverno -n kyverno --create-namespace \
  --wait --timeout 120s

echo ""
success "Kyverno installed!"
kubectl get pods -n kyverno
pause

# =============================================================================
header "STEP 4: Apply Kyverno Policies"
# =============================================================================

info "Applying policies that enforce Kubernetes best practices..."
echo ""
echo "  🛡️ Policy 1: Disallow :latest tag"
echo "  🛡️ Policy 2: Require resource limits"
echo "  🛡️ Policy 3: Require liveness/readiness probes"
echo "  🛡️ Policy 4: Require runAsNonRoot"
echo "  🛡️ Policy 5: Require app & team labels"
echo "  🛡️ Policy 6: Auto-add default resource requests (mutate)"
echo ""

kubectl apply -f "$DEMO_DIR/02-kyverno-policies.yaml"

echo ""
success "Policies applied!"
echo ""
kubectl get validatingpolicy,mutatingpolicy
pause

# =============================================================================
header "STEP 5: 🚫 Try BAD Workloads Again — BLOCKED!"
# =============================================================================

info "Deleting old bad workloads..."
kubectl delete -f "$DEMO_DIR/01-bad-workloads.yaml" --ignore-not-found

echo ""
info "Attempting to re-deploy bad workloads..."
echo -e "${YELLOW}Watch Kyverno block them! 🛡️${NC}"
echo ""

# This should FAIL — capture and display the error
if kubectl apply -f "$DEMO_DIR/01-bad-workloads.yaml" 2>&1; then
  error_msg "Workloads were not blocked (unexpected)"
else
  echo ""
  success "Kyverno BLOCKED the bad workloads! 🎉"
  echo -e "${GREEN}The Gatekeeper prevented every issue that the Auditor flagged!${NC}"
fi
pause

# =============================================================================
header "STEP 6: ✅ Deploy GOOD Workloads"
# =============================================================================

info "Deploying best-practice workloads that comply with all policies..."
echo ""

kubectl apply -f "$DEMO_DIR/03-good-workloads.yaml"

echo ""
success "Good workloads deployed successfully!"
echo ""
info "Waiting for pods to start..."
sleep 15
kubectl get pods -n audit-enforce
echo ""
kubectl get pods -n audit-enforce --show-labels
pause

# =============================================================================
header "STEP 7: 🔍 Re-scan with Popeye — Clean Report!"
# =============================================================================

info "Running Popeye again on the compliant workloads..."
echo ""

popeye -n audit-enforce --force-exit-zero || true

echo ""
info "Saving HTML report..."
POPEYE_REPORT_DIR="$DEMO_DIR" popeye -n audit-enforce --save --out html --output-file popeye-AFTER.html --force-exit-zero || true

echo ""
success "📈 Score improved dramatically!"
pause

# =============================================================================
header "🎯 SUMMARY"
# =============================================================================

echo -e "${BOLD}The Two-Step Strategy:${NC}"
echo ""
echo -e "  ${CYAN}Step 1:${NC} 🔍 ${BOLD}Popeye${NC} scans and FINDS problems (Auditor)"
echo -e "  ${CYAN}Step 2:${NC} 🛡️  ${BOLD}Kyverno${NC} PREVENTS problems (Gatekeeper)"
echo ""
echo -e "  ${GREEN}Together = Healthy Kubernetes Clusters! 🏥${NC}"
echo ""
echo -e "  ${YELLOW}Audit ➜ Enforce ➜ Verify ➜ Repeat 🔄${NC}"
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "📊 HTML Reports saved:"
echo "   - $DEMO_DIR/popeye-BEFORE.html"
echo "   - $DEMO_DIR/popeye-AFTER.html"
echo ""

# =============================================================================
header "🧹 CLEANUP"
# =============================================================================

echo -e "Run the following to clean up:"
echo ""
echo -e "  ${CYAN}kind delete cluster --name auditor-gatekeeper${NC}"
echo ""
