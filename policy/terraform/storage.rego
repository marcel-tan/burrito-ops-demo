# Standard 2.7: storage containers are private.
package main

deny[msg] {
	module := input.module[name]
	module.menu_assets_access_type != "private"
	msg := sprintf(
		"standards.md 2.7: module.%s sets menu_assets_access_type=%q; public blob access needs an exception",
		[name, module.menu_assets_access_type],
	)
}
