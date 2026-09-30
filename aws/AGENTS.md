# `aws/`: notes for agents

One module, `aws/gitlab-ci`: one or more EC2 instances registered as GitLab runners with the
`docker` executor, provisioned by `shared/ci`. Commit scope: `aws-gitlab-ci`. There is no scalable
AWS variant and no GitHub variant.

## How `aws/gitlab-ci` is put together

- Creates its own network: a VPC hard-coded to `10.0.0.0/16`, one subnet per availability zone
  (`10.0.<n>.0/24`), an internet gateway, a main route table with a default route, a security group
  allowing SSH from `ssh_cidr_ranges` and all egress, one ENI and one Elastic IP per instance.
  `availability_zones` are **suffix letters** (`["a", "b"]`) appended to the current region from
  `data "aws_region" "current"`; instances round-robin across them. Subnet count is
  `min(instance_count, length(availability_zones))`.
- Generates an RSA 4096 SSH key with the `tls` provider, registers it as an `aws_key_pair` named
  `<project_prefix>-ci-ssh`, and uses it for the `remote-exec` provisioner. The private key is in
  state and exposed as the `private_key` output (`sensitive`).
- Resolves the AMI with `data "aws_ami"` from `image_config` filters; the default is Canonical's
  **Ubuntu 18.04 (bionic)**, which is end-of-life. Changing the default filter would replace every
  consumer's instances on the next apply (breaking); consumers can override `image_config` today.
  `image_config.default_username` must match the image (`ubuntu` for Canonical images).
- Root volume is `gp3`, `disk_size` GB. Instance type default `t2.micro`.
- `remote-exec` runs `module.shared_ci.provisioner_commands[count.index]` over SSH to the EIP with
  a 500 s connection timeout. Provisioner changes do not re-run on existing instances (see
  `shared/AGENTS.md`).
- Tags: `tags` is `map(any)` merged with a `Name` tag on instances.

## Validation

`_build/run/validate/providers.ts` writes a temporary `provider "aws" { region = "eu-west-1" }`
into the module during `pnpm turbo validate` because the AWS provider will not initialise without a
region. It is deleted afterwards and gitignored (`aws/**/providers.tf`). Do not add a provider block
to the module.

## Version constraints

`versions.tf`: `required_version >= 1.1.6`, `aws >= 4.1.0, < 6.0.0`, `tls >= 3.1.0`.

The `< 6.0.0` upper bound on `aws` contradicts the "only set lower limits" rule in the root
`README.md`. It is the only upper bound in the repository. Removing it is a real change: provider
6.x has breaking changes and validation runs against the newest allowed version, so lifting the cap
means validating and testing against 6.x first. Record the decision in the changelog either way.

## Testing

`_tests/src/aws/gitlab-ci` assumes the role
`arn:aws:iam::971573726931:role/internal-gitlab-runners-deployment` in `eu-west-2` from base
credentials and passes the temporary keys into the fixture's provider block as variables, unlike
the Azure and GCP fixtures which rely on ambient credentials. **The package does not currently
compile** (missing `rmutils` module wiring); details in `_tests/AGENTS.md`. State is in S3 bucket
`rocketmakers-terratest`, key `gitlab-ci`. The fixture hard-codes the office IP for SSH.

## Docs

`readme.tpl` example passes `availability_zones = var.availability_zone` (singular variable name on
the consumer side; fine) and does not show `project_prefix` being derived; nothing wrong, just terse.
The "Rebuilding CI box" section names `module.gitlab-ci.aws_instance.ci`; the actual resource is
`aws_instance.ci`, so the address is right for a module block called `gitlab-ci`.
