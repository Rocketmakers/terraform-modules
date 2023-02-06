variable "project_prefix" {
  type        = string
  description = "A prefix given to resource names related to the runner instance"
}

variable "cidr_range" {
  type        = string
  description = "CIDR range allowed to access CI instances via ssh"
}

variable "runner_tag" {
  type        = string
  description = "The tag to give to the runner"
}

variable "max_builds_per_machine" {
  type        = number
  description = "The maximum number of jobs that will be run on a machine before it is removed."
}

variable "gitlab_max_runners" {
  type        = number
  description = "The maximum number of VMs that will be created (one VM will run one job at a time)."
}

variable "primary_location" {
  type        = string
  description = "Main location to store everything (e.g. westeurope)"
}

variable "runner_machine_name" {
  type        = string
  description = "Name of the machine. It must contain %s, which is replaced with a unique machine identifier."
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group in which to place resources"
}
