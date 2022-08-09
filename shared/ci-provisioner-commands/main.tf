locals {
  register_args = join(" ", [
    "--non-interactive",
    "--url https://gitlab.com",
    "--registration-token ${chomp(var.gitlab_token)}",
    "--template-config ${var.config_template_path}",
    "--tag-list ${join(",", var.runner_tags)}",
    "--executor docker+machine",
    "--docker-image ${var.gitlab_runner_docker_image}",
    "--locked=${var.gitlab_runner_locked}",
  ])

  download_gitlab_runner              = "sudo curl -L --output /usr/local/bin/gitlab-runner https://gitlab-runner-downloads.s3.amazonaws.com/${var.gitlab_runner_version}/binaries/gitlab-runner-linux-amd64"
  chmod_gitlab_runner                 = "sudo chmod +x /usr/local/bin/gitlab-runner"
  install_docker                      = "curl -sSL https://get.docker.com/ | sh"
  add_user_to_docker_group            = "sudo usermod -aG docker ${var.username}"
  update_default_new_user_info        = "sudo useradd --comment 'GitLab Runner' --create-home gitlab-runner --shell /bin/bash"
  install_gitlab_runner               = "sudo gitlab-runner install --user=gitlab-runner --working-directory=/home/gitlab-runner"
  start_gitlab_runner                 = "sudo gitlab-runner start"
  register_gitlab_runner_command      = "sudo gitlab-runner register --name ${var.name} ${local.register_args}"
  download_docker_machine             = "sudo curl -O \"https://gitlab-docker-machine-downloads.s3.amazonaws.com/${var.docker_machine_version}/docker-machine-Linux-x86_64\""
  install_docker_machine              = "sudo cp docker-machine-Linux-x86_64 /usr/local/bin/docker-machine && sudo chmod +x /usr/local/bin/docker-machine"
  set_gitlab_orchestrator_concurrency = "sudo sed -i '/concurrent = 1/c\\concurrent = ${var.gitlab_orchestrator_concurrency}' /etc/gitlab-runner/config.toml" // Set concurrency manually because gitlab is silly

  init_docker = [
    local.install_docker,
    local.add_user_to_docker_group
  ]
  init_docker_machine = [
    local.download_docker_machine,
    local.install_docker_machine
  ]
  init_gitlab_runner = [
    local.download_gitlab_runner,
    local.chmod_gitlab_runner,
    local.update_default_new_user_info,
    local.install_gitlab_runner,
    local.start_gitlab_runner
  ]
  register_gitlab_runner = [
    local.register_gitlab_runner_command,
    local.set_gitlab_orchestrator_concurrency
  ]
}
