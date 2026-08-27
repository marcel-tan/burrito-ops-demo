variable "name_suffix" {
  description = "Suffix used in resource names, e.g. dev-eastus2."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group that holds the cluster."
  type        = string
}

variable "subnet_id" {
  description = "Subnet the node pools attach to."
  type        = string
}

variable "kubernetes_version" {
  description = "AKS control plane version."
  type        = string
}

variable "sku_tier" {
  description = "AKS SKU tier (Free or Standard)."
  type        = string
  default     = "Free"
}

variable "system_node_count" {
  description = "Node count for the system pool."
  type        = number
  default     = 2
}

variable "system_vm_size" {
  description = "VM size for the system pool."
  type        = string
  default     = "Standard_D2s_v3"
}

variable "apps_node_count" {
  description = "Node count for the application pool."
  type        = number
  default     = 3
}

variable "apps_vm_size" {
  description = "VM size for the application pool."
  type        = string
  default     = "Standard_D4s_v3"
}

variable "tags" {
  description = "Tags applied to cluster resources."
  type        = map(string)
  default     = {}
}
