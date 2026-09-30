# Contributing to Rocketmakers terraform modules

- [Contributing to Rocketmakers terraform modules](#contributing-to-rocketmakers-terraform-modules)
  - [Getting started](#getting-started)
  - [Running tests](#running-tests)
  - [Documentation](#documentation)
  - [Branching strategy](#branching-strategy)
  - [Release process](#release-process)
    - [Prepare release](#prepare-release)
    - [Finalise release](#finalise-release)

## Getting started

We use `asdf` to manage tool versions (see `.tool-versions`). See [Notion](https://www.notion.so/Managing-CLI-tool-versions-asdf-386a27d8e9e54c44ab3624bf0de6ff09) for a guide on how to install it.

Install the tools and node dependencies:

```bash
asdf install
pnpm install
```

Scripts are run with [turbo](https://turbo.build), e.g. validate all modules (or pass `-- --directory=gcp` to target one parent directory) and check formatting:

```bash
pnpm turbo --filter @repo/typescript-scripts-core validate
pnpm format # or pnpm format-fix
```

You can test any of these modules by using a **relative path** to the module directory (absolute path will not work) as the `source` in your terraform project, like this:

```terraform
module ci_box {
  # Remember not to commit this relative path to your project - it's just for local development 🤓
  source = "../../../../../terraform-modules/gcp/ci-box"
  ...
}
```

If you have any issues then try removing the `.terraform` directory and re-initializing in both your project and in this repo:

```bash
# In your project and in the module of this repository that you're referencing
rm -rf .terraform
terraform init
```

## Running tests

You will need to be on the VPN or in the Rocketmakers office.

**Authentication to be reviewed and improved...**

Get AWS keys from [internal-gitlab-runners/secrets/secrets.yaml](https://gitlab.com/rocketmakers/internal-gitlab-runners/-/blob/master/secrets/secrets.yaml)

```bash
# For gitlab tests
export GITLAB_TOKEN=_token_with_api_access_

# For github tests
export GH_RUNNER_API_TOKEN=_classic_token_with_repo_and_admin:repo_hook_access_

# Optionally prevent resources from being destroyed at the end of tests, so feedback is quicker during development
export CLEANUP_AFTER_TESTS=false

# A file named inputs.tfvars will be written to the config directory for the test being run
# e.g. _tests/config/gcp/scalable-gitlab-ci/inputs.tfvars
# This file is very useful for debugging using the terraform CLI
# If you just want this file to be written without running the test then you can use WRITE_VARS_FILE_AND_EXIT
export WRITE_VARS_FILE_AND_EXIT=true

# aws
export AWS_SECRET_ACCESS_KEY=_key_
export AWS_ACCESS_KEY_ID=_access_key_
TERRATEST_DIR=aws/gitlab-ci pnpm turbo --filter @repo/typescript-scripts-core terratest

# azure (you'll need to be added to a group first)
export ARM_SUBSCRIPTION_ID=68bb123f-6027-4e99-8ab0-a01fb16cdd79
pnpm az-login
TERRATEST_DIR=azure/gitlab-ci pnpm turbo --filter @repo/typescript-scripts-core terratest

# gcp
gcloud auth application-default login
TERRATEST_DIR=gcp/gitlab-ci pnpm turbo --filter @repo/typescript-scripts-core terratest
```

## Documentation

We use [terraform-docs](https://github.com/terraform-docs/terraform-docs) along with custom scripts to help generate our module documentation.

Run the following to install the tools and generate documentation:

```bash
pnpm turbo --filter @repo/typescript-scripts-core generate-docs
```

## Branching strategy

We're using feature branches targeting `main`.

Commit messages follow the conventions enforced by the following tools, which are also used to generate the changelog:

- `commitizen`: Enforcing commit message conventions
- `commit-and-tag-version`: Maintaining a changelog based on commit message conventions

## Release process

Releasing requires the [GitHub CLI](https://cli.github.com) (`gh`) to be installed and authenticated. Make sure your local git repo is clean before starting.

### Prepare release

First prepare a release:

```bash
# --as can be 'major', 'minor' or 'patch'
pnpm turbo --filter @repo/typescript-scripts-core release-prepare -- --as=minor
```

This will

- Check out and pull `main`
- Bump the `package.json` version to the desired version
- Update `CHANGELOG.md`
- Regenerate the module READMEs with the new version
- Create a new release branch (`release/<version>`)

### Finalise release

Review the changelog, editing if necessary, then finalise the release:

```bash
pnpm turbo --filter @repo/typescript-scripts-core release-finalise
```

This will

- Check you are on `release/<version>` for the version in `package.json`
- Commit the version bump, READMEs and changelog
- Push the release branch
- Create a pull request from the release branch to `main`

Once you are happy, merge the pull request. This will tag the release with the new version, create a GitHub release and send a Slack notification. Once the tag has been created, the new version is officially released and should be referenced via git tag.

The tag is only created when the branch is `release/<version>` for the version in `package.json`. Validate and Docs are not rerun on the release pull request; its changes have already passed them on their feature pull requests and on `main`.
