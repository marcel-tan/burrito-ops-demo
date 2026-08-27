locals {
  environment = "dev"
  name_suffix = "${local.environment}-${var.location}"
}

module "resource_group" {
  source = "../../modules/resource_group"

  name     = "rg-burritoworks-platform-${local.environment}"
  location = var.location
  tags     = var.tags
}

module "network" {
  source = "../../modules/network"

  name_suffix          = local.name_suffix
  location             = var.location
  resource_group_name  = module.resource_group.name
  vnet_cidr            = "10.40.0.0/16"
  aks_subnet_cidr      = "10.40.1.0/24"
  data_subnet_cidr     = "10.40.2.0/24"
  ingress_source_cidrs = var.ingress_source_cidrs
  tags                 = var.tags
}

module "aks" {
  source = "../../modules/aks"

  name_suffix         = local.name_suffix
  location            = var.location
  resource_group_name = module.resource_group.name
  subnet_id           = module.network.aks_subnet_id
  kubernetes_version  = var.kubernetes_version
  sku_tier            = "Free"
  system_node_count   = 1
  system_vm_size      = "Standard_D2s_v3"
  apps_node_count     = 2
  apps_vm_size        = "Standard_D2s_v3"
  tags                = var.tags
}

module "storage" {
  source = "../../modules/storage"

  account_name        = "stbwplatformdev"
  resource_group_name = module.resource_group.name
  location            = var.location
  replication_type    = "LRS"
  tags                = var.tags
}

module "keyvault" {
  source = "../../modules/keyvault"

  vault_name                 = "kv-bw-platform-dev"
  location                   = var.location
  resource_group_name        = module.resource_group.name
  tenant_id                  = var.tenant_id
  purge_protection_enabled   = false
  soft_delete_retention_days = 7
  tags                       = var.tags

  secrets = {
    "sql-admin-password" = var.sql_admin_password
    "payments-api-key"   = var.payments_api_key
  }
}
