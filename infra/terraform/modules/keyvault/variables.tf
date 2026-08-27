variable "vault_name" {
  description = "Key vault name."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group that holds the key vault."
  type        = string
}

variable "tenant_id" {
  description = "Entra ID tenant that owns the vault."
  type        = string
}

variable "purge_protection_enabled" {
  description = "Whether purge protection is enabled."
  type        = bool
  default     = true
}

variable "soft_delete_retention_days" {
  description = "Soft delete retention in days."
  type        = number
  default     = 30
}

variable "secrets" {
  description = "Secrets seeded into the vault at provision time."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags applied to the key vault."
  type        = map(string)
  default     = {}
}
