resource "azurerm_storage_account" "this" {
  name                     = var.account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = var.replication_type
  min_tls_version          = "TLS1_2"
  tags                     = var.tags
}

resource "azurerm_storage_container" "receipts" {
  name                  = "receipts"
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "menu_assets" {
  name                  = "menu-assets"
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = var.menu_assets_access_type
}
