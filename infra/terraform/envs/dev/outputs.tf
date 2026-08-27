output "cluster_name" {
  value = module.aks.cluster_name
}

output "key_vault_uri" {
  value = module.keyvault.vault_uri
}

output "storage_account" {
  value = module.storage.account_name
}
