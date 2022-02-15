# Terraform rocketmakers modules

## What makes a good shared module?

### A good shared module should

- Actually be useful for more than one project
- Add value
  - No point just wrapping a single resource or doing something very basic
- Have a single responsibility
  - Improves reusability
  - If it's difficult to name the module then it might be doing too much
  - Avoid modules like `core`
- Have no hard-coded values
  - Use variables for everything
  - If it's hard-coded then it can't be changed by the consuming project
  - If there is a sensible default then give the variable a default value but it's often best to make the consumer consider the value
- Have automated tests
  - Against all supported terraform versions
  - Against all supported major provider versions
  - Include tests for destroying the module
- Be documented
  - A brief description of its purpose
  - Describe all variables, including default values
  - Required terraform and provider versions
- Have no deprecation warnings from `terraform validate` when released
  - Deprecation warnings are there for a reason and removing them early will make upgrades a lot smoother
- Only set lower limits for requirements (no upper limits)
  - Terraform version
  - Provider versions
- Not be too restrictive when there is no "typical" configuration for a set of resources
  - Some resources (e.g. cloud database instances) have a large number of configuration options so a reusable module can be too restrictive in practice and experience has shown us that it's best to allow projects to configure databases without being hamstring by an opinionated module
  - In this case a better alternative would be a set of example projects which could be used as a starting point for different scenarios
- Manage your infrastructure, not your code
  - The terraform plan/apply workflow is a bit cumbersome when it comes to code deployments
  - We make some exceptions for some helm charts because terraform fits pretty well for code that doesn't need to change very often, e.g.
    - ingress
    - monitoring
  - Cloud functions (or similar) are another fuzzy exception where we may want to use terraform to configure the cloud function but then use other tools to subsequently update the code associated with a function

## Available modules

### AWS

- gitlab-ci

### Azure

- gitlab-ci

### GCP

- gitlab-ci

## Local development of modules

### Getting started

We use `asdf` to manage the terraform version. See [Notion](https://www.notion.so/Managing-CLI-tool-versions-asdf-386a27d8e9e54c44ab3624bf0de6ff09) for a guide on how to install it.

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

## Documentation

We use [terraform-docs](https://github.com/terraform-docs/terraform-docs) along with custom scripts to help generate our module documentation. This will need to be installed using the following

```
brew install terraform-docs
```

You can then generate documentation using `make generate-docs` at the root.

## Release process

This relies on the following tools:

- `commitizen`: Enforcing commit message conventions
- `cz-conventional-changelog`: Maintaining a changelog based on commit message conventions

### Install commitizen dependencies

```bash
npm i
```

### Pull the latest master

```bash
git checkout master
git pull
```

### Decide on the NEW_VERSION_CODE

```
# Format
export NEW_VERSION_CODE=<major>.<minor>.<patch>
```

### Create a release

```bash
# Bump the version number - this will also update the changelog thanks to a "postversion" npm script
npm version $NEW_VERSION_CODE

# Commit the version bump and changelog (commitizen will step in again here)
git add -A
git commit -m ""
git push origin master

# Tag and push the release
git tag v$NEW_VERSION_CODE
git push --tags
```

## Consuming the modules

You can consume the module by specifying a source in the following format: `git::ssh://git@gitlab.com/rocketmakers/infrastructure/terraform-modules.git//<PATH_TO_MODULE>?ref=<TAG_VERSION>`

```terraform
module "ci_box" {
  source = "git::ssh://git@gitlab.com/rocketmakers/infrastructure/terraform-modules.git//gcp/ci-box?ref=v1.0.0"

  instance_count             = var.instance_count
  zones                      = var.zones
  project_id                 = var.project_id
  gcr_bucket_names           = var.gcr_bucket_names
  project_prefix             = var.project_prefix
  cidr_ranges                = module.trusted_ips.cidrs
  runner_registration_token  = var.runner_registration_token
  machine_type               = var.machine_type
  runner_tags                = var.runner_tags
  gitlab_runner_concurrency  = var.runner_concurrency
  gitlab_runner_docker_image = var.runner_docker_image
  gitlab_runner_locked       = var.runner_locked
}
```
