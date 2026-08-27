#!/usr/bin/env bash
# Run the platform policy suite (policy/) against the Terraform, Helm and
# Ansible layers. This is the same check the Azure DevOps pipelines run.
#
# On the seeded scaffold this FAILS on purpose: see docs/backlog.md.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

FAILED=0
section() { printf '\n=== %s\n' "$*"; }
record() { [ "$1" -eq 0 ] || FAILED=1; }

section "Terraform: environment tfvars"
conftest test --parser hcl2 -p policy/terraform \
  infra/terraform/envs/dev/dev.tfvars \
  infra/terraform/envs/staging/staging.tfvars \
  infra/terraform/envs/prod/prod.tfvars
record $?

section "Terraform: environment roots"
conftest test --parser hcl2 -p policy/terraform \
  infra/terraform/envs/dev/main.tf infra/terraform/envs/dev/providers.tf \
  infra/terraform/envs/staging/main.tf infra/terraform/envs/staging/providers.tf \
  infra/terraform/envs/prod/main.tf infra/terraform/envs/prod/providers.tf
record $?

section "Helm: rendered manifests"
for env in dev staging prod; do
  for chart in order-ahead catering; do
    printf -- '-- %s/%s\n' "${env}" "${chart}"
    helm template "${chart}" "infra/helm/charts/${chart}" \
      -f "infra/helm/values/${env}/${chart}.yaml" |
      conftest test --parser yaml -p policy/kubernetes -
    record $?
  done
done

section "Ansible: inventory variables"
conftest test --parser yaml -p policy/ansible \
  infra/ansible/inventories/stores/group_vars/all.yml
record $?

section "Ansible: per-site ACLs"
conftest test --parser yaml -p policy/ansible \
  infra/ansible/inventories/stores/host_vars/*.yml
record $?

if [ "${FAILED}" -eq 0 ]; then
  printf '\npolicy suite passed\n'
else
  printf '\npolicy suite FAILED (expected on the seeded scaffold)\n'
fi
exit "${FAILED}"
