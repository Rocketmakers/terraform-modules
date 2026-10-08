# `gcp/`: notes for agents

Three modules on the `google` provider (lower bounds `>= 4.11.0` / `>= 4.27.0`; v3.8.4 made them
work with provider 7.x by bumping the registry modules they use). GCP needs no provider stub for
validation. Every module creates its own VPC network and firewall; consumers pass `project_id`.

| Module | What it builds | Commit scope |
| --- | --- | --- |
| `gitlab-ci` | N static Compute Engine VMs as GitLab `docker`-executor runners, provisioned by `shared/ci`, plus the Ops Agent | `gcp-gitlab-ci` |
| `scalable-gitlab-ci` | one orchestrator VM running `gitlab-runner` with `docker+machine`, creating **preemptible** runner VMs via docker-machine's `google` driver, with a GCS cache bucket | `gcp-gitlab-ci` historically (no scope of its own) |
| `scalable-github-ci` | an instance template + zonal managed instance group + CPU-based autoscaler of GitHub Actions runners | `gcp-github-ci` |

## Naming and region/zone conventions differ between modules

- `gitlab-ci` takes `gcp_region` and a `zones` list (instances round-robin across zones).
- Both scalable modules take `region` and a single `zone`.
- `gitlab-ci` exposes `image_config = { project_name, image_name }`; the scalable modules expose
  `image_project` and `image_name` as separate variables.
- `gitlab-ci` and `scalable-gitlab-ci` set `project = var.project_id` on most resources;
  `scalable-github-ci` sets it only on the network, subnetwork and firewall, and relies on the
  provider's default project for the template, group manager, target pool and autoscaler.

These are inconsistencies to copy within each module, not to harmonise: renaming a variable is a
breaking change.

## `gcp/gitlab-ci`

- Auto-mode VPC (`auto_create_subnetworks = true`) named `<project_prefix>-<name>`, firewall
  allowing TCP 22 from `ssh_cidr_ranges` to instances tagged with `tags` (default
  `["ci", "externalssh"]`), one regional static address per instance; instance names equal the
  address names (`<network>-<n>`), which are also the runner names passed to `shared/ci`.
- One service account `<project_prefix>-<name>-runner` with `service_account_roles` (default
  `roles/monitoring.metricWriter`) and `roles/storage.admin` on each bucket in `gcr_bucket_names`.
  Those buckets must already exist, which is why the README warns about fresh projects: push one
  image to Container Registry first, or pass an empty list.
- SSH key is ED25519 from the `tls` provider, injected through instance metadata `ssh-keys`.
- Default image is the specific `ubuntu-2004-focal-v20230302` in `ubuntu-os-cloud`. Google
  eventually deprecates dated images; changing the default replaces every consumer's VMs. Default
  machine type `f1-micro`.
- After the `shared/ci` commands, the provisioner installs the Google Cloud Ops Agent
  (`local.install_monitoring_agent`). Provisioner changes do not re-run on existing VMs (see
  `shared/AGENTS.md`).
- `allow_stopping_for_update = true` by default so machine-type changes can be applied in place.

## `gcp/scalable-gitlab-ci`

- Uses two registry modules pinned **exactly**: `terraform-google-modules/service-accounts/google`
  `4.6.0` (twice, for the runner and orchestrator service accounts, with `generate_keys = true`)
  and `terraform-google-modules/cloud-storage/google//modules/simple_bucket` `3.4.1` for the
  `<project_prefix>-ci-cache` bucket (`force_destroy = true`). Exact pins on external **modules**
  are the convention here (providers get lower bounds); bump them deliberately, as v3.0.0 and
  v3.8.4 did.
- Service account **keys** are generated and stored in state. The runner key is uploaded to the
  orchestrator as `/etc/gitlab-runner/application_default_credentials.json` and referenced by
  `[runners.cache.gcs] CredentialsFile`. Both keys are outputs (`sensitive`).
- Custom-mode VPC with one subnet hard-coded to `10.128.0.0/20` in `region`, an SSH firewall from
  `cidr_ranges` (note: not `ssh_cidr_ranges` as in the other GCP modules) to `tags`, and an
  `all_on_network` firewall allowing everything from the orchestrator's internal IP so it can reach
  the runner VMs it creates. That second rule depends on the orchestrator instance, which is why
  provisioning is split out.
- Provisioning is in `null_resource.orchestrator_provisioner` (the older pattern; the Azure twin
  uses `terraform_data`) keyed on the instance id: `file` provisioner for the `config.toml`
  template (`[runners.machine]` with the `google` driver, `google-preemptible=true`,
  `google-use-internal-ip`, `google-skip-firewall-create`, `engine-registry-mirror=https://mirror.gcr.io`;
  `[runners.cache]` type `gcs`), a second `file` provisioner for the credentials JSON, then
  `remote-exec` running the `shared/ci-provisioner-commands` lists with the `docker-machine create
  ... test-runner` / `rm` step, the credentials move, and the Ops Agent install. Same caveat as
  Azure: changing the template does not re-provision an existing orchestrator.
- The orchestrator service account gets `roles/compute.admin`, `roles/iam.serviceAccountUser` and
  `roles/monitoring.metricWriter` hard-coded; runner roles come from `service_account_roles`, which
  the module prefixes with `${var.project_id}=>` itself.
- `required_version = ">= 1.4"` (the only module above 1.1.6; see the changelog discrepancy in the
  root `AGENTS.md`). `runner_machine_type` and `cache_location` are required; `idle`/`max builds`
  knobs have defaults here (`orchestrator_idle_count = 0`, `orchestrator_idle_time = 300`,
  `orchestrator_max_builds = 100`), unlike Azure.
- `outputs.tf` keeps five `[Deprecated]` outputs (`service_account_key`, `service_account_email`,
  `username`, `private_key`, `public_key`) alongside the `orchestrator_*` replacements. That is the
  house pattern for renaming an output without a major release. Removing them is breaking.

## `gcp/scalable-github-ci`

- `google_compute_instance_template` -> `google_compute_instance_group_manager` (zonal, with an
  otherwise unused `google_compute_target_pool`) -> `google_compute_autoscaler` on
  `cpu_utilization.target = cpu_percentage_target_utilization` (default `0.1`, i.e. 10%), between
  `min_instance_count` and `max_instance_count` (both default 1), `cooldown_period` 60 s.
- `replace_triggered_by` chains: template change -> group manager replaced -> autoscaler replaced.
  Without it the template cannot be recreated while in use and the autoscaler is orphaned. Any
  change to the startup script (`github_runner_version`, labels, Docker script URL, prune schedule,
  API token) therefore recreates every runner VM. Intended (v3.3.0); say so in the changelog.
- The startup script is a plain bash `metadata_startup_script` running as root
  (`RUNNER_ALLOW_RUNASROOT=1`): install Docker, add the prune cron (`docker_prune_cron_schedule`),
  download `actions-runner` `github_runner_version`, fetch a registration token from
  `/repos/${github_organisation}/actions/runners/registration-token` with `github_api_token`,
  `config.sh --url https://github.com/${github_organisation}` with `ACTIONS_RUNNER_INPUT_REPLACE=true`,
  install and start the service. It runs on **every boot**, and the token is visible in instance
  metadata to anyone who can read the instance.
- Runner VMs get an external IP (empty `access_config {}`), a custom-mode VPC with a
  `subnetwork_ip_cidr` subnet (default `10.128.0.0/28`, 14 addresses, so `max_instance_count` is
  bounded by it), and a service account from the `service-accounts` registry module (`4.6.0`,
  `generate_keys = true` although the key is never used) with `service_account_roles`.
- Default image `ubuntu-2504-plucky-amd64-v20250815`. Outputs are only `network_name`,
  `network_self_link` and `subnetwork_ip_cidr`.
- No `gcr_bucket_names`, no cache bucket, no webhook: scaling is purely CPU-driven, unlike the
  Azure twin.

## Testing

See `_tests/AGENTS.md`. Project `terraform-testing-317911`, `europe-west1`. The
`scalable-gitlab-ci` fixture also enables the required project APIs through
`terraform-google-modules/project-factory/google//modules/project_services` `13.0.0`. The
`scalable-github-ci` fixture is not in a runnable state (pinned provider, swapped region/zone,
placeholder organisation); it applies and destroys but cannot register runners.

## Discrepancies between docs and code

- `gcp/scalable-gitlab-ci/readme.tpl` example passes `service_account_roles` as
  `"${var.project_id}=>roles/..."`; the module already prefixes each role with
  `${var.project_id}=>` (fixed in v1.1.1 / v2.1.3), so following the example yields
  `proj=>proj=>roles/...`. The example also pins `required_version = "1.1.6"` and exact provider
  versions in the consumer block, contrary to the lower-bound rule, and contains a broken link
  (`https: //cloud.google.com/...`). Its "Rebuilding CI box" section names
  `module.ci_box.google_compute_instance.ci_box`; the resource here is
  `google_compute_instance.orchestrator`.
- `gcp/scalable-github-ci/readme.tpl` example passes `gcr_bucket_names`, which this module does not
  have.
- Both GitLab READMEs refer to "the `ci-box` module" in the fresh-project warning; the module is
  `gitlab-ci`.
- `_tests/config/gcp/scalable-github-ci/backend.tf` pins `google 4.27.0` and swaps `region`/`zone`
  in the provider block; `main.tf` has a placeholder `github_organisation`. See `_tests/AGENTS.md`.
- The changelog entry for v3.2.0 uses the scope `scalabale-github-ci` (typo, not in
  `.commit-config.js`); commitizen would not accept it today.
