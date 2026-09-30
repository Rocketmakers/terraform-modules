package gcpgitlabci

import (
	"backendconfig"
	"fmt"
	"gitlabapi"
	"rmutils"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestAzureGitlabCi(t *testing.T) {
	// Construct the terraform options with default retryable errors to handle the most common
	// retryable errors in terraform testing.
	runnerTag := "azure-gitlab-ci-terratest"
	instanceCount := 2

	ipAddress, err := rmutils.GetMachineExternalIPAddress()
	require.NoError(t, err)

	backendConfigOptions := backendconfig.AzureBackendConfigOptions{
		Key: "gitlab-ci.tfstate",
	}
	backendConfig := backendconfig.GetAzureBackendBucketConfig(&backendConfigOptions)

	vars := map[string]interface{}{
		"runner_tag":          runnerTag,
		"instance_count":      instanceCount,
		"resource_group_name": backendConfig["resource_group_name"],
		"cidr_range":          ipAddress.String() + "/32",
	}

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		BackendConfig: backendConfig,
		TerraformDir:  "../../../config/azure/gitlab-ci",
		Vars:          vars,
	})

	rmutils.WriteTfvarsFile(t, vars, "../../../config/azure/gitlab-ci/inputs.tfvars")

	gitlabapi.TestGitlabCi(t, &gitlabapi.TestGitlabRunnerOptions{
		RunnerTag:        runnerTag,
		InstanceCount:    instanceCount,
		TerraformOptions: terraformOptions,
	}, assertions)

	fmt.Println("🚀 Done 🚀")
}

func assertions(t *testing.T, terraformOptions *terraform.Options) {
	// Exit code 2 means there are changes in the plan
	// Exit code 1 means there was an error in the plan
	exit_code := terraform.PlanExitCode(t, terraformOptions)
	assert.Equal(t, 0, exit_code, "Expecting plan with no changes")
}
