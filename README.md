# Terraform rocketmakers modules

This is a set of terraform modules that can be used in other projects to help speed up management of infrastructure via terraform.

- [Contributing Guide](./CONTRIBUTING.md)

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
