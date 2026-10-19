#!/usr/bin/env bash
# ==============================================================================
# Teardown Script for Local Kind Kubernetes Cluster
# Ephemeral Environment Provisioning Platform
# Environment: WSL2 / Linux
# ==============================================================================

set -euo pipefail

CLUSTER_NAME="eep-cluster"

echo "=== [EEP Platform] Tearing down Kind Cluster '${CLUSTER_NAME}' ==="

if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
    kind delete cluster --name "${CLUSTER_NAME}"
    echo "Cluster '${CLUSTER_NAME}' has been successfully deleted."
else
    echo "Cluster '${CLUSTER_NAME}' does not exist. Nothing to tear down."
fi

