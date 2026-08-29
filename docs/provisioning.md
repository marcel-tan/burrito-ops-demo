# Provisioning

## Environment turn-up

1. Open a pull request with the infrastructure change.
2. `infra-validate` runs Terraform format, validation, and a plan for the
   selected environment.
3. `deploy.yml` applies the approved plan behind the environment approval.
4. Each environment uses its own Terraform root and tfvars file. All roots use
   remote state, including prod.

## Service deployment

`deploy.yml` installs the Helm charts with the environment-specific values
files. `build-test.yml` builds the service images consumed by those releases.

## Adopting existing environments

Environments originally created by the legacy scripts have resources that are
not yet in Terraform state. Before the first pipeline apply against such an
environment, run a one-time state migration through the pipeline: `terraform
import` for each pre-existing resource (notably the `etl-landing` container
created by `provision-storage.ps1`, e.g.
`module.storage.azurerm_storage_container.etl_landing`) so the apply is a
no-op rather than a create conflict.

Clusters that were attached to the monitoring workspace by hand must pass the
workspace ID (platform wiki) as `log_analytics_workspace_id` on the aks module
before that first apply, otherwise the apply detaches monitoring.

## Manual steps retired

- Old step 3 (AKS and network turn-up): `infra/terraform/envs/*/` and
  `azure-pipelines/infra-validate.yml`.
- Old step 4 (`etl-landing`): `infra/terraform/modules/storage/main.tf`.
- Old step 5 (storage lifecycle): `infra/terraform/modules/storage/main.tf`.
- Old step 6 (prod state): `infra/terraform/envs/prod/providers.tf`.
- Old step 7 (monitoring attach): optional
  `log_analytics_workspace_id` in `infra/terraform/modules/aks`.
- Old steps 8-9 (NSG and VNet network-team handoff): `vnet_cidr` outputs in
  `infra/terraform/modules/network/outputs.tf` and each environment's
  `outputs.tf`. Until store router ACLs are templated from these outputs
  (PLAT-434), new VNet CIDRs must still be handed to the network team so store
  routing is updated.

State storage accounts in `rg-burritoworks-tfstate` are still created
out-of-band per subscription.
