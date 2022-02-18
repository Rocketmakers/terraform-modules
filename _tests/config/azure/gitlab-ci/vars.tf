variable "runner_tag" {
  type        = string
  description = "The tag to give to the runner"
}

variable "instance_count" {
  type        = number
  description = "The number of VM instances to create"
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group in which to place resources"
}
