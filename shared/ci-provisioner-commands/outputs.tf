output "init_docker" {
  description = "List of commands for installing and initialising docker"
  value       = local.init_docker
}

output "init_docker_machine" {
  description = "List of commands for installing and initialising docker-machine"
  value       = local.init_docker_machine
}

output "init_gitlab_runner" {
  description = "List of commands for installing and initialising gitlab-runner"
  value       = local.init_gitlab_runner
}

output "register_gitlab_runner" {
  description = "List of commands for registering gitlab-runner"
  value       = local.register_gitlab_runner
}

output "config_template_path" {
  description = "Config template file path"
  value       = var.config_template_path
}
