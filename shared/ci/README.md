# shared ci

Returns the string list for provisioning a gitlab runner. This module is intended for use within one of the cloud specific `gitlab-ci` modules although it could be used to provision any linux machine as a gitlab runner.

## Required Inputs

| name    | description          | type   |
| ------- | -------------------- | ------ |
| `docker_prune_cron_schedule` | The schedule to use for pruning docker images to prevent disk space filling up. | string |
| `gitlab_runner_concurrency` | The maximum number of jobs that the runner will run concurrently | number |
| `gitlab_runner_docker_image` | The value passed to --docker-image when registering the runner (see https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#docker) | string |
| `gitlab_runner_locked` | Setting true will limit the runner to the project that provided the registration token. Setting false will allow other projects to enable the runner. | bool |
| `gitlab_runner_version` | The version of gitlab-runner to install (see https://docs.gitlab.com/runner/install/bleeding-edge.html#download-any-other-tagged-release) | string |
| `gitlab_token` | Token used to register gitlab runner | string |
| `names` | Main names of resources created | list(string) |
| `runner_tags` | List of tags for gitlab runner | list(string) |
| `username` | Username for CI box | string |


## Outputs

| name      | description                 |
| --------- | --------------------------- |
| `provisioner_commands` | List of commands for privisioning a ci_box |




## Example Use Cases

```
module shared-ci {
  source = "git::ssh://git@gitlab.com/rocketmakers/infrastructure/terraform-modules.git//shared/ci?ref=v3.8.2"

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
