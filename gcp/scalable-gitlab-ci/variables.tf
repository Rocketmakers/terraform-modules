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

variable "zone" {
  type        = string
  description = "Google Cloud zone where instance should be placed"
}

variable "region" {
  type        = string
  description = "The GCP region where VMs and related resources will be created."
}

variable "runner_tags" {
  type        = list(string)
  description = "List of tags for gitlab runner (no tags will be added by default)"
}

// Optional

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
}

variable "image_project" {
  type        = string
  description = "Google image project to base CI on"
  default     = "ubuntu-os-cloud"
}

variable "image_name" {
  type        = string
  description = "Google image name to base CI on"
  default     = "ubuntu-2204-jammy-v20250701"
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
  description = "Minimum number of VM's that will be left running when there is no demand for jobs"
  default     = 0
}

variable "orchestrator_idle_time" {
  type        = number
  description = "Number of seconds for the machine to be in Idle State before it is destroyed"
  default     = 300
}

variable "orchestrator_max_builds" {
  type        = number
  description = "Maximum job count before machine is removed."
  default     = 100
}

variable "runner_machine_name" {
  type        = string
  description = "Name of the machine. It must contain %s, which is replaced with a unique machine identifier."
  default     = "auto-scale-%s"
}

variable "runner_disk_size" {
  type        = number
  description = "Size of runner disk in GB"
  default     = 50
}

variable "gitlab_max_runners" {
  type        = number
  description = "The maximum number of VMs that will be created (one VM will run one job at a time)."
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
  description = "The location of the cache bucket (see https://cloud.google.com/storage/docs/locations)"
}

variable "engine_install_url" {
  type        = string
  description = "URL to use for engine installation through docker-machine"
  default     = "https://get.docker.com"
}
