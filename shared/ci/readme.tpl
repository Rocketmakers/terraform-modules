# shared ci

Returns the string list for provisioning a ci-box

{{{ this.coreContent }}}

## Example Use Cases

```
module shared-ci {
  source = "git::ssh://git@gitlab.com/rocketmakers/infrastructure/terraform-modules.git//shared/ci"

  username                  = var.username
  gitlab-token              = data.aws_kms_secrets.ci.plaintext["gitlab_token"]
  gitlab-runner-concurrency = var.gitlab-runner-concurrency
  project-prefix            = var.project-prefix
  name                      = var.name
  runner-tags               = var.runner-tags
}
```
