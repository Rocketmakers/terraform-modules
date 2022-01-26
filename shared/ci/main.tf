locals {
  register_args = join(" ", [
    "--non-interactive",
    "--url https://gitlab.com",
    "--registration-token ${chomp(var.gitlab_token)}",
    "--tag-list ${join(",", var.runner_tags)}",
    "--executor docker",
    "--docker-image ${var.gitlab_runner_docker_image}",
    "--locked=${var.gitlab_runner_locked}",
    "--docker-volumes /var/run/docker.sock:/var/run/docker.sock",
    "--docker-volumes /cache",
    "--docker-volumes /tmp/builds:/tmp/builds",
    "--builds-dir /tmp/builds"
  ])

  download_gitlab_runner       = "sudo curl -L --output /usr/local/bin/gitlab-runner https://gitlab-runner-downloads.s3.amazonaws.com/${var.gitlab_runner_version}/binaries/gitlab-runner-linux-amd64"
  chmod_gitlab_runner          = "sudo chmod +x /usr/local/bin/gitlab-runner"
  install_docker               = "curl -sSL https://get.docker.com/ | sh"
  add_user_to_docker_group     = "sudo usermod -aG docker ${var.username}"
  update_default_new_user_info = "sudo useradd --comment 'GitLab Runner' --create-home gitlab-runner --shell /bin/bash"
  install_gitlab_runner        = "sudo gitlab-runner install --user=gitlab-runner --working-directory=/home/gitlab-runner"
  start_gitlab_runner          = "sudo gitlab-runner start"
  docker_system_prune_cron_job = "(crontab -l 2>/dev/null; echo '${var.docker_prune_cron_schedule} docker system prune -f -a --volumes') | crontab -"
  register_gitlab_runner = [
    for name in var.names :
    "sudo gitlab-runner register --name ${name} ${local.register_args}"
  ]
  set_gitlab_runner_concurrency = "sudo sed -i '/concurrent = 1/c\\concurrent = ${var.gitlab_runner_concurrency}' /etc/gitlab-runner/config.toml" // Set concurrency manually because gitlab is silly

  provisioner_commands = [
    for register_gitlab_runner in local.register_gitlab_runner :
    [
      local.download_gitlab_runner,
      local.chmod_gitlab_runner,
      local.install_docker,
      local.add_user_to_docker_group,
      local.update_default_new_user_info,
      local.install_gitlab_runner,
      local.start_gitlab_runner,
      local.docker_system_prune_cron_job,
      register_gitlab_runner,
      local.set_gitlab_runner_concurrency
  ]]
}
