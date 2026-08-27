# BurritoWorks platform

Infrastructure and services for a fast-casual restaurant chain: ~400 stores, two
digital services, an AKS-based platform in Azure, and a store fleet of edge
routers, kitchen displays and POS gateways.

This repo is deliberately in a **mid-migration state**. The platform runs today
from the imperative scripts in `scripts/legacy/` and a nine-step manual runbook;
the declarative layers under `infra/` exist but are drifted, copy-pasted and in
violation of our own written standard. `docs/standards.md` says what correct
looks like, `policy/` encodes it, and `./scripts/policy_check.sh` shows how far
off we are. `docs/backlog.md` is the agreed list of work.

## Layout

```
services/order-ahead     Node/TypeScript ordering API (menu, cart, orders)
services/catering        Python/Flask catering API (packages, quotes, orders)
web/                     Angular front end, calls both services
infra/terraform          AzureRM modules + one root per environment
infra/helm               Charts for both services, values per environment
infra/ansible            Store network + edge host layer, AAP-shaped
infra/targets            Local kind cluster and SSH sandbox store hosts
azure-pipelines          Azure DevOps YAML: build/test, validate, deploy, drift
policy/                  Conftest/OPA policies per layer
scripts/legacy           The imperative before-state, plus the stale runbook
docs/standards.md        The written platform standard
docs/backlog.md          Azure Boards mirror
```

## Run the demo

Requires Docker, `kind`, `kubectl`, `helm`, `terraform`, `conftest`, `ansible`,
`sshpass`, Node 22 and Python 3.12.

1. **Bring up the local targets** — kind cluster with both services deployed via
   Helm, plus three SSH-enabled containers standing in for store edge hosts.

   ```bash
   ./scripts/demo/up.sh
   curl localhost:30080/healthz    # order-ahead
   curl localhost:30081/healthz    # catering
   ```

2. **Run the front end** against them.

   ```bash
   cd web && npm ci && npm start   # http://localhost:4200
   ```

3. **Validate the infrastructure** the way the pipelines do.

   ```bash
   for e in dev staging prod; do (cd infra/terraform/envs/$e && terraform init -backend=false && terraform validate); done
   helm lint infra/helm/charts/order-ahead infra/helm/charts/catering
   (cd infra/ansible && ansible-lint playbooks/ roles/)
   ./scripts/policy_check.sh       # fails on the seeded violations, by design
   ```

4. **Configure the store hosts** with the Ansible layer, then run it a second
   time and watch the non-idempotent tasks report changed again.

   ```bash
   cd infra/ansible
   ansible-playbook -i inventories/sandbox/hosts.yml playbooks/edge_baseline.yml
   ansible-playbook -i inventories/sandbox/hosts.yml playbooks/edge_baseline.yml
   ansible-playbook -i inventories/sandbox/hosts.yml playbooks/smoke_test.yml
   ```

5. **Break things out of band, then detect it.**

   ```bash
   ./scripts/introduce_drift.sh    # kubectl patches, SSH edits, simulated portal changes
   ./scripts/check_drift.sh        # exits 1 and writes .drift/drift-report.md
   ```

6. **Tear down.**

   ```bash
   ./scripts/demo/down.sh
   ```

Nothing here ever touches a real Azure subscription. `terraform apply` is a
pipeline-only operation and the demo runs plan/validate only.

## Known problems

Summarised in `docs/backlog.md`; `./scripts/policy_check.sh` reports the ones
that are machine-checkable. In short: secrets in tfvars, prod state on a laptop,
an NSG open to the world, three drifted Terraform roots, floating image tags and
missing limits/probes in Kubernetes, per-site store ACLs, a duplicated
network role, and a pile of non-idempotent shell tasks.
