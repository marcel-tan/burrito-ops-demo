output "vnet_id" {
  value = azurerm_virtual_network.this.id
}

output "vnet_cidr" {
  value = var.vnet_cidr
}

output "aks_subnet_id" {
  value = azurerm_subnet.aks.id
}

output "data_subnet_id" {
  value = azurerm_subnet.data.id
}

output "nsg_name" {
  value = azurerm_network_security_group.aks.name
}
