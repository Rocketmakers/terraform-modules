variable "runner_tag" {
  type        = string
  description = "The tag to give to the runner"
}

variable "project_id" {
  type = string
  description = "Project id"
  default = "terraform-testing-317911"
}
variable "gitlab_max_runners" {
  type        = number
}

variable "runner_machine_name" {
  type        = string
  description = "Name of the machine. It must contain %s, which is replaced with a unique machine identifier."
}

variable "project_prefix" {
  type        = string
  description = "The project prefix"
}