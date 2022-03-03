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
  description = "The schedule to use for pruning docker images to prevent disk space filling up. Default value is weekly on Sundays at 0400 UTC."
  default     = "0 4 * * 0"
}

####################
# Instance details #
####################

variable "instance_count" {
  type        = number
  description = "The number of VM instances to create"
  default     = 1
}

variable "availability_zones" {
  type        = list(string)
  description = "The availability zones that the instance should be created in"
}

variable "image_config" {
  type = object({
    owners                      = list(string)
    filter_names                = list(string)
    filter_virtualization_types = list(string)
    filter_root_device_types    = list(string)
    default_username            = string
  })

  description = "A set of filters used to determine the OS image used on the instance. The latest matching image will be used. The default_username needs to be correct for the image that is resolved by the given filters."

  default = {
    owners                      = ["099720109477"] # Canonical - owner of Ubuntu image
    filter_names                = ["*ubuntu-bionic-18.04-amd64-server-*"]
    filter_virtualization_types = ["hvm"]
    filter_root_device_types    = ["ebs"]
    default_username            = "ubuntu"
  }
}

variable "tags" {
  type        = map(any)
  description = "Tags for aws resources"
  default     = {}
}

variable "instance_type" {
  type        = string
  description = "Instance type of the vm"
  default     = "t2.micro"
}

variable "disk_size" {
  type        = number
  description = "Size of disk in GB"
  default     = 50
}
