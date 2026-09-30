#!/bin/bash
set -eo pipefail

if [ -z "$TERRATEST_DIR" ]; then
  echo "TERRATEST_DIR must be set (e.g. TERRATEST_DIR=gcp/gitlab-ci)"
  exit 1
fi

TERRATEST_LOG_PARSER_VERSION=${TERRATEST_LOG_PARSER_VERSION:-v0.40.24}
ARCHITECTURE=${ARCHITECTURE:-linux_amd64}

# Set false to leave resources in place after testing (speed up feedback loops)
export CLEANUP_AFTER_TESTS=${CLEANUP_AFTER_TESTS:-true}

# Set true to write inputs.tfvars without running tests
export WRITE_VARS_FILE_AND_EXIT=${WRITE_VARS_FILE_AND_EXIT:-false}

# To allow terraform init to work without having to hardcode an AWS region into a provider block
export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-eu-west-1}

asdf plugin add golang https://github.com/kennyp/asdf-golang.git || true
# asdf install >= 0.16 returns non-zero error code if already installed
asdf install golang || true

TEST_DIR="$(git rev-parse --show-toplevel)/_tests/src/$TERRATEST_DIR"
echo "Running tests for $TERRATEST_DIR..."

if [[ "$(uname -s)" == "Darwin" ]]; then
  (cd "$TEST_DIR" && go test -timeout 60m)
else
  curl --location --silent --fail --show-error -o terratest_log_parser https://github.com/gruntwork-io/terratest/releases/download/${TERRATEST_LOG_PARSER_VERSION}/terratest_log_parser_${ARCHITECTURE}
  chmod +x terratest_log_parser
  mv terratest_log_parser /usr/local/bin
  (cd "$TEST_DIR" && go test -timeout 60m | tee test_output.log) && terratest_log_parser -testlog "$TEST_DIR/test_output.log" -outputdir "$TEST_DIR"
fi
