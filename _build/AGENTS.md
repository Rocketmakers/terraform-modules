# `_build/`: repository tooling

`_build/run` is the only package in the pnpm workspace (`pnpm-workspace.yaml`), named
`@repo/typescript-scripts-core`. Its scripts are TypeScript run with `ts-node` (TypeScript 4.5,
`strict`), built on `@rocketmakers/shell-commands` (shell, git, terraform and prerequisite helpers)
and `@rocketmakers/log`. Turbo (`turbo.json` at the root) maps each task to a script here; all tasks
depend on `setup-dependencies` and none are cached. Commit scope: `scripts`.

| Turbo task | Script | What it does |
| --- | --- | --- |
| `setup-dependencies` | `_shell-scripts/setup-dependencies.sh` | `asdf plugin add` / `asdf install` for terraform, terraform-docs and github-cli, every command `\|\| true` |
| `validate` | `validate.ts` -> `validate/validate.ts` | `terraform init` + `terraform validate -json` in every module directory |
| `generate-docs` | `readmes.ts` -> `readme/readme.ts` | regenerate every `README.md` next to a `readme.tpl` |
| `release-prepare` | `releasePrepare.ts` | bump version, changelog, READMEs, create `release/<version>` |
| `release-finalise` | `releaseFinalise.ts` -> `release/githubCli.ts` | commit, push, open the release PR |
| `terratest` | `_shell-scripts/terratest.sh` | run one Go test package (`TERRATEST_DIR` required) |

Common to every TypeScript script:

- Arguments are parsed with `Args.match`; pass them after `--` when going through turbo:
  `pnpm turbo validate -- --directory=gcp`. `--help` prints them. `--log` (or the `LOG_LEVEL`
  environment variable, which CI sets from a repository variable) controls verbosity:
  `trace|debug|info|warn|error|fatal`.
- `Prerequisites.check()` runs first and fails if a registered command is missing from `PATH`
  (`terraform` always; `terraform-docs` for docs and release; `gh` for release). It only checks
  presence, not version. The `.tool-versions` shims from asdf are what CI uses.
- `RepositoryPaths.resolve()` in `paths/repositoryPaths.ts` is `_build/run/../..`; scripts work
  from any current directory.
- Exit code is `-1` (255) on an unhandled error, `1` when validation reports failed modules.

## validate

`validate.ts` iterates the parent directories `aws`, `azure`, `gcp`, `shared` (or the single
`--directory`), and treats **every immediate subdirectory** as a module. For each one it:

1. Writes a temporary `providers.tf` for `aws` (`provider "aws" { region = "eu-west-1" }`) and
   `azure` (`provider "azurerm" { subscription_id = "68bb..." features {} }`). The AWS provider
   needs a region and azurerm needs a `features {}` block before `init` will succeed, and
   reusable modules must not carry provider blocks themselves. GCP and shared need nothing.
2. Runs `terraform init` (via `Terraform.init`, plain `init` with no flags) and then
   `terraform validate -json`.
3. Fails the module if `valid` is false **or `error_count > 0` or `warning_count > 0`**, re-running
   plain `terraform validate` so the human-readable message appears in the log.
4. Deletes the temporary `providers.tf` and the module's `.terraform.lock.hcl` in a `finally`.
   `.terraform/` is left in place.

Consequences:

- Deprecation warnings fail validation. When a provider upgrade introduces one, the fix is in the
  module, not in the validator.
- A new parent directory needs adding to the list in `validate.ts` and, if its provider needs
  configuration to initialise, a writer in `validate/providers.ts`.
- Do not put a real `providers.tf` in a module. It would be overwritten and deleted for `aws` and
  `azure`, and it is gitignored (`aws/**/providers.tf` and friends in `.gitignore`).
- Every module is initialised against the newest provider its lower bound allows, so a new
  provider major release can turn `main` red without any commit. That is by design (see the "no
  upper limits" rule in `README.md`) and the response is a module fix, usually under the `upgrade`
  or `fix` type.
- The run takes about a minute with a warm plugin cache and needs network access.

## generate-docs

`readme/readme.ts` walks every directory under the repository root recursively, skipping only
directories named `node_modules` (so it also descends into `.git`, `.terraform` and `_tests`;
slow but harmless). Any directory containing a `readme.tpl` gets its `README.md` rewritten:

- `terraform-docs json ./` supplies inputs, outputs, providers and requirements.
- `preprocessModule` splits inputs into required (`required: true`) and optional, sorts everything by
  name, and JSON-stringifies optional defaults with surrounding double quotes stripped.
- The root `readme.core.tpl` renders the tables; the `Newlines` helper turns `\n` into `<br />`.
  Triple-stash `{{{ }}}` everywhere, so nothing is HTML-escaped.
- The module's `readme.tpl` is rendered with `coreContent` and `version` (the root `package.json`
  version) and written as `README.md`.

Rules that follow: edit `readme.tpl` or the `description` fields, never `README.md`; regenerate and
commit the README with the same change; expect no version diff outside a release. `terraform-docs`
reads `versions.tf` for the Requirements and Providers tables, so the two `shared/` modules (no
`versions.tf`) have neither table.

## release-prepare and release-finalise

`releasePrepare.ts` (`--as=major|minor|patch`, mandatory):

1. `git checkout main` and `git pull`, both erroring if the working tree is dirty or `main` does not
   track a remote.
2. `pnpm exec commit-and-tag-version --release-as <as>`. Its config comes from `.versionrc.js` ->
   `.commit-config.js` (`standardVersion`): changelog sections per type, `skip.tag` and
   `skip.commit` both true, so it only edits `package.json` and `CHANGELOG.md`.
3. Regenerates every README with the new version.
4. `git checkout -b release/<version>`.

Nothing is committed. Review and, if needed, hand-edit `CHANGELOG.md` at this point; it is the one
moment editing it is expected.

`releaseFinalise.ts`:

1. Reads the version from `package.json` and refuses unless the current branch is exactly
   `release/<version>`.
2. `Git.preventHuskyHooks()` sets `HUSKY=0` (and the legacy `HUSKY_SKIP_HOOKS=1`) so the
   `prepare-commit-msg` hook does not open commitizen.
3. `git add package.json CHANGELOG.md **/README.md` and commits `release: Changelog for v<version>`.
   Anything else you changed on the branch is left unstaged.
4. `git push origin release/<version> --set-upstream`.
5. `gh pr create --title "Release <version>" --base main` (needs an authenticated `gh`).

From there `.github/workflows/create_tag.yml` takes over when the PR is merged (see the root
`AGENTS.md`). The `release/*` PR skips the Validate and Docs jobs on purpose.

The `release` commit type is hidden from the changelog; the `--release-as` flag means the bump is
always the size the human chose, regardless of `BREAKING CHANGE:` footers in the commits.

## terratest.sh

- Exits early unless `TERRATEST_DIR` is set (e.g. `gcp/gitlab-ci`); the Go package is
  `_tests/src/$TERRATEST_DIR`.
- Installs golang through asdf, then `go test -timeout 60m` in that directory.
- On macOS that is all. On Linux it also downloads `terratest_log_parser` (`TERRATEST_LOG_PARSER_VERSION`,
  default `v0.40.24`; `ARCHITECTURE`, default `linux_amd64`) into `/usr/local/bin`, tees the test
  output to `test_output.log` and produces per-test logs and JUnit XML in the package directory.
  That path was written for the old GitLab CI image and assumes write access to `/usr/local/bin`.
- Defaults `CLEANUP_AFTER_TESTS=true`, `WRITE_VARS_FILE_AND_EXIT=false` and
  `AWS_DEFAULT_REGION=eu-west-1` (so `terraform init` of the AWS fixture works without a region in
  the provider block). Everything the tests need is in `_tests/AGENTS.md`.

## Editing the tooling

- `tsconfig.json` is strict with `noUnusedLocals` and `noUnusedParameters`; `ts-node` type-checks on
  run, so an unused import fails the task at start-up.
- The `~/*` path alias in `tsconfig.json` is declared but not used.
- `@types/node` is pinned to 20.x while `.tool-versions` runs Node 24; it has not caused trouble.
- Formatting for TypeScript and JavaScript follows `.prettierrc.yaml` (single quotes, width 120),
  but nothing runs Prettier automatically.
- Commit scope `scripts`; a change that alters what CI runs is `ci`.
