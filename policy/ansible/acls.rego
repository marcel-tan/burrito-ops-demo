# Standard 4.1 / 4.2: store ACLs are templated from a data model and never permit any.
package main

deny[msg] {
	rules := input.acls[name]
	rule := rules[_]
	lower(rule) == "permit ip any any"
	name != "GUEST_WIFI_IN"
	msg := sprintf("standards.md 4.2: store %v ACL %v contains %q", [input.site_id, name, rule])
}

warn[msg] {
	input.acls
	input.site_id
	msg := sprintf("standards.md 4.1: store %v carries a hand-maintained per-site ACL definition", [input.site_id])
}
