# Contributing to Rocketmakers terraform modules

- [Contributing to Rocketmakers terraform modules](#contributing-to-rocketmakers-terraform-modules)
  - [Getting started](#getting-started)
  - [Running tests](#running-tests)
  - [Documentation](#documentation)
  - [Branching strategy](#branching-strategy)
  - [Release process](#release-process)
    - [Decide on the new version code](#decide-on-the-new-version-code)
    - [Branching](#branching)
    - [Versioning and changelog generation](#versioning-and-changelog-generation)
    - [Changelog review](#changelog-review)
    - [Update local branches](#update-local-branches)

## Getting started

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

## Running tests

You will need to be on the VPN or in the Rocketmakers office.

**Authentication to be reviewed and improved...**

Get AWS keys from [internal-gitlab-runners/secrets/secrets.yaml](https://gitlab.com/rocketmakers/internal-gitlab-runners/-/blob/master/secrets/secrets.yaml)

```bash
# For all tests
export GITLAB_TOKEN=_token_with_api_access_

# Optionally prevent resources from being destroyed at the end of tests, so feedback is quicker during development
export CLEANUP=false

# aws
export AWS_SECRET_ACCESS_KEY=_key_
export AWS_ACCESS_KEY_ID=_access_key_
make test TERRATEST_DIR=aws/gitlab-ci

# azure (you'll need to be added to a group first)
export ARM_SUBSCRIPTION_ID=68bb123f-6027-4e99-8ab0-a01fb16cdd79
az login
make test TERRATEST_DIR=azure/gitlab-ci

# gcp
gcloud auth application-default login
make test TERRATEST_DIR=gcp/gitlab-ci
```

## Documentation

We use [terraform-docs](https://github.com/terraform-docs/terraform-docs) along with custom scripts to help generate our module documentation.

Run the following to install the tools and generate documentation:

```
make generate-docs
```

## Branching strategy

We follow the strategy described in [Notion](https://www.notion.so/Source-Control-59348db1cfb847f88cbdfdc3d0feb48c#ca1f2bb64421489a941e444617280e6b). Some of this process has been automated as described below.

This relies on the following tools:

- `commitizen`: Enforcing commit message conventions
- `cz-conventional-changelog`: Maintaining a changelog based on commit message conventions

## Release process

To release a new version, make sure your local git repo is clean and run the following:

### Decide on the new version code

```
# Format
export NEW_VERSION_CODE=<major>.<minor>.<patch>
```

### Branching

If the intended release branch doesn't exist, create one with the following commands:

```bash
git checkout develop
git pull
git checkout -b release/$NEW_VERSION_CODE
```

If release branch already exists, checkout that branch and make sure you have the latest changes:

```bash
git checkout release/$NEW_VERSION_CODE
git pull
```

### Versioning and changelog generation

Clean the codebase, increase the version number and generate updates to the changelog with the following commands:

```bash
make clean
make bump-version
```

**NB**: If you add any more commits to the changelog after the initial `make bump-version` then you can run `make changelog` to update the changelog based on the new commits. You will want to check the updated changelog for duplicate entries before committing the update.

### Changelog review

The changelog generated in step 2 needs to be reviewed. When finished, commit the updated changelog:

```bash
git add CHANGELOG.md
HUSKY_SKIP_HOOKS=1 git commit -m "release: Changelog for v$NEW_VERSION_CODE"
```

Run the following command to push to origin and auto-generate a merge request from the release branch into `master`:

```bash
git push origin release/$NEW_VERSION_CODE -o merge_request.create -o merge_request.target=master
```

Go to https://gitlab.com/rocketmakers/infrastructure/terraform-modules/-/merge_requests to review and merge once the pipeline has passed.

CI is set up to automatically create and push a tag whenever a release branch is merged into master. Once the tag has been created then the new version is officially released and should be referenced via git tag.

### Update local branches

Once the CI has completed the tagged release, you will need to create a merge request from `master` back into `develop`, which will include the new version number and changelog.

Bring your local branches up to date with origin:

```bash
git checkout master
git pull origin master
git checkout develop
git pull origin develop
```
