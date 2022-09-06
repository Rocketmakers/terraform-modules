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
