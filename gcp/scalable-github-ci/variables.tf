variable "zone" {
  type        = string
  description = "Google Cloud zone where instance should be placed"
}

variable "region" {
  type        = string
  description = "The GCP region where VMs and related resources will be created."
}

variable "project_id" {
  type        = string
  description = "Google Cloud project ID where the runner instance and related resources will be created"
}

variable "project_prefix" {
  type        = string
  description = "A prefix given to resource names related to the runner instance"
}

variable "machine_type" {
  type        = string
  description = "Machine type of the runner vm"
}

variable "ssh_cidr_ranges" {
  type        = list(string)
  description = "CIDR ranges allowed to access the runner instance"
}

variable "name" {
  type        = string
  description = "Main name of resources created"
  default     = "ci"
}

variable "image_project" {
  type        = string
  description = "Google image project to base CI on"
  default     = "ubuntu-os-cloud"
}

variable "image_name" {
  type        = string
  description = "Google image name to base CI on"
  default     = "ubuntu-2004-focal-v20241115"
}

variable "tags" {
  type        = list(string)
  description = "List of tags to enable ssh access"
  default     = ["ci", "externalssh"]
}

variable "min_instance_count" {
  type        = number
  description = "The minimum number of VM instances to create"
  default     = 1
}

variable "max_instance_count" {
  type        = number
  description = "The maximum number of VM instances to create"
  default     = 1
}

variable "docker_prune_cron_schedule" {
  type        = string
  description = "The schedule to use for pruning docker images to prevent disk space filling up. Default value is daily at 0400 UTC."
  default     = "0 4 * * *"
}

variable "username" {
  type        = string
  description = "Username for CI box"
  default     = "ci"
}

variable "github_runner_version" {
  type        = string
  description = "The version of github-runner to install"
  default     = "2.317.0"
}

variable "github_api_token" {
  type        = string
  description = "The Github API token to support retrieving a runner registeration token. This must be against a user and have access to runners for a repository."
}

variable "github_organisation" {
  type        = string
  description = "The name of the Github organisation to use (e.g. Rocketmakers), if registering against an organisation, or the name of the repository (e.g. Rocketmakers/terraform-modules), if registering against a single repository"
}