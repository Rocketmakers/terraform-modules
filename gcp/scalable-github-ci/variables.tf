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

variable "gcr_bucket_names" {
  type        = list(string)
  description = "Names of google container registry buckets that the runner instance has permission to access e.g. [\"eu.artifacts.my-cool-project.appspot.com\"]"
}

variable "machine_type" {
  type        = string
  description = "Machine type of the runner vm"
}

variable "cidr_ranges" {
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
  default     = "ubuntu-2004-focal-v20230302"
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
  description = "The Github API token to support retrieving a runner registeration token"
}

variable "github_organisation" {
  type        = string
  description = "The Github organisation to use"
}