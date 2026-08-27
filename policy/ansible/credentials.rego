# Standard 4.5: credentials come from an AAP credential or a vault lookup.
package main

credential_key_pattern := `(?i)(password|secret|api_key|apikey|token|community)`

deny[msg] {
	some key
	value := input[key]
	is_string(value)
	regex.match(credential_key_pattern, key)
	not startswith(value, "{{ lookup(")
	not startswith(value, "!vault")
	count(value) > 0
	msg := sprintf("standards.md 4.5: %q is a plaintext credential in inventory vars", [key])
}
