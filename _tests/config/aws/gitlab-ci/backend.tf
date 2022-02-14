terraform {
  # Config given in terratest code
  backend "s3" {}

  required_providers {
    gitlab = {
      source = "gitlabhq/gitlab"
    }
  }
}

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  token      = var.aws_session_token
}
