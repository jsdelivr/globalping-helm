#!/bin/bash
# Script to test the Globalping Probe Helm chart

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
CHART_PATH="${CHART_PATH:-charts/globalping-probe}"
NAMESPACE="${NAMESPACE:-globalping-probe-test}"
RELEASE_NAME="${RELEASE_NAME:-test-probe}"
TIMEOUT="${TIMEOUT:-300s}"

# Function to print colored output
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

# Function to cleanup
cleanup() {
    print_info "Cleaning up..."
    helm uninstall "$RELEASE_NAME" --namespace "$NAMESPACE" 2>/dev/null || true
    kubectl delete namespace "$NAMESPACE" 2>/dev/null || true
}

# Trap cleanup on exit
trap cleanup EXIT

# Check prerequisites
print_info "Checking prerequisites..."

if ! command -v helm &> /dev/null; then
    print_error "Helm is not installed"
    exit 1
fi

if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed"
    exit 1
fi

if ! kubectl cluster-info &> /dev/null; then
    print_error "No Kubernetes cluster found"
    exit 1
fi

print_status "Prerequisites OK"

# Lint chart
print_info "Linting chart..."
helm lint "$CHART_PATH"
print_status "Lint passed"

# Template chart
print_info "Templating chart..."
helm template test "$CHART_PATH" \
    --set globalpingToken=test-token \
    > /tmp/globalping-probe-template.yaml
print_status "Template generated"

# Validate required resources are present
print_info "Validating template..."
for resource in "DaemonSet" "Secret" "ServiceAccount"; do
    if grep -q "kind: $resource" /tmp/globalping-probe-template.yaml; then
        print_status "$resource found"
    else
        print_error "$resource not found"
        exit 1
    fi
done

# Create test namespace
print_info "Creating test namespace..."
kubectl create namespace "$NAMESPACE" || true

# Check if GLOBALPING_TOKEN is set
if [ -z "$GLOBALPING_TOKEN" ]; then
    print_error "GLOBALPING_TOKEN environment variable is not set"
    print_info "Set it with: export GLOBALPING_TOKEN=your-token-here"
    print_info "Get a token from: https://globalping.io"
    exit 1
fi

# Install chart
print_info "Installing chart..."
helm install "$RELEASE_NAME" "$CHART_PATH" \
    --namespace "$NAMESPACE" \
    --set globalpingToken="$GLOBALPING_TOKEN" \
    --set resources.requests.cpu=50m \
    --set resources.requests.memory=128Mi \
    --set livenessProbe.initialDelaySeconds=30 \
    --set readinessProbe.initialDelaySeconds=15 \
    --wait \
    --timeout "$TIMEOUT"

print_status "Chart installed"

# Wait for pods to be ready
print_info "Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod \
    -l app.kubernetes.io/name=globalping-probe \
    -n "$NAMESPACE" \
    --timeout="$TIMEOUT" || {
    print_error "Pods did not become ready in time"
    kubectl get pods -n "$NAMESPACE"
    kubectl describe pods -l app.kubernetes.io/name=globalping-probe -n "$NAMESPACE"
    exit 1
}

print_status "Pods are ready"

# Get pod status
print_info "Pod status:"
kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=globalping-probe

# Check logs
print_info "Recent logs (last 20 lines):"
kubectl logs -l app.kubernetes.io/name=globalping-probe \
    -n "$NAMESPACE" \
    --tail=20 \
    --prefix=true

# Verify probe is running
print_info "Checking if probe process is running..."
POD_NAME=$(kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=globalping-probe -o jsonpath='{.items[0].metadata.name}')

if kubectl exec "$POD_NAME" -n "$NAMESPACE" -- pgrep -f node > /dev/null; then
    print_status "Node process is running"
else
    print_error "Node process is not running"
    exit 1
fi

# Test secret is created
print_info "Checking if secret was created..."
if kubectl get secret -n "$NAMESPACE" | grep -q "$RELEASE_NAME"; then
    print_status "Secret created"
else
    print_error "Secret not found"
    exit 1
fi

# Verify token is in secret
print_info "Verifying token in secret..."
SECRET_TOKEN=$(kubectl get secret "$RELEASE_NAME-globalping-probe" \
    -n "$NAMESPACE" \
    -o jsonpath='{.data.gp-adoption-token}' | base64 -d)

if [ -n "$SECRET_TOKEN" ]; then
    print_status "Token present in secret"
else
    print_error "Token not found in secret"
    exit 1
fi

# Test upgrade
print_info "Testing chart upgrade..."
helm upgrade "$RELEASE_NAME" "$CHART_PATH" \
    --namespace "$NAMESPACE" \
    --set globalpingToken="$GLOBALPING_TOKEN" \
    --set resources.limits.memory=384Mi \
    --wait \
    --timeout "$TIMEOUT"

print_status "Upgrade successful"

# Test with deployment mode
print_info "Testing deployment mode..."
helm upgrade "$RELEASE_NAME" "$CHART_PATH" \
    --namespace "$NAMESPACE" \
    --set globalpingToken="$GLOBALPING_TOKEN" \
    --set deploymentType=deployment \
    --set replicaCount=1 \
    --wait \
    --timeout "$TIMEOUT"

print_status "Deployment mode works"

# Check if deployment was created
if kubectl get deployment -n "$NAMESPACE" | grep -q "$RELEASE_NAME"; then
    print_status "Deployment created"
else
    print_error "Deployment not found"
    exit 1
fi

# Test rollback
print_info "Testing rollback..."
helm rollback "$RELEASE_NAME" --namespace "$NAMESPACE" --wait
print_status "Rollback successful"

# All tests passed
echo ""
print_status "All tests passed! ✨"
echo ""
print_info "Chart is ready for production use"
print_info "To clean up: helm uninstall $RELEASE_NAME --namespace $NAMESPACE"

