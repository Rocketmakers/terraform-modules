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

variable "github_runner_concurrency" {
  type        = number
  description = "The maximum number of jobs that the runner will run concurrently"
  default     = 3
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

####################
# Instance details #
####################

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

variable "scale_in_rule" {
  type        = string
  description = "The rule to use for scaling in"
  default     = "OldestVM"
}

variable "autoscale_max_cpu_percentage" {
  type        = number
  description = "The minimum CPU percentage which must be achieved before scaling up to the max_instance_count"
  default     = 10
}

variable "autoscale_max_cooldown" {
  type        = string
  description = "The cooldown mode for autoscaling to the maximum instances"
  default     = "PT1M"
}

variable "autoscale_min_cpu_percentage" {
  type        = number
  description = "The maximum CPU percentage which must be achieved before scaling down to the min_instance_count"
  default     = 5
}

variable "autoscale_min_cooldown" {
  type        = string
  description = "The cooldown mode for autoscaling to the minimum instances"
  default     = "PT1M"
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

