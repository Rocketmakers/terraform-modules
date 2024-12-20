locals {
  name = "${var.project_prefix}-${var.name}"

  # Adapted from https://brendanthompson.com/posts/2021/09/github-actions-self-hosted-runner-on-azure
  install_github_runner_data = <<EOF
#! /bin/bash
echo "Installing Docker"
curl -sSL https://get.docker.com/ | sh
su root -c 'usermod -aG docker root'
echo "Setting up Docker prune"
(crontab -l 2>/dev/null; echo '${var.docker_prune_cron_schedule} docker system prune -f -a --volumes') | crontab -
echo "Downloading GitHub runner installer"
mkdir '/actions-runner'
cd /actions-runner
curl -o 'actions-runner.tar.gz' -L 'https://github.com/actions/runner/releases/download/v${var.github_runner_version}/actions-runner-linux-x64-${var.github_runner_version}.tar.gz'
tar -xzf 'actions-runner.tar.gz'
chmod -R 777 '/actions-runner'
echo "Retrieving GitHub runner token"
curl -s -X POST -H 'Accept: application/vnd.github+json' -H 'Authorization: Bearer ${var.github_api_token}' -H 'X-GitHub-Api-Version: 2022-11-28' 'https://api.github.com/repos/${var.github_organisation}/actions/runners/registration-token' > .runner_token_output
cat .runner_token_output | sed -n 's/.*"token": "\([^"]*\)".*/\1/p' > .runner_token
echo "Registering GitHub runner"
export ACTIONS_RUNNER_INPUT_REPLACE=true
export RUNNER_ALLOW_RUNASROOT="1"
su root -c '/actions-runner/config.sh --url https://github.com/${var.github_organisation} --token $(cat /actions-runner/.runner_token)'
./svc.sh install
./svc.sh start
rm '/actions-runner/actions-runner.tar.gz'
EOF
}

resource "google_compute_firewall" "ci_firewall" {
  project = google_compute_network.ci_network.project

  name    = google_compute_network.ci_network.name
  network = google_compute_network.ci_network.self_link

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.ssh_cidr_ranges
  target_tags   = var.tags
}

resource "google_compute_network" "ci_network" {
  name                    = local.name
  auto_create_subnetworks = false
  project                 = var.project_id
}

resource "google_compute_subnetwork" "ci_subnet" {
  name          = "${google_compute_network.ci_network.name}-${var.region}"
  ip_cidr_range = var.subnetwork_ip_cidr
  region        = var.region
  network       = google_compute_network.ci_network.name
  project       = google_compute_network.ci_network.project
}

resource "google_compute_autoscaler" "main" {
  name   = "${local.name}-autoscaler"
  zone   = var.zone
  target = google_compute_instance_group_manager.main.id

  autoscaling_policy {
    max_replicas    = var.max_instance_count
    min_replicas    = var.min_instance_count
    cooldown_period = 60

    cpu_utilization {
      target = 0.1
    }
  }
}

data "google_compute_image" "image" {
  project = var.image_project
  name    = var.image_name
}

resource "tls_private_key" "ssh" {
  algorithm = "ED25519"
}

module "account" {
  source  = "terraform-google-modules/service-accounts/google"
  version = "4.4.2"

  project_id    = var.project_id
  project_roles = [for role in var.service_account_roles : "${var.project_id}=>${role}"]
  generate_keys = true
  names         = ["${var.project_prefix}-ci"]
  descriptions  = ["GitHub CI service account"]
}


resource "google_compute_instance_template" "main" {
  name           = "${local.name}-template"
  machine_type   = var.machine_type
  can_ip_forward = false

  disk {
    source_image = data.google_compute_image.image.id
    disk_size_gb = var.disk_size_gb
  }

  network_interface {
    subnetwork = google_compute_subnetwork.ci_subnet.self_link
    access_config {
      // Required to assign an external IP address
    }
  }

  metadata = {
    ssh-keys = format("%s:%s", var.username, tls_private_key.ssh.public_key_openssh)
  }

  service_account {
    email  = module.account.email
    scopes = ["userinfo-email", "compute-ro", "storage-ro", "cloud-platform"]
  }

  metadata_startup_script = local.install_github_runner_data
}

resource "google_compute_target_pool" "main" {
  name   = "${local.name}-pool"
  region = var.region
}

resource "google_compute_instance_group_manager" "main" {
  name = "${local.name}-manager"
  zone = var.zone

  version {
    instance_template = google_compute_instance_template.main.id
    name              = "primary"
  }

  target_pools       = [google_compute_target_pool.main.id]
  base_instance_name = local.name
}