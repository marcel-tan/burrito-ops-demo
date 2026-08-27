# Standard 3.5: no secret values in manifests; secrets come from the Key Vault CSI driver.
package main

secret_env_pattern := `(?i)(password|secret|api_key|apikey|token)`

deny[msg] {
	container := containers[_]
	env := container.env[_]
	regex.match(secret_env_pattern, env.name)
	env.value
	msg := sprintf(
		"standards.md 3.5: %s/%s sets %v as a literal environment variable",
		[input.kind, input.metadata.name, env.name],
	)
}
