variable "names" {
  type        = list(string)
  description = "Main names of resources created"
}

variable "username" {
  type        = string
  description = "Username for CI box"
}

variable "runner_tags" {
  type        = list(string)
  description = "List of tags for gitlab runner"
}

variable "gitlab_token" {
  type        = string
  description = "Token used to register gitlab runner"
  sensitive   = true
}

variable "gitlab_runner_concurrency" {
  type        = number
  description = "The maximum number of jobs that the runner will run concurrently"
}

variable "gitlab_runner_version" {
  type        = string
  description = "The version of gitlab-runner to install (see https://docs.gitlab.com/runner/install/bleeding-edge.html#download-any-other-tagged-release)"
}

variable "gitlab_runner_docker_image" {
  type        = string
  description = "The value passed to --docker-image when registering the runner (see https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#docker)"
}

variable "gitlab_runner_locked" {
  type        = bool
  description = "Setting true will limit the runner to the project that provided the registration token. Setting false will allow other projects to enable the runner."
}

variable "docker_prune_cron_schedule" {
  type        = string
  description = "The schedule to use for pruning docker images to prevent disk space filling up."
}
