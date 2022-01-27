## Breaking changes since restarting this repository

This changelog will be generated for the first release but here are the breaking changes since moving from the original [terraform-rocketmakers-modules](https://gitlab.com/rocketmakers/infrastructure/terraform-rocketmakers-modules) repository.

### azure/gitlab-ci

- The Rocketmakers HQ IP address is no longer automatically included in the IP whitelist so if you need SSH access to the runner then you'll need to include it via the `whitelist` variable.

### gcp/gitlab-ci

- The service account created for use by the runner instances does not have a key generated because it should not be needed.
