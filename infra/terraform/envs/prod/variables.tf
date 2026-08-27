variable "subscription_id" {
  description = "Azure subscription for the production platform."
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

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
}
