# Standard 3.2: images are pinned to an immutable reference.
package main

workload_kinds := {"Deployment", "StatefulSet", "DaemonSet", "Job", "CronJob"}

containers[container] {
	workload_kinds[input.kind]
	container := input.spec.template.spec.containers[_]
}

deny[msg] {
	container := containers[_]
	endswith(container.image, ":latest")
	msg := sprintf("standards.md 3.2: %s/%s uses a floating image tag (%v)", [input.kind, input.metadata.name, container.image])
}

deny[msg] {
	container := containers[_]
	not contains(container.image, ":")
	msg := sprintf("standards.md 3.2: %s/%s image %q has no tag", [input.kind, input.metadata.name, container.image])
}

warn[msg] {
	container := containers[_]
	not contains(container.image, "@sha256:")
	not endswith(container.image, ":latest")
	msg := sprintf("standards.md 3.2: %s/%s image %v is not pinned to a digest", [input.kind, input.metadata.name, container.image])
}
