#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")"

mise install

CLUSTER_NAME="${KIND_CLUSTER_NAME:-kind}"

if kind get clusters 2>/dev/null | grep -qx "${CLUSTER_NAME}"; then
  echo "Kind cluster '${CLUSTER_NAME}' already exists. Skipping creation."
else
    kind create cluster --name "${CLUSTER_NAME}" --config ../platform/kind/kind-config.yaml
fi

kustomize build --enable-helm ../platform/argocd | kubectl apply --server-side -f -

echo "==> Waiting for ArgoCD server to be ready..."
kubectl rollout status deployment/argocd-server -n argocd --timeout=3m

kubectl apply --server-side -f ../platform/argocd/bootstrap/root-app.yaml