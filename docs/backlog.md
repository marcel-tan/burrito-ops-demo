# Platform backlog

Azure Boards mirror. These are the items the platform team has already agreed
need doing; the code in this repo is the "before" state they describe.

| ID | Title | Type | Priority | Area |
| --- | --- | --- | --- | --- |
| PLAT-412 | Replace `scripts/legacy/` provisioning with the Terraform modules | Epic | 1 | Platform Engineering |
| PLAT-418 | Collapse the drifted dev/staging/prod Terraform roots onto one module set | Story | 1 | Platform Engineering |
| PLAT-421 | Move every tfvars secret into Key Vault | Story | 1 | Security |
| PLAT-425 | Close `allow-promo-loadtest` (0.0.0.0/0 on 443, prod) | Bug | 1 | Security |
| PLAT-427 | Put prod Terraform state in the remote backend | Bug | 1 | Platform Engineering |
| PLAT-431 | Restore probes in prod and resource limits in staging | Bug | 2 | Platform Engineering |
| PLAT-434 | Template store ACLs instead of per-site `host_vars` | Story | 2 | Network Engineering |
| PLAT-436 | Merge `store_network_baseline_west` back into `store_network_baseline` | Story | 2 | Network Engineering |
| PLAT-440 | Nightly drift detection that files a work item | Story | 3 | Platform Engineering |

---

## PLAT-412 — Replace `scripts/legacy/` provisioning with the Terraform modules

**As** a platform engineer **I want** environments provisioned from code **so
that** a turn-up is a pipeline run rather than a 40-minute babysitting session.

`scripts/legacy/provision-aks.sh` and `provision-storage.ps1` overlap, disagree,
and are not idempotent — a failed run leaves half an environment behind and the
next run dies on "already exists". `runbook.md` documents nine manual steps
around them, three of which happen in the portal.

Acceptance criteria:
- `infra/terraform/envs/<env>` fully describes each environment; no `az`/`Az`
  script is needed for a turn-up.
- `terraform plan` on a provisioned environment is empty.
- `scripts/legacy/` is deleted and `runbook.md` is replaced by pipeline docs.

## PLAT-418 — Collapse the drifted Terraform roots

The three environment roots were copy-pasted and have since diverged: prod runs
Kubernetes 1.26.10 while staging runs 1.28.5, storage `menu_assets` access
differs per environment, Key Vault settings differ, and staging carries an extra
`loyalty_api_key` variable nothing consumes.

Acceptance criteria:
- One module set; environment roots differ only by tfvars.
- Kubernetes version comes from a single supported-version variable.
- `conftest` reports no drift-class failures.

## PLAT-421 — Move every tfvars secret into Key Vault

`dev.tfvars`, `staging.tfvars` and `prod.tfvars` carry `sql_admin_password` and
`payments_api_key` literals in git; `scripts/legacy/` writes the same values.
Rotate on the way through — treat all of them as exposed.

Acceptance criteria:
- No secret literals in the repo (`policy/terraform/secrets.rego` passes).
- Secrets read via `azurerm_key_vault_secret` data sources or the CSI driver.
- Rotation ticket filed for every value that was in git.

## PLAT-425 — Close `allow-promo-loadtest`

Added during the 2024 promo incident for a vendor load generator and never
removed: inbound 443 from `0.0.0.0/0` on the prod AKS subnet NSG. Confirm with
the vendor whether they still need access; if so, allow-list their egress range.

Acceptance criteria:
- `azurerm_network_security_rule.promo_loadtest_ingress` removed or narrowed to
  a specific prefix.
- `policy/terraform/network.rego` passes for prod.

## PLAT-427 — Put prod Terraform state in the remote backend

Prod has no `backend "azurerm"` block. The state file lives on the platform
lead's laptop and gets copied to SharePoint after each apply, so concurrent
applies are unprotected and there is no state history.

Acceptance criteria:
- Prod uses the `stbwplatformtfstate` backend with state locking.
- Existing state migrated, laptop copy destroyed.
- Pipeline is the only thing that applies prod.

## PLAT-431 — Restore probes and resource limits

Prod `order-ahead` has both probes disabled (2024 promo incident, readiness
flapping under load). Staging `order-ahead` has no resource limits (March load
test, OOMKills). Both were meant to be temporary.

Acceptance criteria:
- Probes enabled in every environment with timeouts that survive load; fix the
  underlying readiness behaviour rather than deleting the probe.
- Requests and limits set in every environment.
- `policy/kubernetes/probes.rego` passes.

## PLAT-434 — Template store ACLs

18 sites carry hand-maintained ACLs in `inventories/stores/host_vars/`; the rest
inherit group defaults. Store 214 and store 352 have a `permit ip any any` in
`POS_IN` from the 2022 vendor tablet pilot.

Acceptance criteria:
- ACLs generated from role templates plus per-site variables (addresses only).
- No `permit ip any any` anywhere.
- New store turn-up needs no new `host_vars` file.

## PLAT-436 — Merge the duplicated West role

`store_network_baseline_west` was copied from `store_network_baseline` in 2022.
It hardcodes the VLAN list, drops ACL logging, and never got the syslog/NTP
block. Nobody knows which role is authoritative for a West-region store.

Acceptance criteria:
- One role, region behaviour driven by variables.
- `store_network_baseline_west` deleted, AAP job templates updated.

## PLAT-440 — Nightly drift detection

We find out about out-of-band changes when something breaks. We want to find out
the next morning.

Acceptance criteria:
- Nightly pipeline runs `terraform plan -detailed-exitcode` per environment plus
  the Kubernetes and store-host checks.
- A work item is filed with the diff when drift is found.
- `scripts/introduce_drift.sh` followed by `scripts/check_drift.sh` reports the
  injected drift, and reports clean afterwards.
