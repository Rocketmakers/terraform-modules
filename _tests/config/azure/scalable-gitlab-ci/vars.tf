variable "runner_tag" {
  type        = string
  description = "The tag to give to the runner"
}

variable "gitlab_project_id" {
  type        = string
  description = "Project id"
  default     = ""
}
variable "gitlab_max_runners" {
  type = number
}

variable "runner_machine_name" {
  type        = string
  description = "Name of the machine. It must contain %s, which is replaced with a unique machine identifier."
}

variable "project_prefix" {
  type        = string
  description = "The project prefix"
}

variable "cidr_range" {
  type        = string
  description = "CIDR ranges allowed to access CI instances via ssh"
  default     = ""
}

variable "azure_project_zone" {
  type        = string
  description = "Which zone to deploy the infrastructure into."
}

variable "azure_project_region" {
  type        = string
  description = "Which region to deploy the infrastructure into."
}