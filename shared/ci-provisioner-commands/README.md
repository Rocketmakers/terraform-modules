# ci provisioner commands

Returns the string list for provisioning a gitlab runner. This module is intended for use within one of the cloud specific `scalable-gitlab-ci` modules although it could be used to provision any linux machine as a gitlab runner.

## Required Inputs

| name    | description          | type   |
| ------- | -------------------- | ------ |
| `gitlab_orchestrator_concurrency` | The maximum number of jobs that the orchestrator will run concurrently from gitlab | number |
| `gitlab_runner_docker_image` | The value passed to --docker-image when registering the runner (see https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#docker) | string |
| `gitlab_runner_locked` | Setting true will limit the runner to the project that provided the registration token. Setting false will allow other projects to enable the runner. | bool |
| `gitlab_runner_version` | The version of gitlab-runner to install (see https://docs.gitlab.com/runner/install/bleeding-edge.html#download-any-other-tagged-release) | string |
| `gitlab_token` | Token used to register gitlab runner | string |
| `name` | Main name of resources created | string |
| `runner_tags` | List of tags for gitlab runner (no tags will be added by default) | list(string) |
| `username` | Username for CI box | string |

## Optional Inputs

| name    | description          | type   | default value   |
| ------- | -------------------- | ------ | --------------- |
| `config_template_path` |  | string | /tmp/test-config.template.toml |
| `docker_machine_version` | Docker machine version for runner | string | v0.16.2-gitlab.35 |

## Outputs

| name      | description                 |
| --------- | --------------------------- |
| `config_template_path` | Config template file path |
| `init_docker` | List of commands for installing and initialising docker |
| `init_docker_machine` | List of commands for installing and initialising docker-machine |
| `init_gitlab_runner` | List of commands for installing and initialising gitlab-runner |
| `register_gitlab_runner` | List of commands for registering gitlab-runner |




## Example Use Cases

```
module "ci-provisioner-commands" {
  source = "git::ssh://git@gitlab.com/rocketmakers/infrastructure/terraform-modules.git//shared/ci-provisioner-commands?ref=v3.5.0"

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
