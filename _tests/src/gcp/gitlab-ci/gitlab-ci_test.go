package gcpgitlabci

import (
	"backendconfig"
	"fmt"
	"gitlabapi"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestGcpGitlabCi(t *testing.T) {
	// Construct the terraform options with default retryable errors to handle the most common
	// retryable errors in terraform testing.
	runnerTag := "gcp-d7500544-e29d-451b-bd3f-083065f46b67"
	instanceCount := 2

	backendConfigOptions := backendconfig.GcsBackendConfigOptions{
		Prefix: "gcp/gitlab-ci",
	}
	backendConfig := backendconfig.GetGcsBackendBucketConfig(&backendConfigOptions)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		BackendConfig: backendConfig,
		TerraformDir:  "../../../config/gcp/gitlab-ci",
		Vars: map[string]interface{}{
			"runner_tag":     runnerTag,
			"instance_count": instanceCount,
		},
	})

	gitlabapi.TestGcpGitlabCi(t, &gitlabapi.TestGitlabRunnerOptions{
		RunnerTag:        runnerTag,
		InstanceCount:    instanceCount,
		TerraformOptions: terraformOptions,
	})

	fmt.Println("🚀 Done 🚀")
}
