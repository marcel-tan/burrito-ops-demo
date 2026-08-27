#!/usr/bin/env bash
# Bring up the local demo targets: kind cluster with both services deployed via
# Helm, plus the three sandbox store hosts for the Ansible layer.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CLUSTER_NAME="burrito-ops"
NAMESPACE="burritoworks-local"

log() { printf '\n== %s\n' "$*"; }

log "Building service images"
docker build -q -t burritoworks/order-ahead:local "${REPO_ROOT}/services/order-ahead"
docker build -q -t burritoworks/catering:local "${REPO_ROOT}/services/catering"

if ! kind get clusters | grep -qx "${CLUSTER_NAME}"; then
  log "Creating kind cluster ${CLUSTER_NAME}"
  kind create cluster --config "${REPO_ROOT}/infra/targets/kind-cluster.yaml"
else
  log "kind cluster ${CLUSTER_NAME} already exists"
fi

log "Loading images into the cluster"
kind load docker-image --name "${CLUSTER_NAME}" burritoworks/order-ahead:local
kind load docker-image --name "${CLUSTER_NAME}" burritoworks/catering:local

log "Deploying charts"
kubectl --context "kind-${CLUSTER_NAME}" create namespace "${NAMESPACE}" \
  --dry-run=client -o yaml | kubectl --context "kind-${CLUSTER_NAME}" apply -f -
helm --kube-context "kind-${CLUSTER_NAME}" upgrade --install order-ahead \
  "${REPO_ROOT}/infra/helm/charts/order-ahead" \
  -n "${NAMESPACE}" -f "${REPO_ROOT}/infra/helm/values/local/order-ahead.yaml" --wait
helm --kube-context "kind-${CLUSTER_NAME}" upgrade --install catering \
  "${REPO_ROOT}/infra/helm/charts/catering" \
  -n "${NAMESPACE}" -f "${REPO_ROOT}/infra/helm/values/local/catering.yaml" --wait

log "Bringing up the sandbox store hosts"
docker compose -f "${REPO_ROOT}/infra/targets/docker-compose.yml" up -d --build

log "Targets are up"
cat <<'EOF'
order-ahead : http://localhost:30080/healthz
catering    : http://localhost:30081/healthz
store hosts : ssh bwops@localhost -p 2201 (password: bwops), also 2202 / 2203

Next:
  cd infra/ansible && ansible-playbook -i inventories/sandbox/hosts.yml playbooks/edge_baseline.yml
  cd web && npm start   # Angular app against both services
EOF
