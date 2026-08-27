# BurritoWorks Platform Standards

Owner: Platform Engineering. Enforced by the policies in `policy/` and by the
Azure DevOps pipelines in `azure-pipelines/`. Everything in this document is
machine-checked; if a rule is not checkable it does not belong here.

## 1. Everything is declarative

1.1 Infrastructure is created by Terraform, Kubernetes workloads by Helm, and
store network/edge configuration by Ansible. Imperative provisioning scripts
(`az`, `kubectl edit`, PowerShell against ARM) are not a supported mechanism for
changing an environment.

1.2 Every change lands as a pull request. Nobody has standing write access to an
environment; `plan`/`apply` and `ansible-playbook` run from the pipeline under
the platform service principal.

1.3 Running the same automation twice must be a no-op. Second-run diffs are
treated as bugs.

## 2. Terraform

2.1 One module set, parameterized per environment. Environment directories carry
`*.tfvars` and a backend configuration, not copies of the module code.

2.2 Remote state is mandatory for every environment (`backend "azurerm"`, one
state per environment, state storage account locked to the platform network).

2.3 Providers are pinned and no more than one minor version behind the current
release at the time of the quarterly upgrade.

2.4 No secret values in `.tf` or `.tfvars`. Secrets live in Key Vault and are
referenced (`azurerm_key_vault_secret` data sources, Key Vault CSI driver, or
pipeline variable groups backed by Key Vault).

2.5 Required tags on every taggable resource: `environment`, `owner`,
`cost-center`, `data-classification`.

2.6 No inbound NSG rule may use a source of `0.0.0.0/0`, `*`, or `Internet`.
Public ingress terminates at Front Door / Application Gateway, and the documented
CIDR list is the only permitted NSG source.

2.7 Storage containers are `private`. Public blob access requires a documented
exception.

## 3. Helm and Kubernetes

3.1 One parameterized chart per service shape, with per-environment values
files. Chart templates are identical across environments; only values differ.

3.2 Images are pinned to an immutable reference (semver tag plus digest).
`latest` is never deployed.

3.3 Every container declares liveness, readiness and startup probes, and CPU +
memory requests and limits, in every environment.

3.4 Every production workload has a PodDisruptionBudget and an HPA sized for a
promo traffic spike (design point: 30x baseline within 10 minutes).

3.5 Secrets reach pods through the Key Vault CSI driver. No secret values in
values files, ConfigMaps, or environment variables in git.

3.6 Every namespace has a default-deny NetworkPolicy plus explicit allows.

## 4. Store network and edge (network-as-code)

4.1 Store network configuration is generated from a per-store-profile data
model. Per-site configuration files are limited to the facts that are genuinely
site-specific (addresses, circuit ids) — never per-site copies of the policy.

4.2 ACL and firewall policy is templated. `permit ip any any` on an inbound
store ACL is a policy violation.

4.3 Tasks use purpose-built modules (`cisco.ios.*`, `ansible.posix.*`,
`ansible.builtin.package`, `ansible.builtin.systemd_service`). `shell`/`command`
require a `creates`/`removes`/`changed_when` guard and a comment explaining why
no module exists.

4.4 Packages are version-pinned. Services are managed by the service manager,
not by `nohup`.

4.5 Credentials come from an AAP credential or a vault lookup. No credentials in
inventory, `group_vars`, `host_vars`, or playbooks.

4.6 Fleet-wide entrypoints are AAP job templates with surveys, so a network
engineer runs a reviewed template rather than a laptop playbook. Every template
runs in check/diff mode first and is batched (`serial`) with a smoke test.

4.7 PCI-scope hosts (POS gateways) are configured by a separate job template
with its own credential and its own approval.

## 5. Pipelines

5.1 Every PR runs: unit tests, `terraform validate` + `terraform plan`,
`helm lint` + `helm template | conftest`, `ansible-lint` + a check-mode run, and
the policy suite in `policy/`.

5.2 `terraform apply` and non-check-mode playbook runs happen only on the main
branch, from the pipeline, behind an environment approval.

5.3 Drift is checked nightly across all three layers and files a work item when
it finds something.
