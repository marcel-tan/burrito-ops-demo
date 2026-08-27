# Standard 2.6: no inbound NSG rule sourced from the public internet.
package main

open_sources := {"0.0.0.0/0", "*", "Internet", "internet"}

deny[msg] {
	input.ingress_source_cidrs[_] == "0.0.0.0/0"
	msg := "standards.md 2.6: ingress_source_cidrs contains 0.0.0.0/0"
}

deny[msg] {
	rule := input.resource.azurerm_network_security_rule[name]
	rule.direction == "Inbound"
	rule.access == "Allow"
	open_sources[rule.source_address_prefix]
	msg := sprintf(
		"standards.md 2.6: azurerm_network_security_rule.%s allows inbound traffic from %v",
		[name, rule.source_address_prefix],
	)
}

deny[msg] {
	rule := input.resource.azurerm_network_security_rule[name]
	rule.direction == "Inbound"
	rule.access == "Allow"
	open_sources[rule.source_address_prefixes[_]]
	msg := sprintf("standards.md 2.6: azurerm_network_security_rule.%s allows inbound traffic from the internet", [name])
}
