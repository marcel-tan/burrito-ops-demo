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

resource "azurerm_storage_container" "etl_landing" {
  name                  = "etl-landing"
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
}

resource "azurerm_storage_management_policy" "this" {
  storage_account_id = azurerm_storage_account.this.id

  rule {
    name    = "receipts-lifecycle"
    enabled = true

    filters {
      prefix_match = ["receipts/"]
      blob_types   = ["blockBlob"]
    }

    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than    = 30
        tier_to_archive_after_days_since_modification_greater_than = 180
      }
    }
  }
}
