variable "project_id" {
  type        = string
  description = "The ID of the google project to deploy to"
  default     = "terraform-testing-317911"
}

variable "gcp_project_zone" {
  type        = string
  description = "Which zone to deploy the infrastructure into."
}

variable "gcp_project_region" {
  type        = string
  description = "Which region to deploy the infrastructure into."
}

variable "github_api_token" {
  type        = string
  description = "The GitHub API token to use for registering the runner"
  sensitive   = true
}

variable "runner_label" {
  type        = string
  description = "The label to assign to the runner"
}

variable "cidr_range" {
  type        = string
  description = "CIDR range allowed to access CI instances via ssh"
}
