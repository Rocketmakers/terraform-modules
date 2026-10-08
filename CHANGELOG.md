# Changelog

All notable changes to this project will be documented in this file. See [commit-and-tag-version](https://github.com/absolute-version/commit-and-tag-version) for commit guidelines.

## [4.0.0](https://github.com/Rocketmakers/terraform-modules/compare/v3.9.0...v4.0.0) (2026-09-30)


### ⚠ BREAKING CHANGES

* **azure-github-ci:** Minimum azurerm version is now 5.0.0 for azure-gitlab-ci, azure-scalable-gitlab-ci and
azure-github-ci

### CI

* Move to trunk-based workflow on GitHub with pnpm and turbo ([36492b0](https://github.com/Rocketmakers/terraform-modules/commit/36492b032605f9acb70e188cf7c30aa5880248d6))
* Pull request reminders ([f8953a6](https://github.com/Rocketmakers/terraform-modules/commit/f8953a6200b29f9378fd4c2e40a916e9b584fb41))
* Stop concurrent release merges cancelling each other's tags ([26f3f23](https://github.com/Rocketmakers/terraform-modules/commit/26f3f23bc4bcdc96f23b20be21b350e16fe20b41))
* Validate the release version and branch before tagging ([f8e1036](https://github.com/Rocketmakers/terraform-modules/commit/f8e1036f50bf35ee9cff81b42a65ed272179948e))


### Other Changes

* **azure-github-ci:** Document container app environment destroy known issue ([ebb57ee](https://github.com/Rocketmakers/terraform-modules/commit/ebb57ee6b8ef51e0cdc136a9b8a96c20c73e4d2b))


### Features

* **azure-github-ci:** Expose inputs for azurerm defaults that changed in v4 and v5 ([f54087d](https://github.com/Rocketmakers/terraform-modules/commit/f54087d28daa452c07077045562e675aeacbe2d0))
* **azure-github-ci:** Upgrade azurerm to v5 ([dedfb5e](https://github.com/Rocketmakers/terraform-modules/commit/dedfb5eb88a72b766e4db9494cfa7c9764f6254d))

## [3.9.0](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/compare/v3.8.3...v3.9.0) (2026-02-09)


### Features

* **azure-github-ci:** Updated github runner version to 2.331.0 ([a07ed9b](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/a07ed9ba02668c8720a8adf8a28686ce83bc315c))
* **gcp-github-ci:** Updated github runner version to 2.331.0 ([97c9ad4](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/97c9ad458daf67e56329ab80682687cc32ccf987))

### [3.8.4](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/compare/v3.8.3...v3.8.4) (2025-12-22)


### Bug Fixes

* **gcp-github-ci:** Updated module versions to support v7 google providers ([6a268ee](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/6a268eed700449ae3415e95263d9d23f4786d411))
* **gcp-gitlab-ci:** Updated module versions to support v7 google providers ([e8ed024](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/e8ed02489f9000b594d38b0d4bd1628efec827c7))


### Other Changes

* Updated package lock ([a12b65e](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/a12b65eeb54d8c46962f2db37e377fa9572af9b0))
* Updated tool versions to latest ([502dda0](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/502dda06b291c6c626536384d146aaeff60b5f7e))

### [3.8.3](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/compare/v3.8.2...v3.8.3) (2025-10-30)


### Other Changes

* **azure-github-ci:** Increase default autoscaler version for .NET security patch CVE-2025-55315 ([cf57822](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/cf57822b58eb72677435c5cdaba352fd3518eb7b))

### [3.8.2](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/compare/v3.8.1...v3.8.2) (2025-09-26)


### Bug Fixes

* **azure-github-ci:** Use latest autoscaler version 1.0.4 for stabilitly improvements ([7959f46](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/7959f46d3f4bb2281755d69cf7d3e77c6ff92c12))

### [3.8.1](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/compare/v3.8.0...v3.8.1) (2025-09-16)


### Bug Fixes

* **azure-github-ci:** Don't overprovision VM scale set instances - it causes jobs to be cancelled ([ca8088c](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/ca8088c3526d517e1e275480d28980ad6d33721f))

## [3.8.0](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/compare/v3.7.0...v3.8.0) (2025-09-10)


### Features

* **azure-github-ci:** Add disk_storage_account_type variable and default to StandardSSD_LRS ([cd66551](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/cd665514c179b61e034e5b96b7c4abf83d166b65))

## [3.7.0](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/compare/v3.6.0...v3.7.0) (2025-09-08)


### Features

* **azure-github-ci:** Add variable for configuring the autoscaler webhook delay ([ab8e2cb](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/ab8e2cba37969cfbb75fba502fb20b874f644a7d))
* **azure-github-ci:** Create CI autoscaler webhook via terraform ([fcbb62f](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/fcbb62f738580b445a583ca169f2e282d9869d3f))
* **azure-github-ci:** Use version 1.0.3 of the autoscaler app by default for structured logs ([aa035d9](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/aa035d9cd9e37528fc118714a9446c5acc6f330a))


### Bug Fixes

* **azure-github-ci:** Updated to expose docker install script url ([9ae2337](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/9ae23379a96c5c45b70de0b09534fd02ed51a8a7))
* **gcp-github-ci:** Added apt-get update to fix docker failing to install ([dcff95c](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/dcff95c7a9902638cbfeedc7889d3e50be23df64))


### Other Changes

* Updated apt-get command ([e803d89](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/e803d890b29d9611f348269c8362e70176fc6f5a))
* Updated base image for runner ([9bd4664](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/9bd46645e29d732fcd45369e3c68725740c05976))
* Updated update command ([f566bb1](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/f566bb18784d1499d4d5221b75c454d5b5e86097))


### Tests

* **azure-github-ci:** Add new variables to test config ([f132bd1](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/f132bd1862b11d47a4e9772943a2fcd20ed258eb))

## [3.6.0](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/compare/v3.5.0...v3.6.0) (2025-07-30)


### Features

* **azure-github-ci:** Updated to include public url for autoscaler ([a86c5c8](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/a86c5c8cc5922f2ba353fd5b5a763465bd4bace1))


### Bug Fixes

* **azure-github-ci:** Removed app environment profile as not required and causing issues in later version of provider ([7bd74ba](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/7bd74baa070654fe51acb5fd80ce3b5bbb730c3e))
* **azure-github-ci:** Removed workload profile for autoscaler as not needed ([36aa991](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/36aa991f733d080ae2fecdb7361046ec8cb0ab76))
* **azure-github-ci:** Updated to output webhook secret ([4540097](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/4540097a4f6ed2833325cc15c607c13593ba8059))
* **gcp-gitlab-ci:** Updated image name to latest version ([192355d](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/192355d01418ec6db2128dc1367553cbbbf1837e))


### Other Changes

* **azure-github-ci:** Updated scalable runner version ([87b3feb](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/87b3febb9165b6da24c84ab35f6090967ea61e9a))

## [3.5.0](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/compare/v3.4.0...v3.5.0) (2025-07-08)


### Features

* **azure-github-ci:** Added support for auto scaler via container app ([9340ebc](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/9340ebc4a6ea1653295840c8b02ccc8ad081f56d))
* **azure-github-ci:** Added support for encryption at host for github scalable runners ([c23382a](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/c23382a081fd1578e0b27d749fb28496d174a554))
* **azure-github-ci:** Exposed virtual machine scale set id as output ([9fd8780](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/9fd87809009a97fb808017cf08197e071e7cce4b))



## [3.4.0](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/compare/v3.3.0...v3.4.0) (2025-05-16)


### Features

* **azure-github-ci:** Remove the oldest VM when scaling in ([5c9f30e](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/5c9f30e7530fd850406c4050d6bf6564546c7f08))

## [3.3.0](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/compare/v3.2.0...v3.3.0) (2025-05-08)


### Features

* **azure-github-ci:** Add support for custom labels when registering runners ([f25d8dd](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/f25d8dd93d2d7faae69969ce36c932f9d936c661))
* **azure-github-ci:** Replace the runner scale set if the provisioning script changes ([7d572df](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/7d572df37ad6f3196b79206e9132581ae79a7d78))
* **gcp-github-ci:** Add support for custom labels when registering runners ([94e9b9c](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/94e9b9c97e5c7761557a36a5b2781271ad74de59))
* **gcp-github-ci:** Ensure runner VMs are recreated when the provisioning script changes ([4f2e5bf](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/4f2e5bfbc8e41bc4e29c2cdf8371bd7a6fda4995))
* Mark variable "github_api_token" as sensitive ([bbfa1e0](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/bbfa1e02dc9b40562e1912e75b358c55724d4415))


### Bug Fixes

* **gcp-gitlab-ci:** Allow google_storage_bucket_iam_member resources to be created after service accounts ([9d5a9c4](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/9d5a9c4003a54b9c818ce6f2b47b30335de9ae61))


### Tests

* **azure-github-ci:** Start of tests - just applies and destroys - no verification steps yet ([69e1883](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/69e18838fae6e56c9e7414e751af7a40e636f85a))
* **azure-gitlab-ci:** Support WRITE_VARS_FILE_AND_EXIT in non-scalable gitlab runner tests ([30e1f4a](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/30e1f4a937128cd9c75e3b246842433b17cd2eb5))
* **azure-gitlab-ci:** Use a dedicated resource group and project name for azure scalable CI tests ([ce62c3d](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/ce62c3da95e790fe8681bb752950cec808734a41))
* **gcp-github-ci:** Start of tests - just applies and destroys - no verification steps yet ([95e3d3e](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/95e3d3e45e77b7036b56d73721e057bb80f13250))
* **gcp-gitlab-ci:** Use a different project_prefix for scalable and non-scalable runner tests ([6b71b03](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/6b71b03d49146f56effa5ba6a29ffe0da0448f0f))
* Use descriptive tags for gitlab CI tests ([6f07770](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/6f077709b1ca1259bafdc37265b549389d842df0))
* **scripts:** Don't notify slack when tests pass ([9ec1ce3](https://gitlab.com/rocketmakers/infrastructure/terraform-modules/commit/9ec1ce3b697b37a85813300e7a18a6bf8b1ca995))


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
