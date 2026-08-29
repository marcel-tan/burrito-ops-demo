# Demo script — BurritoWorks IaC/CaC

Read this top to bottom while presenting. Commands are copy-paste ready.

Timing: 30 min live. Beat 1 is 5 min, beat 2 is 15 min (Devin works while you
talk), beat 3 is 10 min.

## Before the call (20 min, do it the day before)

1. Start a Devin session on this repo and paste **Prompt 2** (below). Let it run.
2. Confirm at least two child-session PRs are open before you present.
3. In a local clone, run `./scripts/demo/up.sh` (about 6 min) so the cluster is
   already warm.
4. Open four tabs: this repo, the Devin session, one PR, Devin Review on that PR.

If the pre-run is missing, the demo still works — you kick off Prompt 2 live and
show a finished session from the day before instead.

## Beat 1 — "your IaC is really scripting" (5 min)

Say: *this is your platform, notionally — Azure, ADO, ~150 services, Helm,
thousands of store networks.*

1. Open `scripts/legacy/provision-aks.sh` — copy-pasted env blocks, inline
   secrets, no idempotency. Then `scripts/legacy/runbook.md` — the manual steps.
   Say: *this is Kevin's "it's more scripting than anything else," in a repo.*
2. Open `infra/terraform/envs/` — `dev`, `staging`, `prod` are three drifted
   copies of the same thing. Different K8s versions, different storage settings.
3. Run the standard against it:
   ```bash
   ./scripts/policy_check.sh          # fails: 16 Terraform, 3 Helm, 6 Ansible
   ```
   Say: *`docs/standards.md` is the written standard, `policy/` is the same thing
   as OPA rules. Today the infra loses to its own standard.*

## Beat 2 — one English prompt, and Devin proves it (15 min)

1. Kick off **Prompt 2** from Slack (shows the event-driven surface), or open the
   pre-run session.
2. While it works, narrate the five workstreams from the session's task list.
3. Land on the proof, not the code:
   - `terraform validate` and `plan` clean, `conftest` green
   - deployed to a throwaway `kind` cluster, second `helm upgrade` is a no-op
   - Ansible run twice against the sandbox store hosts → zero changes
   - Nothing ever applied to real infra: the PR is the deliverable, a service
     account with RBAC applies it behind their IdP and RBAC
4. Show the live app so the infra is provably deploying something real:
   ```bash
   curl localhost:30080/healthz     # order-ahead
   curl localhost:30081/healthz     # catering
   cd web && npm ci && npm start    # Angular front end on :4200
   ```

## Beat 3 — drift, then Devin Review (10 min)

1. Drift, in two commands:
   ```bash
   ./scripts/introduce_drift.sh     # hand-edits the cluster + store hosts out-of-band
   ./scripts/check_drift.sh         # 19 findings, writes .drift/drift-report.md
   ```
   Say: *someone fixed a promo outage at 2am with `kubectl edit`. Nobody chases
   that down. `azure-pipelines/nightly-drift.yml` runs this nightly and files an
   ADO work item.*
2. Open **Devin Review** on one of the PRs. This is the close: *the objection is
   "how do we trust AI-written infra code" — the answer is the same review gate
   you already trust, plus the plan, plus the policy check, plus a throwaway
   cluster that proves it runs twice.*
3. Last slide is the session's child-session fan-out: *fleet-scale, not
   one-engineer-scale.*

## Prompt 2 — paste this to run the demo

> This is the BurritoWorks platform repo: Terraform + Helm for AKS, Ansible/AAP for the store edge and network fleet, Azure DevOps pipelines for CI. `docs/standards.md` is the platform standard and `policy/` encodes it as OPA rules. Treat this as a production, PCI-adjacent restaurant platform — thousands of stores, every change has to be safe to run twice.
>
> Do five workstreams, one child session each, each ending in its own PR:
>
> **0. Scripts → declarative IaC.** Convert `scripts/legacy/` — the imperative Azure CLI/PowerShell provisioning scripts and their runbook — into reviewable Terraform and Helm, preserving current behaviour. Produce a mapping table in the PR (script line → resource), a `terraform plan` proving parity, and delete the scripts they replace.
>
> **1. Consolidate and harden the Terraform.** Collapse the duplicated dev/staging/prod copies into one parameterized module set with per-environment tfvars; move all secrets to Key Vault references; close the 0.0.0.0/0 NSG rule to the documented CIDRs; add the required tags; configure remote state consistently; upgrade the provider and fix the breaking changes. `terraform validate` and `terraform plan` must be clean, and `conftest` must pass. Include the plan output diff in the PR description.
>
> **2. Ticket → Helm chart.** Take `docs/backlog.md` item PLAT-431 and implement it: one parameterized Helm chart shared by both services, per-environment values files, pinned image digests instead of `latest`, liveness/readiness/startup probes, resource requests and limits, PodDisruptionBudget and HPA sized for a promo traffic spike, secrets via Key Vault CSI driver, and NetworkPolicies. Deploy it to the local `kind` cluster, run `helm upgrade` a second time to show a clean no-op diff, and run a load test against the order-ahead service to show the HPA scaling. The PR is the deliverable; do not apply anything to real infrastructure.
>
> **3. Network-as-code / store fleet.** Take `docs/backlog.md` items PLAT-434 and PLAT-436 and implement them: one idempotent role set covering VLAN/ACL/firewall config generated from a per-store-profile data model, plus edge host baseline (package pinning, service handlers, Jinja2-templated config, cert deployment, SSH hardening, logrotate), with pre-flight and post-deploy smoke tests. Delete the copy-paste-drifted duplicate role, replace the `shell:` tasks with proper modules, move credentials to a vault lookup, and express the entrypoints as AAP job templates with surveys so a network engineer runs it from AAP rather than a laptop. Prove it in the demo sandbox only: bring up the store-host targets in `infra/targets/`, run the playbook against them, run it a second time to show zero changes, and verify the edge services respond. Nothing outside the sandbox is ever touched.
>
> **4. Drift detection and remediation.** Run `scripts/introduce_drift.sh`, then detect the drift across all three layers (Terraform plan diff, Helm values vs live cluster state, Ansible check-mode against the store fleet), write up what drifted and why it matters, and open a PR that either codifies the intentional change or reverts the unintentional one. Add a scheduled Azure DevOps pipeline that runs this drift check nightly and files a work item when it finds something.
>
> Every PR must pass the Azure DevOps pipelines and the policy checks. When all five are open, post a summary in Slack with links.

## If something breaks

| Symptom | Fix |
| --- | --- |
| `up.sh` hangs on image build | `docker system prune -f`, rerun. 6 min. |
| Ports 30080/30081 dead | `kubectl -n burritoworks-local get pods`; probes are disabled in prod values by design, not here |
| Angular shows "service unreachable" | The cluster is down; rerun `./scripts/demo/up.sh` |
| Drift check reports nothing | `./scripts/introduce_drift.sh` was not run, or `./scripts/demo/down.sh` wiped it |

## What never happens in this demo

- No `terraform apply` against a real subscription. Plan-only.
- No customer names. The brand is BurritoWorks.
- No claim that Ansible/AAP is their standard — position it as *what
  network-as-code looks like; AAP here, or whatever your network team uses.*
