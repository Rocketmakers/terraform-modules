// Required

variable "project_id" {
  type        = string
  description = "Google Cloud project ID where the runner instance and related resources will be created"
}

variable "gcr_bucket_names" {
  type        = list(string)
  description = "Names of google container registry buckets that the runner instance has permission to access e.g. [\"eu.artifacts.my-cool-project.appspot.com\"]"
}

variable "project_prefix" {
  type        = string
  description = "A prefix given to resource names related to the runner instance"
}

variable "cidr_ranges" {
  type        = list(string)
  description = "CIDR ranges allowed to access the runner instance"
}

variable "gitlab_token" {
  type        = string
  description = "Token used to register gitlab runner"
}

variable "zones" {
  type        = list(string)
  description = "List of Google Cloud zones where instances should be placed (the zones will be used in a round-robin strategy when creating instances)"
}

variable "region" {
  type        = string
  description = "The Region in which the created address should reside."
}

variable "runner_tags" {
  type        = list(string)
  description = "List of tags for gitlab runner (no tags will be added by default)"
}

// Optional

variable "instance_count" {
  type        = number
  description = "The number of VM instances to create"
  default     = 1
}

variable "disable_compute_on_destroy" {
  type = object({
    disable_service            = bool
    disable_dependent_services = bool
  })
  description = "Whether to disable GCP Compute engine and/or dependent services when the module is destroyed"
  default = {
    disable_service            = false
    disable_dependent_services = false
  }
}

variable "name" {
  type        = string
  description = "Main name of resources created"
  default     = "ci"
}

variable "orchestrator_machine_type" {
  type        = string
  description = "Machine type of the orchestrator vm"
  default     = "f1-micro"
}

variable "runner_machine_type" {
  type        = string
  description = "Machine type of the runner vm"
  default     = "f1-micro"
}

variable "image_project" {
  type        = string
  description = "Google image project to base CI on"
  default     = "ubuntu-os-cloud"
}

variable "image_name" {
  type        = string
  description = "Google image name to base CI on"
  default     = "ubuntu-1804-bionic-v20190628"
}

variable "username" {
  type        = string
  description = "Username for CI box"
  default     = "ci"
}

variable "tags" {
  type        = list(string)
  description = "List of tags to enable ssh access"
  default     = ["ci", "externalssh"]
}

variable "allow_stopping_for_update" {
  type        = bool
  description = "Allow the instance to stop when being updated"
  default     = true
}

variable "orchestrator_disk_size" {
  type        = number
  description = "Size of orchestrator disk in GB"
  default     = 50
}

variable "orchestrator_idle_count" {
  type        = number
  description = "Minimum number of VM's running at idle"
  default     = 0
}

variable "orchestrator_idle_time" {
  type        = number
  description = "Time elapsed for orchestrator to become idle"
  default     = 300
}

variable "orchestrator_max_builds" {
  type        = number
  description = "Max number of builds"
  default     = 100
}

variable "runner_machine_name" {
  type = string
  description = "Name of the Gitlab Runner machine"
  default = "auto-scale-%s"
}

variable "runner_disk_size" {
  type        = number
  description = "Size of runner disk in GB"
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

variable "service_account_roles" {
  type        = list(string)
  description = "The roles that should be assigned to the service account running the CI box"
  default     = ["roles/monitoring.metricWriter"]
}

variable "cache_location" {
  type        = string
  description = "The location of the cache bucket"
}

variable "engine_install_url" {
  type        = string
  description = "URL to use for engine installation through docker-machine"
  default     = "https://releases.rancher.com/install-docker/19.03.9.sh"
}
