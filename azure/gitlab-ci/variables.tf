##############################################
# Common between different gitlab-ci modules #
##############################################

variable "project_prefix" {
  type        = string
  description = "A prefix given to resource names related to the runner instance"
}

variable "ssh_cidr_ranges" {
  type        = list(string)
  description = "CIDR ranges allowed to access CI instances via ssh"

  validation {
    condition     = length(var.ssh_cidr_ranges) > 0
    error_message = "The ssh_cidr_ranges value must contain at least one CIDR."
  }
}

variable "runner_tags" {
  type        = list(string)
  description = "List of tags for gitlab runner, used to allow the runner to be selected for jobs."
}

variable "runner_registration_token" {
  type        = string
  description = "The gitlab registration token that will be used to register the runner."
  sensitive   = true
}

variable "name" {
  type        = string
  description = "Main name of resources created"
  default     = "ci"
}

#####################################################
# Registration details (passed to shared/ci module) #
#####################################################

variable "username" {
  type        = string
  description = "Username for CI box"
  default     = "ci"
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
  description = "The schedule to use for pruning docker images to prevent disk space filling up. Default value is daily at 0400 UTC."
  default     = "0 4 * * *"
}

####################
# Instance details #
####################

variable "instance_count" {
  type        = number
  description = "The number of VM instances to create"
  default     = 1
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
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
}

variable "vm_size" {
  type        = string
  description = "Size of VM to deploy"
  default     = "Standard_B2s"
}

variable "disk_size" {
  type        = number
  description = "Size of disk in GB"
  default     = 50
}

variable "encryption_at_host_enabled" {
  type        = bool
  description = "Determines if encryption at host is enabled for the machine"
  default     = false
}

###################
# Other resources #
###################

variable "container_registry_name" {
  type        = string
  description = "Container registry name to enable access to"
}

variable "key_vault_name" {
  type        = string
  description = "Azure key vault id that jobs on the runner will need to access."
}

variable "key_vault_key_permissions" {
  type        = list(string)
  description = "The collection of key permissions that should be applied for the CI box for the specified key vault"
  default = [
    "Get",
    "Decrypt",
    "List",
  ]
}

variable "key_vault_secret_permissions" {
  type        = list(string)
  description = "The collection of secret permissions that should be applied for the CI box for the specified key vault"
  default = [
    "Get",
    "List",
  ]
}

variable "public_ip_allocation_method" {
  type        = string
  description = "The allocation method for the public ip associated with the cluster"
  default     = "Static"
}

variable "public_ip_sku" {
  type        = string
  description = "The sku for the public ip associated with the cluster"
  default     = "Standard"
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

variable "network_subnet_service_endpoints" {
  type        = list(string)
  description = "The Azure service endpoints that should be enabled for the created network subnet"
  default     = []
}
