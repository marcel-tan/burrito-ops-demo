#!/usr/bin/env bash
# Mutate the running demo targets out-of-band, the way an on-call engineer would
# during an incident: kubectl straight at the cluster, edits on the store hosts,
# and a hand-edited copy of the Azure state.
#
# Nothing here touches the git working tree. That is the point: after this runs,
# the repo says one thing and the running estate says another.
#
# Usage: ./scripts/introduce_drift.sh
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONTEXT="kind-burrito-ops"
NAMESPACE="burritoworks-local"
DRIFT_DIR="${REPO_ROOT}/.drift"

log() { printf '\n== %s\n' "$*"; }

log "Kubernetes: scaling order-ahead by hand (incident response, never reverted)"
kubectl --context "${CONTEXT}" -n "${NAMESPACE}" scale deployment/order-ahead-order-ahead --replicas=4

log "Kubernetes: dropping the catering memory limit to stop OOMKills"
kubectl --context "${CONTEXT}" -n "${NAMESPACE}" patch deployment/catering-catering --type json \
  -p '[{"op":"remove","path":"/spec/template/spec/containers/0/resources/limits"}]'

log "Kubernetes: disabling the order-ahead readiness probe"
kubectl --context "${CONTEXT}" -n "${NAMESPACE}" patch deployment/order-ahead-order-ahead --type json \
  -p '[{"op":"remove","path":"/spec/template/spec/containers/0/readinessProbe"}]'

log "Kubernetes: adding an untracked debug env var"
kubectl --context "${CONTEXT}" -n "${NAMESPACE}" set env deployment/order-ahead-order-ahead \
  LOG_LEVEL=debug PROMO_BYPASS=true

log "Store hosts: editing config in place over SSH"
for port in 2201 2202 2203; do
  sshpass -p bwops ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -p "${port}" bwops@localhost \
    'S() { echo bwops | sudo -S "$@" 2>/dev/null; };
     S sed -i "s/^log_level=.*/log_level=debug/" /etc/burritoworks/agent.conf;
     S sh -c "echo poll_interval=5 >> /etc/burritoworks/agent.conf";
     S rm -f /etc/burritoworks/certs/store.crt;
     S touch /etc/burritoworks/.hand-edited' 2>/dev/null \
    && echo "drifted store host on port ${port}" \
    || echo "could not reach store host on port ${port} (is scripts/demo/up.sh running?)"
done

log "Azure: simulating out-of-band portal changes"
mkdir -p "${DRIFT_DIR}"
cat > "${DRIFT_DIR}/azure-observed.json" <<'JSON'
{
  "_comment": "Stands in for `az` queries against the real subscription so the drift check can run offline.",
  "environments": {
    "prod": {
      "aks": {
        "kubernetes_version": "1.26.10",
        "node_pools": {
          "system": { "node_count": 3, "vm_size": "Standard_D4s_v3" },
          "apps": { "node_count": 9, "vm_size": "Standard_D8s_v3" }
        },
        "tags": { "environment": "prod" }
      },
      "nsg_rules": [
        { "name": "allow-https-ingress", "source_address_prefix": "10.0.0.0/8", "access": "Allow" },
        { "name": "allow-promo-loadtest", "source_address_prefix": "0.0.0.0/0", "access": "Allow" },
        { "name": "allow-vendor-jumpbox", "source_address_prefix": "203.0.113.19/32", "access": "Allow" }
      ],
      "storage": {
        "stbwplatformprod": { "menu_assets_public_access": "blob", "min_tls_version": "TLS1_0" }
      }
    }
  }
}
JSON
echo "wrote ${DRIFT_DIR}/azure-observed.json"

log "Drift introduced"
cat <<'EOF'
Now run:
  ./scripts/check_drift.sh
EOF
