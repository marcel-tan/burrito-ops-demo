variable "name_suffix" {
  description = "Suffix used in resource names, e.g. dev-eastus2."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group that holds the network."
  type        = string
}

variable "vnet_cidr" {
  description = "Address space for the virtual network."
  type        = string
}

variable "aks_subnet_cidr" {
  description = "Address prefix for the AKS node subnet."
  type        = string
}

variable "data_subnet_cidr" {
  description = "Address prefix for the data subnet."
  type        = string
}

variable "ingress_source_cidrs" {
  description = "Source CIDRs allowed to reach the platform ingress on 443."
  type        = list(string)
}

variable "tags" {
  description = "Tags applied to network resources."
  type        = map(string)
  default     = {}
}
