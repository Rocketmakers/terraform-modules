module shared_ci {
  source                     = "../../shared/ci"
  names                      = tolist(google_compute_address.ci_static_ip[*].name)
  username                   = var.username
  runner_tags                = var.runner_tags
  gitlab_token               = var.runner_registration_token
  gitlab_runner_concurrency  = var.gitlab_runner_concurrency
  gitlab_runner_version      = var.gitlab_runner_version
  gitlab_runner_docker_image = var.gitlab_runner_docker_image
  gitlab_runner_locked       = var.gitlab_runner_locked
  docker_prune_cron_schedule = var.docker_prune_cron_schedule
}

locals {
  install_monitoring_agent = [
    "curl -sSO https://dl.google.com/cloudagents/add-monitoring-agent-repo.sh",
    "sudo bash add-monitoring-agent-repo.sh --also-install",
    "sudo service stackdriver-agent start"
  ]
}

resource google_project_service compute {
  project = var.project_id
  service = "compute.googleapis.com"

  disable_dependent_services = var.disable_compute_on_destroy.disable_dependent_services
  disable_on_destroy         = var.disable_compute_on_destroy.disable_service
}

resource google_service_account ci_account {
  project      = var.project_id
  account_id   = "${var.project_prefix}-ci-runner"
  display_name = "Gitlab CI runner service account"
}

resource google_project_iam_member ci_roles {
  count = length(var.service_account_roles)

  project = var.project_id
  role    = var.service_account_roles[count.index]
  member  = "serviceAccount:${google_service_account.ci_account.email}"
}

resource google_storage_bucket_iam_member member {
  count = length(var.gcr_bucket_names)

  bucket = var.gcr_bucket_names[count.index]
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.ci_account.email}"
}

resource tls_private_key ci_ssh {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource google_compute_network ci_network {
  name                    = "${var.project_prefix}-${var.name}"
  auto_create_subnetworks = true
  project                 = google_project_service.compute.project
}

resource google_compute_firewall ci_firewall {
  project = google_compute_network.ci_network.project

  name    = google_compute_network.ci_network.name
  network = google_compute_network.ci_network.self_link

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.cidr_ranges
  target_tags   = var.tags
}

resource google_compute_address ci_static_ip {
  count   = var.instance_count
  project = google_compute_firewall.ci_firewall.project
  region  = var.gcp_region
  name    = "${google_compute_firewall.ci_firewall.name}-${count.index + 1}"
}

data google_compute_image ubuntu_image {
  project = var.image_project
  name    = var.image_name
}

resource google_compute_instance ci_box {
  project                   = var.project_id
  count                     = var.instance_count
  name                      = google_compute_address.ci_static_ip[count.index].name
  machine_type              = var.machine_type
  tags                      = var.tags
  allow_stopping_for_update = var.allow_stopping_for_update
  zone                      = var.zones[count.index % length(var.zones)]

  service_account {
    email  = google_service_account.ci_account.email
    scopes = var.service_account_scopes
  }

  metadata = {
    ssh-keys = format("%s:%s", var.username, tls_private_key.ci_ssh.public_key_openssh)
  }

  boot_disk {
    initialize_params {
      size  = var.disk_size
      image = data.google_compute_image.ubuntu_image.self_link
    }
  }

  network_interface {
    network = google_compute_network.ci_network.self_link
    access_config {
      nat_ip = google_compute_address.ci_static_ip[count.index].address
    }
  }

  provisioner remote-exec {
    connection {
      type        = "ssh"
      user        = var.username
      timeout     = "500s"
      private_key = tls_private_key.ci_ssh.private_key_pem
      host        = google_compute_address.ci_static_ip[count.index].address
    }

    inline = concat(
      module.shared_ci.provisioner_commands[count.index],
      local.install_monitoring_agent
    )
  }
}
