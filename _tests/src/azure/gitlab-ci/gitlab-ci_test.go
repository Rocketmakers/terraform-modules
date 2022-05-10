package gcpgitlabci

import (
	"backendconfig"
	"fmt"
	"gitlabapi"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestAzureGitlabCi(t *testing.T) {
	// Construct the terraform options with default retryable errors to handle the most common
	// retryable errors in terraform testing.
	runnerTag := "azure-1f9044b0-231a-4d92-a4b1-7fddbe19bb0d"
	instanceCount := 2

	backendConfigOptions := backendconfig.AzureBackendConfigOptions{
		Key: "gitlab-ci.tfstate",
	}
	backendConfig := backendconfig.GetAzureBackendBucketConfig(&backendConfigOptions)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		BackendConfig: backendConfig,
		TerraformDir:  "../../../config/azure/gitlab-ci",
		Vars: map[string]interface{}{
			"runner_tag":          runnerTag,
			"instance_count":      instanceCount,
			"resource_group_name": backendConfig["resource_group_name"],
		},
	})

	gitlabapi.TestGitlabCi(t, &gitlabapi.TestGitlabRunnerOptions{
		RunnerTag:        runnerTag,
		InstanceCount:    instanceCount,
		TerraformOptions: terraformOptions,
	}, assertions)

	fmt.Println("🚀 Done 🚀")
}

func assertions(t *testing.T, terraformOptions *terraform.Options) {
}
