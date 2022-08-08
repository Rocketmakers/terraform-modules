locals {
  application_default_credentials_string = "/etc/gitlab-runner/application_default_credentials.json"
  ci_cache_bucket_name                   = "${var.project_prefix}-ci-cache"
}
module "shared_ci" {
  source                     = "../../shared/ci-provisioner-commands"
  names                      = tolist(google_compute_address.orchestrator_static_ip[*].name)
  username                   = var.username
  runner_tags                = var.runner_tags
  gitlab_token               = var.gitlab_token
  gitlab_runner_concurrency  = 1
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

module "runner_account" {
  source  = "terraform-google-modules/service-accounts/google"
  version = "4.1.1"

  project_id    = var.project_id
  project_roles = [for role in var.service_account_roles : "${var.project_id}=>${role}"]
  generate_keys = true
  names         = ["${var.project_prefix}-ci-runner"]
  descriptions  = ["Gitlab CI runner service account"]
}

module "orchestrator_account" {
  source  = "terraform-google-modules/service-accounts/google"
  version = "4.1.1"

  project_id = var.project_id
  project_roles = [
    "${var.project_id}=>roles/compute.admin",
    "${var.project_id}=>roles/iam.serviceAccountUser",
    "${var.project_id}=>roles/monitoring.metricWriter"
  ]
  generate_keys = true
  names         = ["${var.project_prefix}-ci-orchestrator"]
  descriptions  = ["Gitlab CI orchestrator service account"]
}

module "ci_cache" {
  source  = "terraform-google-modules/cloud-storage/google//modules/simple_bucket"
  version = "3.2.0"

  name          = local.ci_cache_bucket_name
  project_id    = var.project_id
  location      = var.cache_location
  force_destroy = true
}

resource "google_storage_bucket_iam_member" "cache" {
  count  = length(var.gcr_bucket_names)
  bucket = var.gcr_bucket_names[count.index]
  role   = "roles/storage.admin"
  member = "serviceAccount:${module.runner_account.email}"
}

resource "google_storage_bucket_iam_member" "gcr" {
  count  = length(var.gcr_bucket_names)
  bucket = var.gcr_bucket_names[count.index]
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
  project                 = var.project_id
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
  source_ranges = ["${google_compute_instance.orchestrator.network_interface[0].network_ip}/32"]
}


resource "google_compute_address" "orchestrator_static_ip" {
  project = google_compute_firewall.ci_firewall.project
  name    = google_compute_firewall.ci_firewall.name
  region  = var.region
}

data "google_compute_image" "ubuntu_image" {
  project = var.image_project
  name    = var.image_name
}

resource "google_compute_instance" "orchestrator" {
  project                   = var.project_id
  name                      = google_compute_address.orchestrator_static_ip.name
  machine_type              = var.orchestrator_machine_type
  tags                      = var.tags
  allow_stopping_for_update = var.allow_stopping_for_update
  zone                      = var.zone

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
      nat_ip = google_compute_address.orchestrator_static_ip.address
    }
  }
}

# We want to run this separately so that the instance is created and the internal ip is attached to google_compute_firewall.all_on_network
# This allows us to run docker-machine create within our provisioning so that the ssh keys are created before multiple jobs try to start up instances
resource "null_resource" "orchestrator_provisioner" {
  triggers = {
    instance_id = google_compute_instance.orchestrator.id
  }

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = var.username
      timeout     = "500s"
      private_key = tls_private_key.orchestrator_ssh.private_key_pem
      host        = google_compute_address.orchestrator_static_ip.address
    }

    content     = <<-EOF
  [[runners]]
    limit = ${var.gitlab_max_runners}
    builds_dir = "/tmp/builds"
    [runners.docker]
      image = "${var.gitlab_runner_docker_image}"
      volumes = ["/var/run/docker.sock:/var/run/docker.sock", "/cache", "/tmp/builds:/tmp/builds"]
    [runners.machine]
      IdleCount = ${var.orchestrator_idle_count}
      IdleTime = ${var.orchestrator_idle_time}
      MaxBuilds = ${var.orchestrator_max_builds}
      MachineName = "${var.runner_machine_name}"
      MachineDriver = "google"
      MachineOptions = [
        "google-project=${var.project_id}",
        "google-zone=${var.zone}",
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
        BucketName = "${local.ci_cache_bucket_name}"
        CredentialsFile = "${local.application_default_credentials_string}"
EOF
    destination = module.shared_ci.config_template_path
  }

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = var.username
      timeout     = "500s"
      private_key = tls_private_key.orchestrator_ssh.private_key_pem
      host        = google_compute_address.orchestrator_static_ip.address
    }

    content     = module.runner_account.key # module auto decodes key
    destination = "/tmp/application_default_credentials.json"
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = var.username
      timeout     = "500s"
      private_key = tls_private_key.orchestrator_ssh.private_key_pem
      host        = google_compute_address.orchestrator_static_ip.address
    }

    inline = concat(
      module.shared_ci.init_docker,
      module.shared_ci.init_docker_machine,
      [
        "sudo -i docker-machine create --driver google --google-project ${var.project_id} --google-machine-type ${var.runner_machine_type} --google-network ${google_compute_network.ci_network.name} --google-subnetwork ${google_compute_subnetwork.ci_subnet.name} --google-zone ${var.zone} --google-username root --engine-install-url ${var.engine_install_url} --google-machine-image ${data.google_compute_image.ubuntu_image.self_link} --google-skip-firewall-create --google-use-internal-ip test-runner",
        "sudo -i docker-machine rm -y test-runner"
      ],
      module.shared_ci.init_gitlab_runner,
      ["sudo mv /tmp/application_default_credentials.json ${local.application_default_credentials_string}"],
      module.shared_ci.register_gitlab_runner,
      local.install_monitoring_agent
    )
  }
}
