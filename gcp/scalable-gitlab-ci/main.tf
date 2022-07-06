module "shared_ci" {
  source                     = "../../shared/ci-provisioner-commands"
  names                      = tolist(google_compute_address.orchestrator_static_ip[*].name)
  username                   = var.username
  runner_tags                = var.runner_tags
  gitlab_token               = var.gitlab_token
  gitlab_runner_concurrency  = var.gitlab_runner_concurrency
  gitlab_runner_version      = var.gitlab_runner_version
  gitlab_runner_docker_image = var.gitlab_runner_docker_image
  gitlab_runner_locked       = var.gitlab_runner_locked
}

locals {
  install_monitoring_agent = [
    "curl -sSO https://dl.google.com/cloudagents/add-monitoring-agent-repo.sh",
    "sudo bash add-monitoring-agent-repo.sh --also-install",
    "sudo service stackdriver-agent start"
  ]
}

resource "google_project_service" "compute" {
  project = var.project_id
  service = "compute.googleapis.com"

  disable_dependent_services = var.disable_compute_on_destroy.disable_dependent_services
  disable_on_destroy         = var.disable_compute_on_destroy.disable_service
}

module "runner_account" {
  source = "../service-account"

  project-id = google_project_service.compute.project
  id         = "${var.project_prefix}-ci-runner"
  name       = "Gitlab CI runner service account"
  roles      = var.service_account_roles
}

resource "google_storage_bucket" "ci_cache" {
  project       = var.project_id
  name          = "${var.project_prefix}-ci-cache"
  location      = var.cache_location
  force_destroy = true
}

module "orchestrator_account" {
  source = "../service-account"

  project-id = google_project_service.compute.project
  id         = "${var.project_prefix}-ci-orchestrator"
  name       = "Gitlab CI orchestrator service account"
  roles = [
    "roles/compute.admin",
    "roles/iam.serviceAccountUser",
    "roles/monitoring.metricWriter"
  ]
}

resource "google_storage_bucket_iam_member" "gcr" {
  count  = length(var.gcr_bucket_names)
  bucket = var.gcr_bucket_names[count.index]
  role   = "roles/storage.admin"
  member = "serviceAccount:${module.runner_account.email}"
}

resource "google_storage_bucket_iam_member" "cache" {
  bucket = google_storage_bucket.ci_cache.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${module.runner_account.email}"
}

resource "tls_private_key" "orchestrator_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "google_compute_network" "ci_network" {
  name                    = "${var.project_prefix}-${var.name}"
  auto_create_subnetworks = false
  project                 = google_project_service.compute.project
}

resource "google_compute_subnetwork" "ci_subnet" {
  name          = "${google_compute_network.ci_network.name}-${var.region}"
  ip_cidr_range = "10.128.0.0/20"
  region        = var.region
  network       = google_compute_network.ci_network.name
  project       = google_compute_network.ci_network.project
}

resource "google_compute_firewall" "ci_firewall" {
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

resource "google_compute_firewall" "all_on_network" {
  project = google_compute_network.ci_network.project

  name    = "${google_compute_network.ci_network.name}-all-on-network"
  network = google_compute_network.ci_network.self_link

  allow {
    protocol = "all"
  }
  source_ranges = ["${google_compute_instance.orchestrator[0].network_interface[0].network_ip}/32"]
}


resource "google_compute_address" "orchestrator_static_ip" {
  count   = var.instance_count
  project = google_compute_firewall.ci_firewall.project
  name    = "${google_compute_firewall.ci_firewall.name}-${count.index + 1}"
  region  = var.region
}

data "google_compute_image" "ubuntu_image" {
  project = var.image_project
  name    = var.image_name
}

resource "google_compute_instance" "orchestrator" {
  project                   = var.project_id
  count                     = var.instance_count
  name                      = google_compute_address.orchestrator_static_ip[count.index].name
  machine_type              = var.orchestrator_machine_type
  tags                      = var.tags
  allow_stopping_for_update = var.allow_stopping_for_update
  zone                      = var.zones[count.index % length(var.zones)]

  service_account {
    email  = module.orchestrator_account.email
    scopes = ["compute-rw", "monitoring-write", "cloud-platform"]
  }

  metadata = {
    ssh-keys = format("%s:%s", var.username, tls_private_key.orchestrator_ssh.public_key_openssh)
  }

  boot_disk {
    initialize_params {
      size  = var.orchestrator_disk_size
      image = data.google_compute_image.ubuntu_image.self_link
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.ci_subnet.self_link
    access_config {
      nat_ip = google_compute_address.orchestrator_static_ip[count.index].address
    }
  }
}

# We want to run this separately so that the instance is created and the internal ip is attached to google_compute_firewall.all_on_network
# This allows us to run docker-machine create within our provisioning so that the ssh keys are created before multiple jobs try to start up instances
resource "null_resource" "orchestrator_provisioner" {
  count = var.instance_count

  triggers = {
    instance_id = google_compute_instance.orchestrator[count.index].id
  }

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = var.username
      timeout     = "500s"
      private_key = tls_private_key.orchestrator_ssh.private_key_pem
      host        = google_compute_address.orchestrator_static_ip[count.index].address
    }

    content     = <<-EOF
  [[runners]]
    limit = ${var.gitlab_runner_concurrency}
    builds_dir = "/tmp/builds"
    [runners.docker]
      image = "${var.gitlab_runner_docker_image}"
      volumes = ["/var/run/docker.sock:/var/run/docker.sock", "/cache", "/tmp/builds:/tmp/builds"]
    [runners.machine]
      IdleCount = ${var.orchestrator_idle_count}
      IdleTime = ${var.orchestrator_idle_time}
      MaxBuilds = ${var.orchestrator_max_builds}
      MachineName = ${var.runner_machine_name}
      MachineDriver = "google"
      MachineOptions = [
        "google-project=${var.project_id}",
        "google-zone=${var.zones[count.index % length(var.zones)]}",
        "google-machine-type=${var.runner_machine_type}",
        "google-machine-image=${data.google_compute_image.ubuntu_image.self_link}",
        "google-network=${google_compute_network.ci_network.name}",
        "google-subnetwork=${google_compute_subnetwork.ci_subnet.name}",
        "google-username=root",
        "google-preemptible=true",
        "engine-registry-mirror=https://mirror.gcr.io",
        "google-use-internal-ip",
        "google-skip-firewall-create",
        "google-disk-size=${var.runner_disk_size}",
        "google-service-account=${module.runner_account.email}",
        "google-scopes=https://www.googleapis.com/auth/devstorage.read_write,https://www.googleapis.com/auth/cloud-platform,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write",
        "engine-install-url=${var.engine_install_url}"
      ]
    [runners.cache]
      Type = "gcs"
      Path = "gitlab-runner"
      Shared = true
      [runners.cache.gcs]
        BucketName = "${google_storage_bucket.ci_cache.name}"
        CredentialsFile = "/etc/gitlab-runner/application_default_credentials.json"
EOF
    destination = module.shared_ci.config_template_path
  }

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = var.username
      timeout     = "500s"
      private_key = tls_private_key.orchestrator_ssh.private_key_pem
      host        = google_compute_address.orchestrator_static_ip[count.index].address
    }

    content     = base64decode(module.runner_account.key)
    destination = "/tmp/application_default_credentials.json"
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = var.username
      timeout     = "500s"
      private_key = tls_private_key.orchestrator_ssh.private_key_pem
      host        = google_compute_address.orchestrator_static_ip[count.index].address
    }

    inline = concat(
      module.shared_ci.init_docker,
      module.shared_ci.init_docker_machine,
      [
        "sudo -i docker-machine create --driver google --google-project ${var.project_id} --google-machine-type ${var.runner_machine_type} --google-network ${google_compute_network.ci_network.name} --google-zone ${var.zones[count.index % length(var.zones)]} --google-username root --engine-install-url ${var.engine_install_url} --google-machine-image ${data.google_compute_image.ubuntu_image.self_link} --google-skip-firewall-create --google-use-internal-ip test-runner",
        "sudo -i docker-machine rm -y test-runner"
      ],
      module.shared_ci.init_gitlab_runner,
      ["sudo mv /tmp/application_default_credentials.json /etc/gitlab-runner/application_default_credentials.json"],
      module.shared_ci.register_gitlab_runner[count.index],
      local.install_monitoring_agent
    )
  }
}
