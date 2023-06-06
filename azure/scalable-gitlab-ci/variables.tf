###########
# Generic #
###########

variable "name" {
  type        = string
  description = "Main name of resources created"
  default     = "ci"
}

variable "primary_location" {
  type        = string
  description = "Main location to store everything (e.g. westeurope)"
}

variable "project_prefix" {
  type        = string
  description = "A prefix given to resource names related to the runner instance"
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group in which to place resources"
}

#####################################################
# Registration details (passed to shared/ci module) #
#####################################################

variable "gitlab_max_runners" {
  type        = number
  description = "The maximum number of VMs that will be created (one VM will run one job at a time)."
  default     = 3
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

variable "gitlab_runner_version" {
  type        = string
  description = "The version of gitlab-runner to install (see https://docs.gitlab.com/runner/install/bleeding-edge.html#download-any-other-tagged-release)"
  default     = "latest"
}

variable "gitlab_token" {
  type        = string
  description = "Token used to register gitlab runner"
}

variable "runner_tags" {
  type        = list(string)
  description = "List of tags for gitlab runner, used to allow the runner to be selected for jobs."
}

variable "username" {
  type        = string
  description = "Username for CI box"
  default     = "ci"
}

########################
# Orchestrator details #
########################

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

variable "orchestrator_disk_size_gb" {
  type        = number
  description = "Size of disk in GB"
  default     = 50
}


variable "orchestrator_storage_type" {
  type        = string
  description = "Storage type of the orchestrator VM. Possible values are Standard_LRS, StandardSSD_LRS, Premium_LRS, StandardSSD_ZRS and Premium_ZRS."
  default     = "Standard_LRS"
}

variable "orchestrator_vm_size" {
  type        = string
  description = "Size of orchestrator VM to deploy"
  default     = "Standard_B1ls"
}

variable "public_ip_allocation_method" {
  type        = string
  description = "The allocation method for the public ip associated with the cluster"
  default     = "Static"
}

variable "public_ip_sku" {
  type        = string
  description = "The sku for the public ip associated with the orchestrator"
  default     = "Standard"
}

variable "trusted_cidr_ranges" {
  type        = list(string)
  description = "CIDR ranges allowed to access CI instances via ssh"

  validation {
    condition     = length(var.trusted_cidr_ranges) > 0
    error_message = "The trusted_cidr_ranges value must contain at least one CIDR."
  }
}

##################
# Runner details #
##################

variable "idle_count" {
  type        = number
  description = "The minimum number of runner machines that should be in place when there is no demand for jobs."
  default     = 0
}

variable "idle_time_seconds" {
  type        = number
  description = "The maximum time a machine will remain in place without running any jobs."
}

variable "max_builds_per_machine" {
  type        = number
  description = "The maximum number of jobs that will be run on a machine before it is removed."
}

variable "runner_machine_name" {
  type        = string
  description = "Name of the machine. It must contain %s, which is replaced with a unique machine identifier."
  default     = "auto-scale-%s"
}

variable "runner_storage_type" {
  type        = string
  description = "Storage type of the runner VM. Possible values are Standard_LRS, StandardSSD_LRS, Premium_LRS, StandardSSD_ZRS and Premium_ZRS."
  default     = "Premium_LRS"
}

variable "runner_vm_size" {
  type        = string
  description = "Size of runner VM to deploy"
  default     = "Standard_B2s"
}

variable "engine_install_url" {
  type        = string
  description = "URL to use for engine installation through docker-machine"
  default     = "https://releases.rancher.com/install-docker/19.03.9.sh"
}

###################
# Other resources #
###################

variable "container_registry_name" {
  type        = string
  description = "Container registry name to enable access to"
}

variable "core_resource_group_name" {
  type        = string
  description = "The resource group containing the container registry"
}

variable "network_address_space" {
  type        = list(string)
  description = "The address space that is used the virtual network. You can supply more than one address space."
  default = [
    "10.0.0.0/16"
  ]
}

variable "subnet_service_endpoints" {
  type        = list(string)
  description = "The list of Service endpoints to associate with the subnet."
}

variable "network_subnet_address_prefixes" {
  type        = list(string)
  description = "The address prefixes of the CI boxes subnet."
  default     = ["10.0.0.0/24"]
}
