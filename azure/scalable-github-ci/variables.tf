variable "ssh_cidr_ranges" {
  type        = list(string)
  description = "CIDR ranges allowed to access CI instances via ssh"

  validation {
    condition     = length(var.ssh_cidr_ranges) > 0
    error_message = "The ssh_cidr_ranges value must contain at least one CIDR."
  }
}

variable "name" {
  type        = string
  description = "Main name of resources created"
  default     = "ci"
}

########################
# Registration details #
########################

variable "username" {
  type        = string
  description = "Username for CI box"
  default     = "ci"
}

variable "github_runner_version" {
  type        = string
  description = "The version of github-runner to install"
  default     = "2.321.0"
}

variable "github_api_token" {
  type        = string
  description = "The Github API token to support retrieving a runner registration token"
  sensitive   = true
}

variable "github_organisation" {
  type        = string
  description = "The name of the Github organisation to use (e.g. Rocketmakers), if registering against an organisation, or the name of the repository (e.g. Rocketmakers/terraform-modules), if registering against a single repository"
}

variable "runner_labels" {
  type        = list(string)
  description = "The labels to assign to the runner"
  default     = []
}

variable "docker_install_script_url" {
  type        = string
  description = "The URL to the Docker installation script"
  default     = "https://get.docker.com/"
}

######################
# Autoscaler details #
######################

variable "autoscaler_version" {
  description = "The version of the autoscaler to use"
  type        = string
  default     = "1.0.1"
}

variable "autoscaler_log_workspace_sku" {
  type        = string
  description = "The SKU of the Log Analytics workspace to use for the autoscaler"
  default     = "PerGB2018"
}

variable "autoscaler_log_workspace_retention_in_days" {
  type        = number
  description = "The retention period in days for the Log Analytics workspace used by the autoscaler"
  default     = 30
}

variable "autoscaler_workload_profile_type" {
  type        = string
  description = "The workload profile type for the autoscaler"
  default     = "Consumption"
}

variable "autoscaler_revision_mode" {
  type        = string
  description = "The revision mode for the autoscaler"
  default     = "Single"
}

variable "autoscaler_cpu" {
  type        = number
  description = "The amount of CPU to allocate to the autoscaler container"
  default     = 0.25
}

variable "autoscaler_memory" {
  type        = string
  description = "The amount of memory to allocate to the autoscaler container in GB"
  default     = "0.5Gi"
}

variable "autoscaler_log_level" {
  type        = string
  description = "The log level to use"
  default     = "Information"
  validation {
    condition     = contains(["Trace", "Debug", "Information", "Warning", "Error", "Critical"], var.autoscaler_log_level)
    error_message = "The log_level value must be one of: Trace, Debug, Information, Warning, Error, Critical."
  }
}

variable "autoscaler_structured_logs" {
  type        = bool
  description = "Whether to enable structured logging in the autoscaler"
  default     = true
}

variable "autoscaler_webhook_enabled" {
  type        = bool
  description = "Whether to enable the GitHub webhook for the autoscaler"
  default     = true
}

variable "autoscaler_webhook_repo_name" {
  type        = string
  description = "The name of the repository to register the webhook against"
}

variable "autoscaler_webhook_path" {
  type        = string
  description = "The path to use for the GitHub webhook endpoint"
  default     = "/webhook"
}

variable "autoscaler_webhook_events" {
  type        = list(string)
  description = "The list of GitHub events that should trigger the webhook"
  default     = ["workflow_job"]
}

####################
# Instance details #
####################

variable "max_instance_count" {
  type        = number
  description = "The maximum number of VM instances to create"
  default     = 1
}

variable "scale_in_rule" {
  type        = string
  description = "The rule to use for scaling in"
  default     = "OldestVM"
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group in which to place resources"
}

variable "primary_location" {
  type        = string
  description = "Main location to store everything (e.g. westeurope)"
}

variable "image_config" {
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })

  description = "The details of the OS image used on the instance"

  default = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

variable "vm_size" {
  type        = string
  description = "Size of VM to deploy"
}

variable "disk_size" {
  type        = number
  description = "Size of disk in GB"
  default     = 50
}

variable "encryption_at_host_enabled" {
  type        = bool
  description = "Determines if encryption at host is enabled for the machine"
  default     = true
}

###################
# Other resources #
###################

variable "container_registry_resource_group_name" {
  type        = string
  description = "The name of the resource group the container registry can be found in"
}

variable "container_registry_name" {
  type        = string
  description = "Container registry name to enable access to"
}

variable "network_address_space" {
  type        = list(string)
  description = "The address space that is used the virtual network. You can supply more than one address space."
  default = [
    "10.0.0.0/16"
  ]
}

variable "network_subnet_address_prefixes" {
  type        = list(string)
  description = "The address prefixes of the CI boxes subnet."
  default     = ["10.0.0.0/24"]
}

variable "subnet_service_endpoints" {
  type        = list(string)
  description = "The list of Service endpoints to associate with the subnet."
}

