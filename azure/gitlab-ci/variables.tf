variable project_name {
  type        = string
  description = "Project name"
}

variable instance_count {
  type        = number
  description = "The number of VM instances to create"
  default     = 1
}

variable resource_group {
  type        = string
  description = "Resource group"
}

variable container_registry_name {
  type        = string
  description = "Container registry name to enable access to"
}

variable primary_location {
  type        = string
  description = "Main location to store everything (e.g. westeurope)"
}

variable whitelist {
  type        = list(string)
  description = "CIDR whitelist of entities allowed to access resource"

  validation {
    condition     = length(var.whitelist) > 0
    error_message = "The whitelist must contain at least one CIDR."
  }
}

variable key_vault_name {
  type        = string
  description = "Azure key vault id that stores the gitlab token"
}

variable gitlab_token_secret_name {
  type        = string
  description = "Name of the gitlab token secret in azure key vault"
  default     = "core-gitlab-token"
}

variable runner_tags {
  type        = list(string)
  description = "List of tags for gitlab runner"
  default     = ["rocketmakers", "docker"]
}

variable vm_size {
  type        = string
  description = "Size of VM to deploy"
  default     = "Standard_B2s"
}

variable public_ip_allocation_method {
  type        = string
  description = "The allocation method for the public ip associated with the cluster"
  default     = "Static"
}

variable public_ip_sku {
  type        = string
  description = "The sku for the public ip associated with the cluster"
  default     = "Standard"
}

variable network_address_space {
  type        = list(string)
  description = "The address space that is used the virtual network. You can supply more than one address space."
  default = [
    "10.0.0.0/16"
  ]
}

variable network_subnet_address_prefix {
  type        = string
  description = "The address prefix of the CI boxes subnet."
  default     = "10.0.0.0/24"
}

variable gitlab_runner_concurrency {
  type        = number
  description = "The maximum number of jobs that the runner will run concurrently"
  default     = 2
}

variable gitlab_runner_version {
  type        = string
  description = "The version of gitlab-runner to install (see https://docs.gitlab.com/runner/install/bleeding-edge.html#download-any-other-tagged-release)"
  default     = "latest"
}

variable gitlab_runner_docker_image {
  type        = string
  description = "The value passed to --docker-image when registering the runner (see https://docs.gitlab.com/ee/ci/docker/using_docker_build.html#docker)"
  default     = "docker:stable"
}

variable gitlab_runner_locked {
  type        = bool
  description = "Setting true will limit the runner to the project that provided the registration token. Setting false will allow other projects to enable the runner."
  default     = true
}

variable docker_prune_cron_schedule {
  type        = string
  description = "The schedule to use for pruning docker images to prevent disk space filling up. Default value is weekly on Sundays at 0400 UTC."
  default     = "0 4 * * 0"
}
