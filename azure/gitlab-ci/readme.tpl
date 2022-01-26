# gitlab-ci

Creates a CI runner for use within gitlab

{{{ this.coreContent }}}

## Example Use Case

```
module ci {
  source = "git::ssh://git@gitlab.com/rocketmakers/infrastructure/terraform-modules.git//azure/ci?ref=v0.8.0"

  resource_group = data.terraform_remote_state.core.outputs.resource_group_name
  project_name   = var.project_name
  key_vault_name = data.terraform_remote_state.core.outputs.key_vault_name
}
```