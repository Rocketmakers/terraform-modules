package gcpgitlabci

import (
	"rmutils"

	"backendconfig"
	"fmt"
	"gitlabapi"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestGcpGitlabCi(t *testing.T) {
	// Construct the terraform options with default retryable errors to handle the most common
	// retryable errors in terraform testing.
	runnerTag := "gcp-gitlab-ci-terratest"
	instanceCount := 2

	backendConfigOptions := backendconfig.GcsBackendConfigOptions{
		Prefix: "gcp/gitlab-ci",
	}
	backendConfig := backendconfig.GetGcsBackendBucketConfig(&backendConfigOptions)

	ipAddress, err := rmutils.GetMachineExternalIPAddress()
	require.NoError(t, err)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		BackendConfig: backendConfig,
		TerraformDir:  "../../../config/gcp/gitlab-ci",
		Vars: map[string]interface{}{
			"runner_tag":     runnerTag,
			"instance_count": instanceCount,
			"cidr_range":     ipAddress.String() + "/32",
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
	service_account_id := terraform.Output(t, terraformOptions, "service_account_id")
	assert.NotNil(t, service_account_id)

	service_account_email := terraform.Output(t, terraformOptions, "service_account_email")
	assert.NotNil(t, service_account_email)
}
