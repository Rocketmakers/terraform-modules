module "project-factory_project_services" {
  source  = "terraform-google-modules/project-factory/google//modules/project_services"
  version = "13.0.0"

  project_id = var.project_id
  activate_apis = [
    "cloudkms.googleapis.com",
    "containerregistry.googleapis.com",
    "compute.googleapis.com",
    "run.googleapis.com",
    "servicenetworking.googleapis.com",
    "vpcaccess.googleapis.com",
    "secretmanager.googleapis.com"
  ]
  disable_services_on_destroy = false
  disable_dependent_services = false
}

resource "google_container_registry" "registry" {
  project  = var.project_id
  location = "EU"
}

data "gitlab_project" "runner_token" {
  id = "33153506"
}

module "ci" {
  depends_on = [
    module.project-factory_project_services
  ]

  source = "../../../../gcp/scalable-gitlab-ci"

  project_id     = var.project_id
  project_prefix = "scalable"
  zone                     = "europe-west1-b"
  region                    = "europe-west1"
  runner_tags               = [var.project_id]
  cidr_ranges               = ["212.139.176.173/32"]
  orchestrator_machine_type = "f1-micro"
  runner_machine_type       = "n2d-standard-2"
  service_account_roles = [
    "${var.project_id}=>roles/cloudkms.cryptoKeyDecrypter",
    "${var.project_id}=>roles/storage.admin",
    "${var.project_id}=>roles/viewer",
    "${var.project_id}=>roles/secretmanager.admin",
    "${var.project_id}=>roles/run.admin",
    "${var.project_id}=>roles/iam.serviceAccountUser",
    "${var.project_id}=>roles/monitoring.metricWriter",
  ]
  gitlab_token              = data.gitlab_project.runner_token.runners_token
  gcr_bucket_names          = [google_container_registry.registry.id]
  gitlab_max_runners        = 3
  cache_location            = "EUROPE-WEST1"
}