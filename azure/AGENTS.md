# `azure/`: notes for agents

Three modules. All use `azurerm >= 5.0.0` on this branch (`main` still has `>= 2.97.0` for
`gitlab-ci` and `>= 3.108.0` for `scalable-github-ci`; the upgrade is the open `upgrade-azurerm`
work) and look up an **existing** resource group with `data "azurerm_resource_group"`; the consumer
creates it. None of them create a provider block.

| Module | What it builds | Commit scope |
| --- | --- | --- |
| `gitlab-ci` | N static Linux VMs as GitLab `docker`-executor runners, provisioned by `shared/ci` | `azure-gitlab-ci` |
| `scalable-gitlab-ci` | one orchestrator VM running `gitlab-runner` with the `docker+machine` executor, creating runner VMs on demand via docker-machine's `azure` driver | `azure-gitlab-ci` historically (no scope of its own) |
| `scalable-github-ci` | a VM scale set of GitHub Actions runners scaled by Rocketmakers' `github-autoscaler` container app, driven by a GitHub webhook | `azure-github-ci` |

## Validation needs a fake provider block

`azurerm` refuses `terraform init` without `features {}` (and, from 4.x, a subscription id), so
`_build/run/validate/providers.ts` writes a temporary `providers.tf` with
`subscription_id = "68bb123f-6027-4e99-8ab0-a01fb16cdd79"` and `features {}` into each `azure/`
module during `pnpm turbo validate`, then deletes it. It is gitignored (`azure/**/providers.tf`).
Never add a real one.

## `azure/gitlab-ci`

- Networking is created by the module: VNet (`network_address_space`), one subnet
  (`network_subnet_address_prefixes`, `private_endpoint_network_policies = "Enabled"` hard-coded,
  optional `network_subnet_service_endpoints`), an NSG allowing SSH from `ssh_cidr_ranges`, and one
  Standard static public IP plus NIC per VM. Resource names are prefixed with the resource group
  name (`<rg>-network`, `<rg>-subnet`, `<rg>-nsg`, `<rg>-<name>-<n>`), VM names with
  `project_prefix`.
- `names` passed to `shared/ci` are the public IP resource names, so runner names on GitLab follow
  `<rg>-<name>-<n>`.
- Each VM has a system-assigned identity that gets `Reader` on the **subscription**, `AcrPush` on
  the container registry named by `container_registry_name` (looked up in the same resource group),
  and a key vault access policy on `key_vault_name` (also same resource group) with
  `key_vault_key_permissions` / `key_vault_secret_permissions`. Applying therefore needs rights to
  create role assignments (Owner or User Access Administrator), which is why the test service
  principal is an Owner.
- Default image Canonical `0001-com-ubuntu-server-jammy` / `22_04-lts`; VM size `Standard_B2s`;
  OS disk `Standard_LRS`, `disk_size` GB; `encryption_at_host_enabled` defaults **false** here and
  **true** in `scalable-github-ci`. Both defaults are load-bearing for existing deployments.
- The NIC `ip_configuration` is named `testconfiguration1`. Cosmetic, historic, leave it.
- History: v2.0.0 moved from `azurerm_virtual_machine` to `azurerm_linux_virtual_machine`, which
  rebuilt every runner; v3.0.0 raised azurerm to 4.9 and azuread to 3.0.2. Both were released as
  majors with `BREAKING CHANGE` notes.

## `azure/scalable-gitlab-ci`

- Creates two Entra applications + service principals + passwords with the `azuread` provider:
  `<rg>-orchestrator` (Reader on the subscription, Contributor on the CI resource group; used by
  docker-machine to create runner VMs) and `<rg>-runner` (Contributor on the **subscription** and
  `AcrPush` on the registry in `core_resource_group_name`; its credentials are exposed as
  `runner_client_id` / `runner_client_secret` outputs for jobs to use). Creating applications needs
  Graph `Application.ReadWrite.All` or equivalent.
- A storage account named `${lower(replace(project_prefix, "/\\W/", ""))}cicache` and container
  `<project_prefix>-ci-cache` hold the shared runner cache. Storage account names are global and at
  most 24 characters, so `project_prefix` must be at most 17 alphanumeric characters once
  non-word characters are stripped.
- The orchestrator VM (`Standard_B1ls`, `Standard_LRS` by default) has no provisioner on the VM
  resource. Provisioning lives in `terraform_data.orchestrator_provisioner` with
  `triggers_replace = [azurerm_linux_virtual_machine.orchestrator.id]`: a `file` provisioner writes
  the `config.toml` template (`[runners.machine]` with the `azure` driver options,
  `[runners.cache]` with the storage account key) to `module.shared_ci.config_template_path`, then a
  `remote-exec` runs the `shared/ci-provisioner-commands` lists with the `docker-machine create ...
  test-runner` / `rm` step in between. **Changing the template or the commands does not
  re-provision an existing orchestrator**; only replacing the VM (or tainting the `terraform_data`)
  does.
- `nonsensitive()` is used on the orchestrator client secret and the storage account key so they
  can be interpolated into the template and the `docker-machine create` command. They appear in
  plan output and provisioner logs as a result. Do not "fix" this by removing `nonsensitive()`
  without checking Terraform still accepts the provisioner arguments.
- Runner VMs are created by docker-machine with `azure-use-private-ip` and (in the test-runner
  step) `azure-no-public-ip`, on the module's VNet/subnet, with the same image as the orchestrator
  (`local.runner_image`), size `runner_vm_size`, storage `runner_storage_type` (default
  `Premium_LRS`), user `gitlab`.
- Scaling knobs map straight onto `[runners.machine]`: `idle_count` -> `IdleCount`,
  `idle_time_seconds` -> `IdleTime`, `max_builds_per_machine` -> `MaxBuilds`,
  `gitlab_max_runners` -> `limit` and the orchestrator `concurrent`. `idle_time_seconds` and
  `max_builds_per_machine` have **no defaults**, unlike the GCP twin.
- `readme.tpl` is titled `scalable-azure-ci`; the directory is `scalable-gitlab-ci`. Its
  "Rebuilding" section names `module.ci.azurerm_linux_virtual_machine.orchestrator`, which is
  correct.

## `azure/scalable-github-ci`

- The scale set is created with `instances = 0` and `lifecycle { ignore_changes = [instances] }`.
  The autoscaler owns the instance count; Terraform never fights it. `max_instance_count` is passed
  to the autoscaler as `MAX_RUNNERS`, not to the scale set. `overprovision = false` (v3.8.1: Azure
  overprovisioning created VMs that were then deleted, cancelling jobs). `scale_in.rule` defaults to
  `OldestVM`.
- Runners register through cloud-init (`custom_data`): install Docker from
  `docker_install_script_url`, download `actions-runner` `github_runner_version`, call the GitHub
  API with `github_api_token` for a registration token at
  `/repos/${github_organisation}/actions/runners/registration-token`, `config.sh --url
  https://github.com/${github_organisation} ... ${labels}` with `ACTIONS_RUNNER_INPUT_REPLACE=true`,
  install and start the service. Note the API path is `/repos/...`, so `github_organisation` in
  practice is `owner/repo` for a repository-level registration; the variable description covers both
  readings.
- `terraform_data.replace_runner` stores `sha256(local.install_github_runner_data)` and the scale
  set has `replace_triggered_by = [terraform_data.replace_runner]`. **Every change to the
  cloud-init text, including `github_runner_version`, `runner_labels`, `docker_install_script_url`
  or the API token, replaces the scale set.** Intended (v3.3.0), and worth a changelog line each
  time because consumers see a full rebuild.
- The autoscaler is an `azurerm_container_app` running
  `ghcr.io/rocketmakers/github-autoscaler:${autoscaler_version}` (default `1.0.5`) in its own
  Container App Environment with a Log Analytics workspace, `min_replicas = 1` (GitHub gives up on
  the webhook if the app has to cold start), external ingress on port 3000, secrets for the webhook
  secret (`random_string`, exposed as `github_webhook_secret`), the API token and the subscription
  id, and a system-assigned identity with `Reader` on the resource group and `Contributor` on the
  scale set. Environment variable names (`MAX_RUNNERS`, `SCALE_DOWN_RUNNERS`, `GITHUB_REPO`,
  `MS_DELAY_BEFORE_HANDLING_WEBHOOK`, ...) are the autoscaler's contract; check that repository
  before renaming any.
- `github_repository_webhook` (provider `integrations/github`, configured by the **consumer** with
  `owner` and a token) registers `https://<app fqdn>${autoscaler_webhook_path}` on
  `autoscaler_webhook_repo_name` for `autoscaler_webhook_events` (default `["workflow_job"]`).
  The webhook is per repository even when runners register at organisation level.
- A storage account `sa<name without hyphens>` provides boot diagnostics, so `name` must be
  lowercase alphanumeric plus hyphens and at most 22 characters after stripping hyphens.
- The three variables `storage_allow_nested_items_to_be_public`,
  `storage_cross_tenant_replication_enabled` and `subnet_private_endpoint_network_policies` exist
  only because azurerm 4.x/5.x changed those defaults. Their descriptions say which value keeps
  infrastructure created under 3.x unchanged. Copy this pattern for future provider majors.
- `encryption_at_host_enabled` defaults to `true` (the subscription must have the
  `EncryptionAtHost` feature registered) and `disk_storage_account_type` to `StandardSSD_LRS`
  (v3.8.0).
- `tls >= 4.0.5` here versus `>= 3.1.0` in the other two modules. Harmless difference; leave it.

## Testing

See `_tests/AGENTS.md`. Static and scalable GitLab tests need `GITLAB_TOKEN`; the GitHub test needs
`GH_RUNNER_API_TOKEN` and registers against organisation `rocketmakers` with the webhook on
repository `terraform-modules`. The `gitlab-ci` test expects key vault `terratest` to already exist
in resource group `Terratest`; the scalable tests create their own resource groups.

## Discrepancies between docs and code

- `azure/scalable-github-ci/readme.tpl` example sets `min_instance_count = 1`, which is not a
  variable of this module (the scale set floor is always 0; `min_replicas` applies to the
  autoscaler app). It also omits the required `autoscaler_webhook_repo_name`.
- `azure/scalable-github-ci/variables.tf` declares `autoscaler_workload_profile_type`
  (default `Consumption`) but nothing reads it; the workload profile block was removed in v3.6.0.
  Removing the variable is a breaking change for consumers who set it.
- `CHANGELOG.md` 3.2.0 states under `azure-gitlab-ci` that the minimum Terraform version is 1.4;
  all three Azure modules still require `>= 1.1.6`. See the root `AGENTS.md`.
- `azure/gitlab-ci/readme.tpl` example passes `var.runner_registration_token_name` and
  `var.runner_tags_name`; odd consumer-side names, not module inputs. Cosmetic.
- The pr-review-response skill says `azure/scalable-gitlab-ci` commits unscoped; the changelog
  history uses `azure-gitlab-ci`. Either passes commitizen.
