variable "name" {
  type        = string
  description = "Main name of resources created"
}

variable "username" {
  type        = string
  description = "Username for CI box"
}

variable "runner_tags" {
  type        = list(string)
  description = "List of tags for gitlab runner (no tags will be added by default)"
}

variable "gitlab_token" {
  type        = string
  description = "Token used to register gitlab runner"
}

variable "gitlab_orchestrator_concurrency" {
  type        = number
  description = "The maximum number of jobs that the orchestrator will run concurrently from gitlab"
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

variable "config_template_path" {
  default = "/tmp/test-config.template.toml"
}

variable "docker_machine_version" {
  type        = string
  description = "Docker machine version for runner"
  default     = "v0.16.2-gitlab.35"
}
