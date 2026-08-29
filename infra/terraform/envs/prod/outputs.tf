output "cluster_name" {
  value = module.aks.cluster_name
}

output "storage_account" {
  value = module.storage.account_name
}

output "vnet_cidr" {
  value = module.network.vnet_cidr
}
