variable "subscription_id" {
  description = "Azure subscription for the staging platform."
  type        = string
}

variable "tenant_id" {
  description = "Entra ID tenant."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "eastus2"
}

variable "kubernetes_version" {
  description = "AKS control plane version."
  type        = string
}

variable "ingress_source_cidrs" {
  description = "Source CIDRs allowed to reach the platform ingress."
  type        = list(string)
}

variable "sql_admin_password" {
  description = "Admin password seeded into Key Vault."
  type        = string
}

variable "payments_api_key" {
  description = "Payment gateway API key seeded into Key Vault."
  type        = string
}

# Added during the 2025 loyalty pilot. dev/prod never got this variable.
variable "loyalty_api_key" {
  description = "Loyalty service API key seeded into Key Vault."
  type        = string
}

variable "receipts_archive_after_days" {
  description = "Days before receipts move to the archive tier; null when the account replication type does not support archive."
  type        = number
  default     = 180
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
}
