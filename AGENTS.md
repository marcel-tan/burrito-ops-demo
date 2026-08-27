# Repo conventions

BurritoWorks platform infrastructure. Two services (`services/order-ahead`,
`services/catering`), an Angular front end (`web/`), and the infrastructure that
runs them (`infra/`). `docs/standards.md` is the written platform standard and
the source of truth for what "correct" means here; `policy/` encodes it as
Conftest/OPA policy.

## Layout

| Path | What lives there |
| --- | --- |
| `services/` | The two application services, each with a Dockerfile, tests and an OpenAPI spec |
| `web/` | Angular front end, calls both services |
| `infra/terraform/` | AzureRM modules plus one root per environment |
| `infra/helm/` | Charts for both services, values per environment under `infra/helm/values/<env>/` |
| `infra/ansible/` | Store network and edge-host layer, AAP-shaped |
| `infra/targets/` | Local kind cluster and the SSH sandbox that stands in for store hosts |
| `azure-pipelines/` | Azure DevOps YAML: build/test, infra validate, deploy, nightly drift |
| `policy/` | Rego policies, one directory per layer |
| `scripts/legacy/` | The imperative before-state. Do not extend it; replace it |

## Rules

1. Never `terraform apply` or `az`/`kubectl` against a real subscription from a
   workstation. Plan-only locally; the pipelines apply.
2. Environment differences belong in tfvars and values files, never in a copied
   root or a copied role. If you are about to copy a directory, stop.
3. No secret literals. Key Vault for cloud, Ansible Vault or AAP credentials for
   the store fleet.
4. Ansible tasks must be idempotent: no `shell:` where a module exists, no
   `state: latest`, no `nohup`, `changed_when` on everything that stays.
5. Every infra change must leave `./scripts/policy_check.sh` no worse than it
   found it, and should aim to make it pass.

## Local checks

```bash
# services
(cd services/order-ahead && npm ci && npm run lint && npm test && npm run build)
(cd services/catering && pip install -r requirements.txt -r requirements-dev.txt && python -m pytest)

# infra
for e in dev staging prod; do (cd infra/terraform/envs/$e && terraform init -backend=false && terraform validate); done
helm lint infra/helm/charts/order-ahead infra/helm/charts/catering
(cd infra/ansible && ansible-lint playbooks/ roles/)
./scripts/policy_check.sh          # fails on the seeded violations, by design
```

## Local environment

`./scripts/demo/up.sh` builds both images, creates the `burrito-ops` kind
cluster, installs both charts into `burritoworks-local`, and starts three
SSH-enabled containers standing in for store edge hosts.
`./scripts/demo/down.sh` tears it all down.
