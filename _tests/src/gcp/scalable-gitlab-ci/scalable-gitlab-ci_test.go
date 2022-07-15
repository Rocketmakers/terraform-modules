package gcpscalablegitlabci

import (
	"backendconfig"
	"fmt"
	"gitlabrunners"
	"testing"

	"github.com/stretchr/testify/assert"

	"github.com/gruntwork-io/terratest/modules/terraform"
)


func TestGcpGitlabCi(t *testing.T) {
	// Construct the terraform options with default retryable errors to handle the most common
	// retryable errors in terraform testing.
	runnerTag := "gcp-d7500544-e29d-451b-bd3f-083065f46b67"

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

	gitlabrunners.TestCIRunners(t, &gitlabrunners.TestScalableGitlabRunnerOptions{
		RunnerTag:        runnerTag,
		ProjectID: 				"terraform-testing-317911",
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
