# Standard 3.3: probes and resource requests/limits in every environment.
package main

deny[msg] {
	container := containers[_]
	not container.livenessProbe
	msg := sprintf("standards.md 3.3: %s/%s container %q has no livenessProbe", [input.kind, input.metadata.name, container.name])
}

deny[msg] {
	container := containers[_]
	not container.readinessProbe
	msg := sprintf("standards.md 3.3: %s/%s container %q has no readinessProbe", [input.kind, input.metadata.name, container.name])
}

warn[msg] {
	container := containers[_]
	not container.startupProbe
	msg := sprintf("standards.md 3.3: %s/%s container %q has no startupProbe", [input.kind, input.metadata.name, container.name])
}

deny[msg] {
	container := containers[_]
	not container.resources.requests.cpu
	msg := sprintf("standards.md 3.3: %s/%s container %q has no CPU request", [input.kind, input.metadata.name, container.name])
}

deny[msg] {
	container := containers[_]
	not container.resources.limits.memory
	msg := sprintf("standards.md 3.3: %s/%s container %q has no memory limit", [input.kind, input.metadata.name, container.name])
}
