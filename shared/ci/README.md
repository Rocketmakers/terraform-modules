# shared ci

Returns the string list for provisioning a ci-box

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
  source = "git::ssh://git@gitlab.com/rocketmakers/infrastructure/terraform-modules.git//shared/ci"

  username                  = var.username
  gitlab-token              = data.aws_kms_secrets.ci.plaintext["gitlab_token"]
  gitlab-runner-concurrency = var.gitlab-runner-concurrency
  project-prefix            = var.project-prefix
  name                      = var.name
  runner-tags               = var.runner-tags
}
```
