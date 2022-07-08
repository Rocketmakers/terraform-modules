# ci provisioner commands

Returns the string list for provisioning a gitlab runner. This module is intended for use within one of the cloud specific `scalable-gitlab-ci` modules although it could be used to provision any linux machine as a gitlab runner.

{{{ this.coreContent }}}

## Example Use Cases

```
module "ci-provisioner-commands" {
  source = "git::ssh://git@gitlab.com/rocketmakers/infrastructure/terraform-modules.git//shared/ci-provisioner-commands?ref=v{{{ this.version }}}"

  names                      = var.names
  username                   = var.username
  runner_tags                = var.runner_tags
  gitlab_token               = var.gitlab_token
  gitlab_runner_concurrency  = var.gitlab_runner_concurrency
  gitlab_runner_version      = var.gitlab_runner_version
  gitlab_runner_docker_image = var.gitlab_runner_docker_image
  gitlab_runner_locked       = var.gitlab_runner_locked
  docker_prune_cron_schedule = var.docker_prune_cron_schedule
}
```
