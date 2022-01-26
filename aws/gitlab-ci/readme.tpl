# aws gitlab-ci

Creates an EC2 instance in a VPC and configures the instance as a gitlab runner.

{{{ this.coreContent }}}

## Example Use Cases

```
module ci-box {
  source = "git::ssh://git@gitlab.com/rocketmakers/infrastructure/terraform-modules.git//aws/gitlab-ci"

  availability_zone          = var.availability_zone
  encrypted_gitlab_token     = var.encrypted_gitlab_token
  instance_type              = var.instance_type
  project_prefix             = local.project_prefix
  cidr_ranges                = local.cidr_ranges
  runner_tags                = var.runner_tags
  gitlab_runner_version      = var.gitlab_runner_version
  gitlab_runner_concurrency  = var.runner_concurrency
  gitlab_runner_docker_image = var.runner_docker_image
  gitlab_runner_locked       = var.runner_locked
  docker_prune_cron_schedule = var.docker_prune_cron_schedule
}
```

### Rebuilding CI box

Terraform has a concept of tainting resources to force a rebuild. If there is a problem with our CI box, we can `taint` it to force a rebuild. To do this, firstly identify the resource to taint by running the following command in the folder that contains your terraform state:

```bash
terraform state list
```

Pick the resource you want to taint (most likely `module.gitlab-ci.aws_instance.ci`):

```bash
terraform taint <resource_in_state>
```

Then, reapply the terraform and the resource (and any dependencies) will be rebuilt.

### Encrypting the gitlab token using AWS KMS

To use the aws kms, you will need to [configure the credentials](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html).

Run the below commands replacing ${TOKEN} and ${key-id} to generate the encrypted token to use with this module.
```bash
echo -n '${TOKEN}' > plaintext-token
aws kms encrypt --key-id ${key-id} --plaintext fileb://plaintext-token --encryption-context usage=gitlab-token --output text --query CiphertextBlob
rm plaintext-token
```