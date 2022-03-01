# gitlab-ci

This module creates one or more VMs within Azure acting as gitlab-runners. Each runner will use the `--executor docker` and uses [Docker socket binding](https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#use-docker-socket-binding) to enable docker-in-docker (dind).

{{{ this.coreContent }}}

## Example Use Case

```
module ci {
  source = "git::ssh://git@gitlab.com/rocketmakers/infrastructure/terraform-modules.git//azure/ci?ref=v{{{ this.version }}}"

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

### Rebuilding CI box

Terraform has a concept of tainting resources to force a rebuild. If there is a problem with our CI box, we can `taint` it to force a rebuild. To do this, firstly identify the resource to taint by running the following command in the folder that contains your terraform state:

```bash
terraform state list
```

Pick the resource you want to taint (most likely `module.ci_box.aws_instance.ci`):

```bash
terraform taint <resource_in_state>
```

Then, reapply the terraform and the resource (and any dependencies) will be rebuilt.
