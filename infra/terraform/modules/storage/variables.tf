variable "account_name" {
  description = "Storage account name (globally unique, lowercase)."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group that holds the storage account."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "replication_type" {
  description = "Replication type, e.g. LRS, ZRS, GRS."
  type        = string
  default     = "LRS"
}

variable "menu_assets_access_type" {
  description = "Access type for the menu asset container."
  type        = string
  default     = "private"
}

variable "receipts_archive_after_days" {
  description = "Days after modification before receipts move to the archive tier. Set to null for accounts whose replication type (e.g. ZRS) does not support the archive tier."
  type        = number
  default     = 180
}

variable "tags" {
  description = "Tags applied to the storage account."
  type        = map(string)
  default     = {}
}
