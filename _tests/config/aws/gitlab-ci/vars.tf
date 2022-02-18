variable "runner_tag" {
  type        = string
  description = "The tag to give to the runner"
}

variable "instance_count" {
  type        = number
  description = "The number of VM instances to create"
}

variable "aws_region" {
  type        = string
  description = "The AWS region used to configure the AWS provider"
}

variable "aws_access_key" {
  type        = string
  description = "The access key used to configure the AWS provider"
}

variable "aws_secret_key" {
  type        = string
  description = "The secret access key used to configure the AWS provider"
}

variable "aws_session_token" {
  type        = string
  description = "The STS session token used to configure the AWS provider"
}
