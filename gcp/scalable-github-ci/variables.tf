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

variable "service_account_roles" {
  type        = list(string)
  description = "The roles that should be assigned to the service account running the CI box"
  default     = ["roles/monitoring.metricWriter"]
}

variable "image_project" {
  type        = string
  description = "Google image project to base CI on"
  default     = "ubuntu-os-cloud"
}

variable "image_name" {
  type        = string
  description = "Google image name to base CI on"
  default     = "ubuntu-2504-plucky-amd64-v20250815"
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

variable "cpu_percentage_target_utilization" {
  type        = number
  description = "The target CPU utilization that the autoscaler should maintain. Must be a float value in the range (0, 1]. If the CPU level is below the target utilization, the autoscaler scales down the number of instances until it reaches the minimum number of instances you specified or until the average CPU of your instances reaches the target utilization. If the average CPU is above the target utilization, the autoscaler scales up until it reaches the maximum number of instances you specified or until the average utilization reaches the target utilization."
  default     = 0.1
}

variable "autoscaling_cooldown_period_in_seconds" {
  type        = number
  description = "The number of seconds that the autoscaler should wait before it starts collecting information from a new instance. This prevents the autoscaler from collecting information when the instance is initializing, during which the collected usage would not be reliable."
  default     = 60
}

variable "subnetwork_ip_cidr" {
  description = "The IP CIDR for the subnetwork. The default supports 14 addresses"
  default     = "10.128.0.0/28"
}

variable "docker_install_script_url" {
  type        = string
  description = "The URL to the Docker installation script"
  default     = "https://get.docker.com/"
}

variable "docker_prune_cron_schedule" {
  type        = string
  description = "The schedule to use for pruning docker images to prevent disk space filling up. Default value is daily at 0400 UTC."
  default     = "0 4 * * *"
}

variable "runner_labels" {
  type        = list(string)
  description = "The labels to assign to the runner"
  default     = []
}

variable "username" {
  type        = string
  description = "Username for CI box"
  default     = "ci"
}

variable "disk_size_gb" {
  type        = number
  description = "The size of the disk in GB"
  default     = 50
}

variable "github_runner_version" {
  type        = string
  description = "The version of github-runner to install"
  default     = "2.317.0"
}

variable "github_api_token" {
  type        = string
  description = "The Github API token to support retrieving a runner registeration token. This must be against a user and have access to runners for a repository."
  sensitive   = true
}

variable "github_organisation" {
  type        = string
  description = "The name of the Github organisation to use (e.g. Rocketmakers), if registering against an organisation, or the name of the repository (e.g. Rocketmakers/terraform-modules), if registering against a single repository"
}
