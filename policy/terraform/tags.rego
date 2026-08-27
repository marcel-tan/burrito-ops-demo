# Standard 2.5: required tags on every taggable resource.
package main

required_tags := {"environment", "owner", "cost-center", "data-classification"}

deny[msg] {
	input.tags
	present := {key | input.tags[key]}
	missing := required_tags - present
	count(missing) > 0
	msg := sprintf("standards.md 2.5: tfvars is missing required tags: %v", [concat(", ", sort(missing))])
}
