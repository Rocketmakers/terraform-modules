# Changelog

All notable changes to this project will be documented in this file. See [standard-version](https://github.com/conventional-changelog/standard-version) for commit guidelines.

## [1.1.0](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/compare/v1.0.1...v1.1.0) (2022-07-27)


### Features

* **gcp-gitlab-ci:** Added job to test scalable CI (see [merge request](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/-/merge_requests/27))
* **gcp-gitlab-ci:** New scalable GCP runner (see [merge request](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/-/merge_requests/25))


### [1.0.1](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/compare/v1.0.0...v1.0.1) (2022-05-10)


### Features

* **gcp-gitlab-ci:** Add GCP service account ID and email to outputs ([d8dbdca](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/d8dbdca798f2bb7c6078ffdd8ead8d46cd162401))


### Bug Fixes

* **azure-gitlab-ci:** Use uppercase for azure config ([f9a4a0e](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/f9a4a0e276968c6121a2f981a3c522a0d7545358))


### Tests

* **terratest:** Add messages to test assertions ([c12762a](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/c12762a9f986daa054b5e77d5b9381421602e973))
* **terratest:** Check for planned changes after applying ([e4ff32a](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/e4ff32a16fe17f927bb4b3f82edeb4758195e436))

## 1.0.0 (2022-03-03)

Working versions of `gitlab-ci` in `aws`, `azure` and `gcp`.
