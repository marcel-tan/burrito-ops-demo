#!/usr/bin/env bash
# Compare the running estate against what the repo declares, and report every
# difference. Runs nightly from azure-pipelines/nightly-drift.yml.
#
# Exit code 0 = no drift, 1 = drift found.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONTEXT="kind-burrito-ops"
NAMESPACE="burritoworks-local"
DRIFT_DIR="${REPO_ROOT}/.drift"
REPORT="${DRIFT_DIR}/drift-report.md"

mkdir -p "${DRIFT_DIR}"
: > "${REPORT}"

DRIFT=0
finding() {
  DRIFT=1
  printf -- '- %s\n' "$1" | tee -a "${REPORT}"
}
section() { printf '\n== %s\n' "$*"; printf '\n### %s\n\n' "$*" >> "${REPORT}"; }

printf '# Drift report\n\nGenerated %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "${REPORT}"

section "Kubernetes (Helm release vs live objects)"
for release in order-ahead catering; do
  if ! helm --kube-context "${CONTEXT}" status "${release}" -n "${NAMESPACE}" >/dev/null 2>&1; then
    echo "release ${release} not installed, skipping"
    continue
  fi
  rendered="${DRIFT_DIR}/${release}-declared.yaml"
  helm --kube-context "${CONTEXT}" get manifest "${release}" -n "${NAMESPACE}" > "${rendered}"

  deployment="${release}-${release}"
  declared_replicas=$(awk '/^  replicas:/ {print $2; exit}' "${rendered}")
  live_replicas=$(kubectl --context "${CONTEXT}" -n "${NAMESPACE}" \
    get "deployment/${deployment}" -o jsonpath='{.spec.replicas}' 2>/dev/null)
  if [ -n "${live_replicas}" ] && [ "${declared_replicas:-}" != "${live_replicas}" ]; then
    finding "${deployment}: replicas declared ${declared_replicas}, live ${live_replicas}"
  fi

  live_limits=$(kubectl --context "${CONTEXT}" -n "${NAMESPACE}" \
    get "deployment/${deployment}" -o jsonpath='{.spec.template.spec.containers[0].resources.limits}' 2>/dev/null)
  if grep -q 'limits:' "${rendered}" && [ -z "${live_limits}" ]; then
    finding "${deployment}: chart declares resource limits, live container has none"
  fi

  for probe in livenessProbe readinessProbe; do
    live_probe=$(kubectl --context "${CONTEXT}" -n "${NAMESPACE}" \
      get "deployment/${deployment}" -o jsonpath="{.spec.template.spec.containers[0].${probe}}" 2>/dev/null)
    if grep -q "${probe}:" "${rendered}" && [ -z "${live_probe}" ]; then
      finding "${deployment}: chart declares ${probe}, live container has none"
    fi
  done

  live_env=$(kubectl --context "${CONTEXT}" -n "${NAMESPACE}" \
    get "deployment/${deployment}" -o jsonpath='{.spec.template.spec.containers[0].env[*].name}' 2>/dev/null)
  for name in ${live_env}; do
    grep -q "name: ${name}$" "${rendered}" || finding "${deployment}: env var ${name} is set on the live object but not in the chart"
  done
done

section "Azure (declared tfvars vs observed subscription)"
observed="${DRIFT_DIR}/azure-observed.json"
if [ ! -f "${observed}" ]; then
  echo "no observed Azure state at ${observed}; run scripts/introduce_drift.sh first"
else
  declared_k8s=$(awk -F'"' '/kubernetes_version/ {print $2}' "${REPO_ROOT}/infra/terraform/envs/prod/prod.tfvars")
  live_k8s=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["environments"]["prod"]["aks"]["kubernetes_version"])' "${observed}")
  [ "${declared_k8s}" = "${live_k8s}" ] || finding "prod AKS: kubernetes_version declared ${declared_k8s}, observed ${live_k8s}"

  declared_apps=$(awk '/apps_node_count/ {print $3}' "${REPO_ROOT}/infra/terraform/envs/prod/main.tf")
  live_apps=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["environments"]["prod"]["aks"]["node_pools"]["apps"]["node_count"])' "${observed}")
  [ "${declared_apps:-}" = "${live_apps}" ] || finding "prod AKS: apps node_count declared ${declared_apps:-unset}, observed ${live_apps}"

  live_rules=$(python3 -c 'import json,sys;print(" ".join(r["name"] for r in json.load(open(sys.argv[1]))["environments"]["prod"]["nsg_rules"]))' "${observed}")
  for rule in ${live_rules}; do
    grep -rq "${rule}" "${REPO_ROOT}/infra/terraform" ||
      finding "prod NSG: rule ${rule} exists in the subscription but is not in Terraform"
  done

  live_tls=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["environments"]["prod"]["storage"]["stbwplatformprod"]["min_tls_version"])' "${observed}")
  [ "${live_tls}" = "TLS1_2" ] || finding "prod storage: min_tls_version observed ${live_tls}, standards.md 2.7 requires TLS1_2"
fi

section "Store hosts (declared baseline vs live config)"
for port in 2201 2202 2203; do
  out=$(sshpass -p bwops ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -o ConnectTimeout=5 -p "${port}" bwops@localhost \
    'grep -E "^(log_level|poll_interval)=" /etc/burritoworks/agent.conf 2>/dev/null;
     test -f /etc/burritoworks/.hand-edited && echo "HAND_EDITED";
     test -f /etc/burritoworks/certs/store.crt || echo "CERT_MISSING"' 2>/dev/null)
  if [ -z "${out}" ]; then
    echo "store host on port ${port} unreachable, skipping"
    continue
  fi
  grep -q 'log_level=debug' <<<"${out}" && finding "store host :${port}: agent.conf log_level=debug, baseline declares info"
  grep -q 'poll_interval=' <<<"${out}" && finding "store host :${port}: agent.conf has an untemplated poll_interval key"
  grep -q 'HAND_EDITED' <<<"${out}" && finding "store host :${port}: /etc/burritoworks/.hand-edited marker present"
  grep -q 'CERT_MISSING' <<<"${out}" && finding "store host :${port}: store.crt missing, edge baseline not applied"
done

if [ "${DRIFT}" -eq 0 ]; then
  printf '\nno drift detected\n'
  printf '\nNo drift detected.\n' >> "${REPORT}"
else
  printf '\ndrift detected -- report written to %s\n' "${REPORT}"
fi
exit "${DRIFT}"
