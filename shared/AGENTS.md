# `shared/`: provisioning-command modules

Two modules with no resources, no data sources and no `versions.tf`. Each turns its variables into
lists of shell commands in `locals` and exposes them as outputs. The cloud modules pull them in by
**relative path** (`source = "../../shared/ci"`), so a consumer pinning a tag gets the matching
`shared/` code automatically, and any change here is a change to every module that uses it.
Commit scope: `shared-ci`. Say which cloud modules are affected in the commit subject, because the
changelog reader only sees `shared-ci`.

Validation still runs `terraform init` and `terraform validate` on both; with no providers that is
quick. Their READMEs have no Requirements or Providers tables because there is no `versions.tf`.

| Module | Consumers | Executor | Output shape |
| --- | --- | --- | --- |
| `shared/ci` | `aws/gitlab-ci`, `azure/gitlab-ci`, `gcp/gitlab-ci` | `docker` with the host socket mounted (docker-in-docker by socket binding) | `provisioner_commands`: a list **per runner name**, index-aligned with the consumer's `count.index` |
| `shared/ci-provisioner-commands` | `azure/scalable-gitlab-ci`, `gcp/scalable-gitlab-ci` | `docker+machine` | separate lists: `init_docker`, `init_docker_machine`, `init_gitlab_runner`, `register_gitlab_runner`, plus `config_template_path` |

## `shared/ci`

For each entry in `names` it emits the same sequence: download the `gitlab-runner` binary from
`https://gitlab-runner-downloads.s3.amazonaws.com/<version>/binaries/gitlab-runner-linux-amd64`,
`chmod`, install Docker with `curl -sSL https://get.docker.com/ | sh`, add `username` to the
`docker` group, create the `gitlab-runner` system user, `gitlab-runner install` + `start`, add a cron
line running `docker system prune -f -a --volumes` on `docker_prune_cron_schedule`, `gitlab-runner
register --non-interactive --url https://gitlab.com ... --executor docker --docker-volumes
/var/run/docker.sock:/var/run/docker.sock ...`, and finally `sed` the `concurrent = 1` line in
`/etc/gitlab-runner/config.toml` to `gitlab_runner_concurrency` (the register command cannot set it).

Things to know:

- `gitlab_token` is passed through `chomp()` because registration tokens read from files or data
  sources often carry a trailing newline.
- `gitlab_runner_version` defaults to `latest` in every consumer; the S3 URL accepts `latest` or a
  tag like `v16.0.0`.
- The consumers feed `provisioner_commands[count.index]` straight into a `remote-exec` `inline`
  block on the VM resource. **Provisioners only run at create time and are not tracked in state**, so
  changing a command here produces no plan diff and no re-provisioning on existing runners. A
  consumer has to `terraform taint` (the module READMEs describe this) or otherwise replace the VM
  to pick the change up. Document that in the changelog subject when you change a command.
- The URL `https://gitlab.com`, the S3 download host, the `docker:stable` default image (set in the
  consumers) and the `gitlab-runner` user are hard-coded. They are existing exceptions to the "no
  hard-coded values" rule; do not add more without a variable.

## `shared/ci-provisioner-commands`

Same install steps, split so the consumer can interleave its own commands, plus:

- Downloads GitLab's fork of docker-machine (`docker_machine_version`, default
  `v0.16.2-gitlab.35`) from `gitlab-docker-machine-downloads.s3.amazonaws.com`. Upstream
  docker-machine is unmaintained; the GitLab fork is what the `docker+machine` executor needs.
- Registers with `--executor docker+machine` and `--template-config <config_template_path>`
  (default `/tmp/test-config.template.toml`). The consumer writes that file with a `file`
  provisioner **before** running `register_gitlab_runner`; it holds the `[runners.machine]` and
  `[runners.cache]` sections (driver options, idle counts, cache bucket, credentials).
- Sets `concurrent` in `config.toml` to `gitlab_orchestrator_concurrency`, which both consumers wire
  to `gitlab_max_runners`.
- Takes a single `name`, not `names`: there is one orchestrator VM.

The consumers run, in order: `init_docker`, `init_docker_machine`, a `docker-machine create ...
test-runner` followed by `docker-machine rm -y test-runner` (this generates the docker-machine SSH
keys once, so the first burst of concurrent jobs does not race to create them; the comment in each
consumer's `main.tf` explains it), `init_gitlab_runner`, then `register_gitlab_runner`. The GCP
consumer moves a service-account key file into place between the last two.

## Inconsistencies to keep, not fix

- `gitlab_token` is `sensitive = true` in `shared/ci` but not in `shared/ci-provisioner-commands`.
  Making it sensitive changes how consumers must reference it (`nonsensitive()` is already used
  around other secrets in the scalable modules); treat it as a deliberate change with a changelog
  line if you do it.
- `shared/ci` has `docker_prune_cron_schedule`; the scalable variant does not, because runner VMs
  are disposable there.
- Variable naming differs from the consumers on purpose: consumers expose
  `runner_registration_token` and map it to `gitlab_token` here (static modules), while the scalable
  modules expose `gitlab_token` directly.

## Discrepancies between docs and code

- `shared/ci-provisioner-commands/readme.tpl` "Example Use Cases" passes `names`,
  `gitlab_runner_concurrency` and `docker_prune_cron_schedule`, none of which are inputs of this
  module, and omits `name` and `gitlab_orchestrator_concurrency`. The example is a copy of
  `shared/ci`'s. The fix belongs in `readme.tpl` (then regenerate), never in `README.md`.
- `shared/ci-provisioner-commands/variables.tf` declares `config_template_path` with a default but
  no `type` and no `description`, so the generated README has an empty description cell. `README.md`
  at the root says every variable is described.
- `shared/ci/outputs.tf` says "privisioning" (typo) in the output description; it is reproduced in
  the generated README. Fix it in `outputs.tf` and regenerate if you are touching the file anyway.
