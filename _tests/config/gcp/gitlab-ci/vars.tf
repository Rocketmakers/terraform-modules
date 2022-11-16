variable "runner_tag" {
  type        = string
  description = "The tag to give to the runner"
}

variable "instance_count" {
  type        = number
  description = "The number of VM instances to create"
}


variable "cidr_range" {
  type        = string
  description = "CIDR ranges allowed to access CI instances via ssh"
  default     = "212.139.176.173/32"
}
