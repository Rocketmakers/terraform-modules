package sclablegcpgitlabci

import (
	"backendconfig"
	"fmt"
	"gitlabapi"
	"testing"

	"github.com/stretchr/testify/assert"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestGcpGitlabCi(t *testing.T) {
	// Construct the terraform options with default retryable errors to handle the most common
	// retryable errors in terraform testing.
	runnerTag := "gcp-6faab9c3-9d73-4d51-ad84-d777b2d0cef0"

	backendConfigOptions := backendconfig.GcsBackendConfigOptions{
		Prefix: "gcp/scalable-gitlab-ci",
	}
	backendConfig := backendconfig.GetGcsBackendBucketConfig(&backendConfigOptions)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		BackendConfig: backendConfig,
		TerraformDir:  "../../../config/gcp/scalable-gitlab-ci",
		Vars: map[string]interface{}{
			"runner_tag":     runnerTag,
		},
	})

	gitlabapi.TestScalableGitlabCi(t, &gitlabapi.TestScalableGitlabRunnerOptions{
		RunnerTag:        runnerTag,
		TerraformOptions: terraformOptions,
	}, assertions)

	fmt.Println("🚀 Done 🚀")
}

func assertions(t *testing.T, terraformOptions *terraform.Options) {
	service_account_key := terraform.Output(t, terraformOptions, "service_account_key")
	assert.NotNil(t, service_account_key)

	service_account_email := terraform.Output(t, terraformOptions, "service_account_email")
	assert.NotNil(t, service_account_email)
}
