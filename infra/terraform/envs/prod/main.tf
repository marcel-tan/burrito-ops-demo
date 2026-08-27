locals {
  environment = "prod"
  name_suffix = "${local.environment}-eastus2"
}

module "resource_group" {
  source = "../../modules/resource_group"

  name     = "rg-burritoworks-platform-${local.environment}"
  location = "eastus2"
  tags     = var.tags
}

module "network" {
  source = "../../modules/network"

  name_suffix          = local.name_suffix
  location             = "eastus2"
  resource_group_name  = module.resource_group.name
  vnet_cidr            = "10.60.0.0/16"
  aks_subnet_cidr      = "10.60.1.0/24"
  data_subnet_cidr     = "10.60.2.0/24"
  ingress_source_cidrs = var.ingress_source_cidrs
  tags                 = var.tags
}

# Added during the 2024 promo incident so the vendor load generator could reach
# the ingress from the internet. Never reverted.
resource "azurerm_network_security_rule" "promo_loadtest_ingress" {
  name                        = "allow-promo-loadtest"
  priority                    = 150
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "0.0.0.0/0"
  destination_address_prefix  = "*"
  resource_group_name         = module.resource_group.name
  network_security_group_name = module.network.nsg_name
}

module "aks" {
  source = "../../modules/aks"

  name_suffix         = local.name_suffix
  location            = "eastus2"
  resource_group_name = module.resource_group.name
  subnet_id           = module.network.aks_subnet_id
  kubernetes_version  = var.kubernetes_version
  sku_tier            = "Standard"
  system_node_count   = 3
  system_vm_size      = "Standard_D4s_v3"
  apps_node_count     = 6
  apps_vm_size        = "Standard_D8s_v3"
  tags                = var.tags
}

module "storage" {
  source = "../../modules/storage"

  account_name        = "stbwplatformprod"
  resource_group_name = module.resource_group.name
  location            = "eastus2"
  replication_type    = "GRS"
  tags                = var.tags
}

module "keyvault" {
  source = "../../modules/keyvault"

  vault_name          = "kv-bw-platform-prod"
  location            = "eastus2"
  resource_group_name = module.resource_group.name
  tenant_id           = var.tenant_id
  tags                = var.tags

  secrets = {
    "sql-admin-password" = var.sql_admin_password
    "payments-api-key"   = var.payments_api_key
  }
}
