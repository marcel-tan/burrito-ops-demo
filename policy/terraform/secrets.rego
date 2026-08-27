# Standard 2.4: no secret values in .tf or .tfvars.
package main

secret_key_pattern := `(?i)(password|passwd|secret|api_key|apikey|token|shared_key|connection_string)`

deny[msg] {
	some key
	value := input[key]
	is_string(value)
	regex.match(secret_key_pattern, key)
	count(value) > 0
	msg := sprintf("standards.md 2.4: %q holds a literal secret value in git; use a Key Vault reference", [key])
}

deny[msg] {
	resource := input.resource.azurerm_key_vault_secret[name]
	is_string(resource.value)
	not startswith(resource.value, "${")
	msg := sprintf("standards.md 2.4: azurerm_key_vault_secret.%s has an inline literal value", [name])
}
