# Standard 2.2: remote state is mandatory for every environment.
package main

deny[msg] {
	input.provider.azurerm
	not input.terraform.backend
	msg := "standards.md 2.2: environment root configures the azurerm provider but has no remote backend"
}
