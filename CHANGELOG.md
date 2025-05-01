# Changelog

All notable changes to this project will be documented in this file. See [standard-version](https://github.com/conventional-changelog/standard-version) for commit guidelines.

## [3.2.0](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/compare/v3.0.0...v3.2.0) (2025-05-01)


### ⚠ BREAKING CHANGES

* **azure-gitlab-ci:** Minimum terraform version is now 1.4

### Features

* **azure-github-ci:** Exposed cooldown mode for autoscaling minimum/maximum instances ([b522a30](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/b522a3022f39f08cf71582ae83536faaa85572c0))
* **azure-github-ci:** Exposed CPU autoscaling thresholds ([c3297da](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/c3297da8bb326744a9db7d4036fddbf707f1514e))
* **azure-gitlab-ci:** Updated static CI runner to expose subnet id ([3472ba5](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/3472ba566fa320a5213322af76b1a127043aa3b3))
* **gcp-github-ci:** Exposed autoscaling threshold as a variable ([a6ee152](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/a6ee152b9647170323c09bafcfe525bcb2f87a34))
* **gcp-github-ci:** Exposed cooldown mode for autoscaling instances ([25c498e](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/25c498e89146953799abcab4845e7e91ce111268))
* **gcp-github-ci:** Fixed registration issues with GCP runner ([458a773](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/458a7737dd05313a2d11eb3ffb30846fb6ccdee1))
* **gcp-github-ci:** Updated to make subnetwork IP CIDR configurable ([4801af9](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/4801af9b165c1c9913221990edb3b3c665eac214))
* **gcp-gitlab-ci:** Support not cleaning up after tests and don't use deprecated container registry resource ([46bd869](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/46bd869cf856ff52a23a1ceba6e113e16c90777f))
* **scalabale-github-ci:** Added ability to configure disk size ([58a6ceb](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/58a6ceb36568f19c35ecafb750140c30950eaca4))
* **scalable-github-ci:** Removed a lot of default roles ([fa24837](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/fa2483793bdf4704f4fd846964d57fcfab380af9))
* **scalable-github-ci:** Updated to have service account roles configurable ([2237887](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/22378873e089615c5b8947b12f9ffe54dac20c06))


### Bug Fixes

* **azure-github-ci:** Added missing outputs required to lock down resources ([240cc55](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/240cc55472f88b7c1554b0738ccf83c999872a8c))
* **azure-gitlab-ci:** Upgrade terraform, docker-machine and gitlab-runner versions ([4c50edc](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/4c50edc21567bb70be226e8656d464798e1bc49a))


### Other Changes

* **config:** Use the CI docker image from github rather than dockerhub ([fd8a21a](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/fd8a21a1b4897a6bf409c8b8fd59a9cc74eaf5eb))
* **scripts:** Rename CLEANUP to CLEANUP_AFTER_TESTS in Makefile ([2d44ce1](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/2d44ce144f3e1f7069d83035f1cf6e0ce0dd11ef))
* Bump ubuntu from 20 to 22, 20 end of life april 2025 ([b8d4b70](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/b8d4b70d39955c89b41a994dd0c443d2b6b18691))
* Fixed required version ([6fa4e58](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/6fa4e5876c84d53137626391d7f843af8b4a3c04))
* Updated base instance name ([833f478](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/833f478479c89eba78428824222b64775cdbf287))


## [3.1.0](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/compare/v3.0.0...v3.1.0) (2024-12-23)


### Features

* **azure-github-ci:** Added initial scalable GitHub runner ([5d2ee39](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/5d2ee391aae44c2764a9551e332bf2d1b9de11b9))
* **gcp-github-ci:** Added initial scalable runner for GitHub ([5f751c1](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/5f751c1d92e8424c4466f28e559db22925077e6c))



### Tests

* **gcp-gitlab-ci:** Use the same resource group name to prevent the GCP tests clashing ([a8ee594](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/a8ee594c5e9bf5460a840352e75617580fd9aafe))



## [3.0.0](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/compare/v2.1.3...v3.0.0) (2024-12-03)


### ⚠ BREAKING CHANGES

* **azure-gitlab-ci:** Upgraded azurerm from 2.97.0 to 4.9.0
* **azure-gitlab-ci:** Upgraded azuread from 2.x.x to 3.0.2

### Features

* **azure-gitlab-ci:** Added new config option available in newer versions of azure provider ([e6dbf14](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/e6dbf141218082bbeecbff55e778e09387b58519))
* **azure-gitlab-ci:** Added suport for encryption at host ([3558e25](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/3558e251b6569e52fdf3bd18b925d97921a5d4fa))
* **azure-gitlab-ci:** Updated key vault key and secret permissions to be configurable ([be73728](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/be7372829536bbe406c5dd52d36c237e2175520b))


### Tests

* **azure-gitlab-ci:** Increase test timeout from 5 to 10 minutes ([b83655e](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/b83655ee31a465a73e07aad86739c55386bd25a0))


### Other Changes

* **azure-gitlab-ci:** Added ability to specify ci network service endpoints ([b3a0b6f](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/b3a0b6f89662d4a12001bba6b88aae071eebc153))
* **gcp-gitlab-ci:** Upgrade the google service-accounts module to latest 4.4.2 ([aa0e21d](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/aa0e21d178b89679dc47ba8f592547b06d958655))

### [2.1.3](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/compare/v2.1.2...v2.1.3) (2023-08-21)


### Bug Fixes

* **gcp:** Fixed service account roles for scalable runner ([24fc478](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/24fc4787e1ae35d7b121836ca71d69df8d8a4c71))

### [2.1.2](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/compare/v2.1.0...v2.1.2) (2023-06-30)


### Bug Fixes

* **azure-gitlab-ci:** Ensure Azure runners use same image as orchestrator ([db930b4](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/db930b404971d8d5d94e83670d69ef799d9d5fef))


### Other Changes

* **azure-gitlab-ci:** Allow min TLS version to be specified for Azure cache storage account and default to TLS 1.2 ([05a0159](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/05a015994c8e9ee257b216caeb09ee363a3984ff))

## [2.1.0](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/compare/v2.0.0...v2.1.0) (2023-06-06)

### Features

* **azure-gitlab-ci:** Add Azure scalable CI runner ([3593be0](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/3593be09f2037cf32443c4c61fd76f95b90943a9))
* Prune docker images daily on CI runners ([6a6f0b6](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/6a6f0b6bf8feb6be2e0d179a44726aff619d2dc7))
* Upgrade to Ubuntu 20 on Azure/GCP CI runners ([8cbc33d](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/8cbc33da361309fa765b967677cd1958281838d7))

## [2.0.0](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/compare/v1.1.2...v2.0.0) (2023-01-11)

### ⚠ BREAKING CHANGES

* **azure-gitlab-ci:** Updating azure_virtual_machine resource to linux_virtual_machine will destroy and rebuild the runner

### Features

* **azure-gitlab-ci:** Updated azure_virtual_machine resource to linux_virtual_machine ([6d215e5](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/6d215e528d8fe7385e08d1602294a44d36f8a026))
* **gcp-gitlab-ci:** Updated scalable runner outputs to be specific in orchestrator ([a9c603f](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/a9c603f4db1796a0cf5cab292f164809f9fe2dd5))
* **gcp-gitlab-ci:** Updated scalable runner to expose runner service account ([c179de6](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/c179de6b133f8a3ca414628f34184362440afc49))

### [1.1.2](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/compare/v1.1.1...v1.1.2) (2022-08-09)

### Features

* **azure-gitlab-ci:** Exposed ids of underlying service principals ([19f1834](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/19f18341421526abbcdb6786d061eaed4a603e42))

### Bug Fixes

* **gcp-gitlab-ci:** Start test runner with subnetwork, allow concurrency to be set ([9b1b8c4](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/9b1b8c429be9fdffd77b7ad907fd1c66b8d53c60))
* **gcp-gitlab-ci:** Switch gcr bucket for cache bucket so ci has permission for both ([09152e5](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/09152e5c94b7910c40291648e2663a473e7b8329))
* **gcp-gitlab-ci:** Set one name instead of names in shared ci, set gitlab orchestrator concurrency ([0a51696](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/0a516966c80661f00c0ad0d244586ed960b87b70))

### [1.1.1](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/compare/v1.1.0...v1.1.1) (2022-07-28)

### Bug Fixes

* **gcp-gitlab-ci:** Fix the outputs in scalable-gitlab-ci ([212f7f6](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/212f7f657250fbad380b43d18ee0c90fbc764779))
* **gcp-gitlab-ci:** Include project ID in scalable runner service account roles ([dbb5a04](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/dbb5a044e614595f8c243cd16cdaa7824dd474da))

## [1.1.0](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/compare/v1.0.1...v1.1.0) (2022-07-27)

### Features

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
