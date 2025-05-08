package azurescalablegithubci

import (
	"backendconfig"
	"os"
	"path/filepath"
	"rmutils"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/require"
)

func TestScalableGithubCI(t *testing.T) {
	runnerLabel := "self-hosted-azure-scalable-github-ci-terratest"
	primaryLocation := "West Europe"
	resourceGroup := "Terratest-Github-Scalable-CI"

	ipAddress, err := rmutils.GetMachineExternalIPAddress()
	require.NoError(t, err)

	backendConfigOptions := backendconfig.AzureBackendConfigOptions{
		Key: "scalable-github-ci.tfstate",
	}
	backendConfig := backendconfig.GetAzureBackendBucketConfig(&backendConfigOptions)

	githubToken := os.Getenv("GH_RUNNER_API_TOKEN")
	require.NotEmpty(t, githubToken, "GH_RUNNER_API_TOKEN must be set")

	vars := map[string]interface{}{
		"github_api_token":    githubToken,
		"primary_location":    primaryLocation,
		"runner_label":        runnerLabel,
		"cidr_range":          ipAddress.String() + "/32",
		"resource_group_name": resourceGroup,
	}

	rmutils.WriteTfvarsFile(t, vars, "../../../config/azure/scalable-github-ci/inputs.tfvars")

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		BackendConfig: backendConfig,
		TerraformDir:  "../../../config/azure/scalable-github-ci",
		Vars:          vars,
	})

	cleanUp := os.Getenv("CLEANUP_AFTER_TESTS") != "false"

	// Remove the lock file so we get the latest providers each time
	lockFilePath := filepath.Join(terraformOptions.TerraformDir, ".terraform.lock.hcl")
	os.Remove(lockFilePath)

	if cleanUp {
		// This has to occur before the init stage https://github.com/gruntwork-io/terratest/issues/511#issuecomment-619873137
		defer terraform.Destroy(t, terraformOptions)
	}

	// Create resources
	// Run "terraform init" and "terraform apply". Fail the test if there are any errors.
	terraform.InitAndApply(t, terraformOptions)

	// TODO: Trigger jobs and verify they pass
}
