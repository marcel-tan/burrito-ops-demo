# Standard 2.3: providers are pinned and current.
package main

minimum_azurerm_major := 4

deny[msg] {
	version := input.terraform.required_providers.azurerm.version
	major := to_number(regex.find_n(`[0-9]+`, version, 1)[0])
	major < minimum_azurerm_major
	msg := sprintf(
		"standards.md 2.3: azurerm provider pinned to %q, which is behind the supported major (%v.x)",
		[version, minimum_azurerm_major],
	)
}

deny[msg] {
	input.provider.azurerm
	not input.terraform.required_providers.azurerm.version
	msg := "standards.md 2.3: azurerm provider is not pinned to a version"
}
