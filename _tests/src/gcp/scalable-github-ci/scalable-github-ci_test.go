package gcpscalablegithubci

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
	runnerLabel := "self-hosted-gcp-scalable-github-ci-terratest"
	gcpProjectZone := "europe-west1-b"
	gcpProjectRegion := "europe-west1"

	ipAddress, err := rmutils.GetMachineExternalIPAddress()
	require.NoError(t, err)

	backendConfigOptions := backendconfig.GcsBackendConfigOptions{
		Prefix: "gcp/scalable-github-ci",
	}
	backendConfig := backendconfig.GetGcsBackendBucketConfig(&backendConfigOptions)

	githubToken := os.Getenv("GH_RUNNER_API_TOKEN")
	require.NotEmpty(t, githubToken, "GH_RUNNER_API_TOKEN must be set")

	vars := map[string]interface{}{
		"github_api_token":   githubToken,
		"gcp_project_region": gcpProjectRegion,
		"gcp_project_zone":   gcpProjectZone,
		"runner_label":       runnerLabel,
		"cidr_range":         ipAddress.String() + "/32",
	}

	rmutils.WriteTfvarsFile(t, vars, "../../../config/gcp/scalable-github-ci/inputs.tfvars")

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		BackendConfig: backendConfig,
		TerraformDir:  "../../../config/gcp/scalable-github-ci",
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
