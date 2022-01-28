variable runner_tag {
  type        = string
  description = "The tag to give to the runner"
}

variable encrypted_gitlab_token {
  type        = string
  description = "Base64 encoded KMS encrypted gitlab token"
}

variable crypto_key_self_link {
  type        = string
  description = "Self link for the KMS crypto key"
}

variable instance_count {
  type        = number
  description = "The number of VM instances to create"
}
