# `_tests/`: the terratest harness

Every test applies a module against a real Rocketmakers cloud account, checks it, and destroys it.
Nothing here runs in CI (see the root `AGENTS.md`); tests are run by hand, one at a time, from a
machine that can reach the cloud APIs and, for the runner checks, from an IP the fixtures allow.
Commit scope: `terratest`. `CONTRIBUTING.md` "Running tests" has the command lines and the
environment variables; this file explains what is behind them.

## Layout

```
_tests/config/<cloud>/<module>/   Terraform fixture: backend.tf, main.tf, vars.tf, outputs.tf
_tests/src/<cloud>/<module>/      Go test package with its own go.mod and go.sum
_tests/src/backend-config/        backendconfig: fixed remote-state settings per cloud
_tests/src/gitlab-api/            gitlabapi: the shared apply / check runners / destroy flow for the static gitlab-ci modules
_tests/src/modules/gitlab/        rmgitlab: GitLab client, pipeline triggers, runner cleanup (scalable gitlab tests)
_tests/src/modules/gcp/           rmgcp: list Compute Engine instances by name fragment
_tests/src/modules/rmutils/       rmutils: external IP lookup, WriteTfvarsFile, AllItemsTrue
```

Fixtures call the module under test by **relative path** (`source = "../../../../gcp/gitlab-ci"`),
so a test always exercises the working tree, never a tag. `backend.tf` declares an empty backend
(`backend "gcs" {}` etc.) whose settings are injected by the Go code from `backendconfig`, and a
`required_providers` block with `source` only, so providers float to the newest the module allows.

The Go helper modules are wired with `replace` directives and the fake version `v1.0.0`:

```
require ( backendconfig v1.0.0  rmutils v1.0.0 )
replace ( backendconfig v1.0.0 => ../../backend-config  rmutils v1.0.0 => ../../modules/rmutils )
```

Adding a helper import to a test needs both the `require` and the `replace` line, or `go test`
stops with `updates to go.mod needed`. Module names are `backendconfig`, `gitlabapi`, `rmgitlab`,
`rmgcp`, `rmutils`; the directory names differ from the module names for some of them.

## What each test does

| `TERRATEST_DIR` | Flow | Asserts | Rough duration (from the sleeps and polls in the code; not measured) |
| --- | --- | --- | --- |
| `aws/gitlab-ci` | STS `AssumeRole` into `arn:aws:iam::971573726931:role/internal-gitlab-runners-deployment` (eu-west-2) using `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`, passes the temporary keys to the provider as variables, then the shared `gitlabapi.TestGitlabCi` flow | 2 registered, online runners; outputs present; empty plan | **does not currently build**, see below |
| `azure/gitlab-ci` | `gitlabapi.TestGitlabCi` flow in resource group `Terratest` with the pre-existing key vault `terratest`; creates ACR `rocketmakersgitlabci` | as above plus empty plan | 10-15 min |
| `gcp/gitlab-ci` | `gitlabapi.TestGitlabCi` flow in project `terraform-testing-317911`, `europe-west1-c` | as above plus service account outputs | 10-15 min |
| `azure/scalable-gitlab-ci` | apply into resource group `Terratest-Gitlab-Scalable-CI`; create a pipeline trigger on GitLab project `33153506`, run 5 pipelines on branch `develop` with variable `AZURE=true`; poll until at least 3 VMs exist; poll until all pipelines succeed; sleep 600 s for scale-down; empty plan; outputs; delete runners and trigger; destroy | VM count, pipeline success, plan | 30-45 min |
| `gcp/scalable-gitlab-ci` | same shape with `GCP=true`, `rmgcp.ListVMInstancesForProject` matching `auto-scale-`, 300 s waits; also enables project APIs through the `project-factory` module | as above | 25-40 min |
| `azure/scalable-github-ci` | apply into resource group `Terratest-Github-Scalable-CI` with `GH_RUNNER_API_TOKEN`; empty plan; destroy. `// TODO: Trigger jobs and verify they pass` | plan only | 15-20 min |
| `gcp/scalable-github-ci` | apply and destroy only. Same TODO | none | 10-15 min |

The shared static-runner flow in `gitlab-api/gitlab-api.go`: create the GitLab client from
`GITLAB_TOKEN` (fail fast if missing), `defer terraform.Destroy` (only when cleanup is on), delete
`.terraform.lock.hcl`, `InitAndApply`, sleep 10 s, list runners by the test's unique tag and require
exactly `instance_count` of them online, delete those runners from GitLab, read the outputs, require
`terraform plan` exit code 0 (no drift after apply), then the per-cloud `assertions` callback.

Registration tokens for the GitLab tests come from `data "gitlab_project" "runner_token"` for
project `33153506` inside the fixtures, so the `gitlab` provider needs `GITLAB_TOKEN` at plan time
as well.

## Environment and credentials

| Variable | Used by | Notes |
| --- | --- | --- |
| `TERRATEST_DIR` | `terratest.sh` | required; path under `_tests/src` |
| `GITLAB_TOKEN` | every GitLab test, the `gitlab` provider | API-scoped token; the tests register, list and delete runners and create pipeline triggers on project 33153506 |
| `GH_RUNNER_API_TOKEN` | both scalable-github tests | classic PAT with `repo` and `admin:repo_hook` (per `CONTRIBUTING.md`); passed to the module as `github_api_token` |
| `CLEANUP_AFTER_TESTS` | all | `false` skips destroy and GitLab runner cleanup so you can inspect or iterate; **you must destroy by hand afterwards** |
| `WRITE_VARS_FILE_AND_EXIT` | tests that call `rmutils.WriteTfvarsFile` (all except `aws/gitlab-ci` and `gcp/gitlab-ci`) | `true` writes `inputs.tfvars` into the fixture directory and calls `t.Skip` before init, for driving the fixture with the Terraform CLI |
| `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` | `aws/gitlab-ci` | base keys that may assume the deployment role above |
| `AWS_DEFAULT_REGION` | `terratest.sh` | defaulted to `eu-west-1` only so `init` works |
| `ARM_SUBSCRIPTION_ID` | Azure tests | `68bb123f-6027-4e99-8ab0-a01fb16cdd79`; log in with `pnpm az-login` (tenant `09e95bcb-...`); you need to be in the right Entra group |
| Google ADC | GCP tests | `gcloud auth application-default login`; project `terraform-testing-317911` is hard-coded in the fixtures |

Network: the Azure and GCP tests look up the machine's public IP (`rmutils.GetMachineExternalIPAddress`,
consensus of external services) and allow SSH only from `<ip>/32`; the AWS fixture and the GCP
fixture defaults hard-code the office IP `212.139.176.173/32`. `CONTRIBUTING.md` says to be on the
VPN or in the office. Provisioners connect over SSH from the test machine, so the machine's IP must
also be what the cloud sees.

## Fixed state backends and names

State lives in shared, fixed locations, so **two people running the same test at once will
collide** on state locks and on resource names.

| Cloud | Backend | Fixed names in fixtures / tests |
| --- | --- | --- |
| GCS | bucket `rocketmakers-terratest`, prefix `gcp/<module>` | project `terraform-testing-317911`; prefixes `gitlab-ci-terratest`, `glabscalableci`, `ghubscalableci` |
| Azure | storage account `rocketmakersterratest`, container `terraform-modules-testing`, resource group `Terratest`, key `<module>.tfstate` | resource groups `Terratest` (static runner, also holds key vault `terratest`), `Terratest-Gitlab-Scalable-CI`, `Terratest-Github-Scalable-CI`; ACR names `rocketmakers<prefix>` |
| S3 | bucket `rocketmakers-terratest`, region `eu-west-2`, key `gitlab-ci` | prefix `terratest` |

The scalable GitLab tests give each module a different `project_prefix` because Azure storage
account and GCP bucket names are global; the changelog records earlier clashes.

`_tests/config/azure/service-principal/` is not a test. It is a one-off configuration (its own
hard-coded `azurerm` backend, key `service-principal.tfstate`) that creates the
`terraform-modules-terratest-ci` service principal with `Owner` on the subscription and Microsoft
Graph `Application.ReadWrite.All`, which the old GitLab CI used to log in. No harness runs it and
nothing references it. Leave it alone unless you are changing CI authentication.

## Conventions to copy

- Newest pattern: `azure/scalable-github-ci` (terratest 0.48, Go 1.24 in `go.mod`, `WriteTfvarsFile`,
  lock-file deletion, `CLEANUP_AFTER_TESTS`). Older packages pin terratest 0.38-0.41 and `go 1.17`;
  they work with the Go 1.25 in `.tool-versions`, but do not "harmonise" them without running them.
- Every test uses a unique runner tag or label (e.g. `gcp-gitlab-ci-terratest`,
  `self-hosted-azure-scalable-github-ci-terratest`) so listing runners by tag finds only its own.
- `terraform.WithDefaultRetryableErrors` wraps the options everywhere.
- Values that vary per run (tag, count, IP) come from Go `Vars`; values that are fixed live in the
  fixture. The fixtures comment `# The following are provided via test code` at the boundary.
- `WriteTfvarsFile` writes every value quoted (`instance_count = "2"`); Terraform converts, but
  `terraform fmt -check` flags the file, hence the `pnpm format` note in the root `AGENTS.md`.

## Known problems and discrepancies

Recorded, not fixed.

- **`_tests/src/aws/gitlab-ci` does not build.** `gitlab-ci_test.go` imports `rmutils` without
  using it, and `go.mod` has no `require` or `replace` for it. `go vet ./...` stops with
  `go: updates to go.mod needed; to update it: go mod tidy`. Last real change was 2022-11-16. The
  AWS test was never part of the GitLab CI pipeline either. `CONTRIBUTING.md` still lists it as
  runnable.
- **`_tests/config/gcp/scalable-github-ci/backend.tf`** pins `google = "4.27.0"` (with a
  `// TODO: Upgrade to latest version`), breaking the unpinned-providers rule, and its provider block
  swaps the values (`region = var.gcp_project_zone`, `zone = var.gcp_project_region`). Its `main.tf`
  sets `github_organisation = "TODO: Set this once we are in github"`, so runners cannot register
  even though the apply succeeds. The Go test only applies and destroys, so none of this fails.
- **`_tests/config/gcp/scalable-gitlab-ci/outputs.tf`** reads `module.ci.service_account_email` and
  `module.ci.service_account_key`, which the module marks `[Deprecated]` in favour of the
  `orchestrator_*` outputs.
- **`_tests/src/azure/gitlab-ci`** declares `package gcpgitlabci` (copy-paste from the GCP test).
  Harmless; Go does not care, but do not let it mislead a search.
- **`_tests/src/gitlab-api/go.mod`** requires `gitlabclient v1.0.0`, which exists nowhere and has no
  `replace`. Consumers still build (`go vet` in `gcp/gitlab-ci` is clean) because Go 1.17 module graph
  pruning never needs it. Do not add a `replace` for it; remove the line only with a test run.
- `go.mod` files declare `go 1.17` or `go 1.24.2`; `.tool-versions` installs 1.25.5. Fine today.
- The scalable GitLab tests drive branch `develop` of the external GitLab project 33153506. That is
  a different repository; this repository's `develop` branch is a legacy branch.
- `CONTRIBUTING.md` says test authentication is "to be reviewed and improved". Nothing in this
  repository documents where the GitLab token, GitHub token or AWS base keys are kept beyond the
  link to the `internal-gitlab-runners` secrets file.
- `_build/run/_shell-scripts/terratest.sh` on Linux installs into `/usr/local/bin`, an assumption
  from the old CI container image.
