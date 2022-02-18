# Required

variable "project_prefix" {
  type        = string
  description = "Project prefix"
}

variable "cidr_ranges" {
  type        = list(string)
  description = "CIDR ranges allowed to access CI"
}

variable "availability_zones" {
  type        = list(string)
  description = "The availability zones that the instance should be created in"
}

variable "runner_tags" {
  type        = list(string)
  description = "List of tags for gitlab runner (no tags will be added by default)"
}

variable "gitlab_token_secret_id" {
  type        = string
  description = "The name or AWS ARN of the secret containing the gitlab registration token"
}

variable "gitlab_token_secret_key" {
  type        = string
  description = "The name of the key within gitlab_token_secret_id containing the gitlab registration token"
}

# // Optional

variable "image_owners" {
  type        = list(string)
  description = "List of image owners to filter on"
  default     = ["099720109477"] # Canonical - owner of Ubuntu image
}

variable "image_names" {
  type        = list(string)
  description = "List of image names to filter on"
  default     = ["*ubuntu-bionic-18.04-amd64-server-*"]
}

variable "tags" {
  type        = map(any)
  description = "Tags for aws resources"
  default     = {}
}

variable "name" {
  type        = string
  description = "Main name of resources created"
  default     = "ci"
}

variable "instance_type" {
  type        = string
  description = "Instance type of the vm"
  default     = "t2.micro"
}

variable "instance_count" {
  type        = number
  description = "The number of VM instances to create"
  default     = 1
}

variable "username" {
  type        = string
  description = "Username for CI box"
  default     = "ubuntu"
}

variable "disk_size" {
  type        = number
  description = "Size of disk in GB"
  default     = 50
}

variable "gitlab_runner_concurrency" {
  type        = number
  description = "The maximum number of jobs that the runner will run concurrently"
  default     = 3
}

variable "gitlab_runner_version" {
  type        = string
  description = "The version of gitlab-runner to install (see https://docs.gitlab.com/runner/install/bleeding-edge.html#download-any-other-tagged-release)"
  default     = "latest"
}

variable "gitlab_runner_docker_image" {
  type        = string
  description = "The value passed to --docker-image when registering the runner (see https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#docker)"
  default     = "docker:stable"
}

variable "gitlab_runner_locked" {
  type        = bool
  description = "Setting true will limit the runner to the project that provided the registration token. Setting false will allow other projects to enable the runner."
  default     = true
}

variable "docker_prune_cron_schedule" {
  type        = string
  description = "The schedule to use for pruning docker images to prevent disk space filling up. Default value is weekly on Sundays at 0400 UTC."
  default     = "0 4 * * 0"
}
