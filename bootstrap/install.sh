#!/usr/bin/env bash
# bootstrap/install.sh
# Installs ArgoCD via Helm and applies the root Application.
#
# Usage:
#   ./bootstrap/install.sh                        # installs latest chart version
#   ARGOCD_CHART_VERSION=7.8.3 ./bootstrap/install.sh  # pins a specific version
#
# Requirements:
#   - helm >= 3.x
#   - kubeconfig pointing to target cluster
#   - kubectl (for applying root-app.yaml)

set -euo pipefail

mise install

NAMESPACE="argocd"
RELEASE_NAME="argocd"
REPO_URL="https://argoproj.github.io/argo-helm"
CHART_NAME="argo/argo-cd"
VALUES_FILE="$(dirname "$0")/argocd/values.yaml"
ROOT_APP="$(dirname "$0")/root-app.yaml"

# Pin version or use latest
CHART_VERSION="${ARGOCD_CHART_VERSION:-}"

echo "==> Adding argo helm repo..."
helm repo add argo "${REPO_URL}" --force-update
helm repo update argo

if [ -z "${CHART_VERSION}" ]; then
  CHART_VERSION=$(helm search repo argo/argo-cd --output json | \
    python3 -c "import sys,json; print(json.load(sys.stdin)[0]['version'])")
  echo "==> Latest chart version detected: ${CHART_VERSION}"
else
  echo "==> Using pinned chart version: ${CHART_VERSION}"
fi

echo "==> Installing ArgoCD ${CHART_VERSION} into namespace '${NAMESPACE}'..."
helm upgrade --install "${RELEASE_NAME}" "${CHART_NAME}" \
  --namespace "${NAMESPACE}" \
  --create-namespace \
  --version "${CHART_VERSION}" \
  --values "${VALUES_FILE}" \
  --wait \
  --timeout 5m

echo "==> Waiting for ArgoCD server to be ready..."
kubectl rollout status deployment/argocd-server -n "${NAMESPACE}" --timeout=3m

echo "==> Applying root Application..."
kubectl apply -f "${ROOT_APP}"

echo ""
echo "✅ ArgoCD bootstrap complete!"
echo ""
echo "   Chart version : ${CHART_VERSION}"
echo "   Namespace     : ${NAMESPACE}"
echo ""
echo "   Get initial admin password:"
echo "   kubectl -n argocd get secret argocd-initial-admin-secret \\"
echo "     -o jsonpath='{.data.password}' | base64 -d && echo"
echo ""
echo "   Port-forward to access UI:"
echo "   kubectl port-forward svc/argocd-server -n argocd 8080:443"