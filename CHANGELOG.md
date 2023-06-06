# Changelog

All notable changes to this project will be documented in this file. See [standard-version](https://github.com/conventional-changelog/standard-version) for commit guidelines.

## [2.1.0](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/compare/v2.0.0...v2.1.0) (2023-06-06)

### Features

- **azure-gitlab-ci:** Add Azure scalable CI runner ([3593be0](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/3593be09f2037cf32443c4c61fd76f95b90943a9))
- Prune docker images daily on CI runners ([6a6f0b6](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/6a6f0b6bf8feb6be2e0d179a44726aff619d2dc7))
- Upgrade to Ubuntu 20 on Azure/GCP CI runners ([8cbc33d](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/8cbc33da361309fa765b967677cd1958281838d7))

## [2.0.0](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/compare/v1.1.2...v2.0.0) (2023-01-11)

### ⚠ BREAKING CHANGES

- **azure-gitlab-ci:** Updating azure_virtual_machine resource to linux_virtual_machine will destroy and rebuild the runner

### Features

- **azure-gitlab-ci:** Updated azure_virtual_machine resource to linux_virtual_machine ([6d215e5](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/6d215e528d8fe7385e08d1602294a44d36f8a026))
- **gcp-gitlab-ci:** Updated scalable runner outputs to be specific in orchestrator ([a9c603f](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/a9c603f4db1796a0cf5cab292f164809f9fe2dd5))
- **gcp-gitlab-ci:** Updated scalable runner to expose runner service account ([c179de6](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/c179de6b133f8a3ca414628f34184362440afc49))

### [1.1.2](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/compare/v1.1.1...v1.1.2) (2022-08-09)

### Features

- **azure-gitlab-ci:** Exposed ids of underlying service principals ([19f1834](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/19f18341421526abbcdb6786d061eaed4a603e42))

### Bug Fixes

- **gcp-gitlab-ci:** Start test runner with subnetwork, allow concurrency to be set ([9b1b8c4](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/9b1b8c429be9fdffd77b7ad907fd1c66b8d53c60))
- **gcp-gitlab-ci:** Switch gcr bucket for cache bucket so ci has permission for both ([09152e5](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/09152e5c94b7910c40291648e2663a473e7b8329))
- **gcp-gitlab-ci:** Set one name instead of names in shared ci, set gitlab orchestrator concurrency ([0a51696](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/0a516966c80661f00c0ad0d244586ed960b87b70))

### [1.1.1](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/compare/v1.1.0...v1.1.1) (2022-07-28)

### Bug Fixes

- **gcp-gitlab-ci:** Fix the outputs in scalable-gitlab-ci ([212f7f6](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/212f7f657250fbad380b43d18ee0c90fbc764779))
- **gcp-gitlab-ci:** Include project ID in scalable runner service account roles ([dbb5a04](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/dbb5a044e614595f8c243cd16cdaa7824dd474da))

## [1.1.0](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/compare/v1.0.1...v1.1.0) (2022-07-27)

### Features

- **gcp-gitlab-ci:** New scalable GCP runner (see [merge request](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/-/merge_requests/25))

### [1.0.1](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/compare/v1.0.0...v1.0.1) (2022-05-10)

### Features

- **gcp-gitlab-ci:** Add GCP service account ID and email to outputs ([d8dbdca](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/d8dbdca798f2bb7c6078ffdd8ead8d46cd162401))

### Bug Fixes

- **azure-gitlab-ci:** Use uppercase for azure config ([f9a4a0e](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/f9a4a0e276968c6121a2f981a3c522a0d7545358))

### Tests

- **terratest:** Add messages to test assertions ([c12762a](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/c12762a9f986daa054b5e77d5b9381421602e973))
- **terratest:** Check for planned changes after applying ([e4ff32a](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/e4ff32a16fe17f927bb4b3f82edeb4758195e436))

## 1.0.0 (2022-03-03)

Working versions of `gitlab-ci` in `aws`, `azure` and `gcp`.
