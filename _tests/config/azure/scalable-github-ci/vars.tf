variable "github_api_token" {
  type        = string
  description = "The GitHub API token to use for registering the runner"
  sensitive   = true
}

variable "primary_location" {
  type        = string
  description = "Main location to store everything (e.g. westeurope)"
}

variable "runner_label" {
  type        = string
  description = "The label to assign to the runner"
}

variable "cidr_range" {
  type        = string
  description = "CIDR range allowed to access CI instances via ssh"
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group in which to place resources"
}

