# gitlab-ci

This module creates one or more VMs within Azure acting as gitlab-runners. Each runner will use the `--executor docker` and uses [Docker socket binding](https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#use-docker-socket-binding) to enable docker-in-docker (dind).

{{{ this.coreContent }}}

## Example Use Case

```
module ci {
  source = "git::ssh://git@gitlab.com/rocketmakers/infrastructure/terraform-modules.git//azure/ci?ref=v0.8.0"

  container_registry_name   = var.container_registry_name
  key_vault_name            = var.key_vault_name
  primary_location          = var.primary_location
  project_prefix            = var.project_prefix
  resource_group            = var.resource_group_name
  runner_registration_token = var.runner_registration_token_name
  runner_tags               = var.runner_tags_name
  ssh_cidr_ranges           = var.ssh_cidr_ranges
}
```
