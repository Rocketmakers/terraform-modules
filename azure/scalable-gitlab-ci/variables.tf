#####################################################
# Registration details (passed to shared/ci module) #
#####################################################

variable "project_prefix" {
  type        = string
  description = "A prefix given to resource names related to the runner instance"
}

variable "trusted_cidr_ranges" {
  type        = list(string)
  description = "CIDR ranges allowed to access CI instances via ssh"

  validation {
    condition     = length(var.trusted_cidr_ranges) > 0
    error_message = "The trusted_cidr_ranges value must contain at least one CIDR."
  }
}

variable "runner_tags" {
  type        = list(string)
  description = "List of tags for gitlab runner, used to allow the runner to be selected for jobs."
}

variable "registration_token_secret_name" {
  type        = string
  description = "The name of the azure key vault secret containing the token used to register the gitlab runner"
}

variable "registration_token_key_vault_id" {
  type        = string
  description = "The id of the azure key vault containing the token used to register the gitlab runner"
}

variable "name" {
  type        = string
  description = "Main name of resources created"
  default     = "ci"
}

variable "idle_count" {
  type        = number
  description = "The minimum number of runner machines that should be in place when there is no demand for jobs."
}

variable "idle_time_seconds" {
  type        = number
  description = "The maximum time a machine will remain in place without running any jobs."
}

variable "max_builds_per_machine" {
  type        = number
  description = "The maximum number of jobs that will be run on a machine before it is removed."
}

variable "username" {
  type        = string
  description = "Username for CI box"
  default     = "ci"
}

variable "gitlab_runner_concurrency" {
  type        = number
  description = "The maximum number of machines that will be in place at any one time (one job per machine)"
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
  description = "Resource group"
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
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

variable "orchestrator_vm_size" {
  type        = string
  description = "Size of orchestrator VM to deploy"
  default     = "Standard_B1ls"
}

variable "runner_vm_size" {
  type        = string
  description = "Size of runner VM to deploy"
  default     = "Standard_B2s"
}

variable "disk_size_gb" {
  type        = number
  description = "Size of disk in GB"
}

###################
# Other resources #
###################

variable "core_resource_group_name" {
  type        = string
  description = "The resource group containing the container registry and key vault"
}

variable "container_registry_name" {
  type        = string
  description = "Container registry name to enable access to"
}

variable "key_vault_name" {
  type        = string
  description = "Azure key vault id that jobs on the runner will need to access."
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

variable "engine_install_url" {
  type        = string
  description = "URL to use for engine installation through docker-machine"
  default     = "https://releases.rancher.com/install-docker/19.03.9.sh"
}

variable "subnet_service_endpoints" {
  type        = list(string)
  description = "The list of Service endpoints to associate with the subnet."
}
