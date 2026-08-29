output "cluster_name" {
  value = module.aks.cluster_name
}

output "key_vault_uri" {
  value = module.keyvault.vault_uri
}

output "vnet_cidr" {
  value = module.network.vnet_cidr
}
