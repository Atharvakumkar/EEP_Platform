#!/usr/bin/env bash
# ==============================================================================
# Setup Script for Local Kind Kubernetes Cluster & Ingress NGINX
# Ephemeral Environment Provisioning Platform
# Environment: WSL2 / Linux
# ==============================================================================

set -euo pipefail

CLUSTER_NAME="eep-cluster"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CONFIG_FILE="${PROJECT_ROOT}/k8s/kind-config.yaml"
INGRESS_MANIFEST="https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml"

echo "=== [EEP Platform] Checking Prerequisites ==="

# Check docker
if ! command -v docker &>/dev/null; then
    echo "ERROR: 'docker' command not found. Please ensure Docker Desktop is running with WSL2 integration." >&2
    exit 1
fi

if ! docker ps &>/dev/null; then
    echo "ERROR: Cannot connect to Docker daemon. Please verify Docker Desktop is running." >&2
    exit 1
fi

# Check kind
if ! command -v kind &>/dev/null; then
    echo "ERROR: 'kind' is not installed in WSL2. Please install kind to /usr/local/bin/kind." >&2
    exit 1
fi

# Check kubectl
if ! command -v kubectl &>/dev/null; then
    echo "ERROR: 'kubectl' is not installed in WSL2. Please install kubectl to /usr/local/bin/kubectl." >&2
    exit 1
fi

echo "Prerequisites verified."

# Check if cluster already exists
if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
    echo "Cluster '${CLUSTER_NAME}' already exists."
else
    echo "=== [EEP Platform] Creating Kind Cluster '${CLUSTER_NAME}' ==="
    kind create cluster --config "${CONFIG_FILE}"
fi

# Set kubectl context
kubectl cluster-info --context "kind-${CLUSTER_NAME}"

# Deploy Ingress NGINX
echo "=== [EEP Platform] Applying Ingress NGINX Controller ==="
kubectl apply -f "${INGRESS_MANIFEST}"

echo "Waiting for Ingress NGINX controller to become ready (up to 180s)..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s

echo "=== [EEP Platform] Cluster Setup Complete! ==="
echo "Node status:"
kubectl get nodes -o wide
echo ""
echo "Ingress controller status:"
kubectl get pods -n ingress-nginx
echo ""
echo "Test local routing on host:"
echo "  curl -I http://localhost:8080"

