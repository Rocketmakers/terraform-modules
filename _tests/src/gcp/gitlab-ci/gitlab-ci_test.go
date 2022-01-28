package gitlabci

import (
	"fmt"
	"os"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/xanzy/go-gitlab"
)

func createGitlabApiClient() (*gitlab.Client, error) {
	variableName := "GITLAB_API_TOKEN"
	gitlabApiToken := os.Getenv(variableName)
	if gitlabApiToken == "" {
		return nil, fmt.Errorf("Missing %v variable", variableName)
	}
	return gitlab.NewClient(gitlabApiToken)
}

func TestGcpGitlabCi(t *testing.T) {
	// Construct the terraform options with default retryable errors to handle the most common
	// retryable errors in terraform testing.
	runnerTag := "gcp-d7500544-e29d-451b-bd3f-083065f46b67"
	encryptedGitlabToken := "CiQA8kio5uT0OO1WRtZMB6V9zrDpLcFF92VrK6tLLY7XOr4TG94SPQD9t8BCTtEelpIo1iTjjtDH5Vm3x6lE0ftB/9l/cex5zaYUWKr8Gpw3AgbNZIkE/DV1n6ZCqg6E3D0ee7o="
	kmsKeyName := "projects/rocketmakers-developers/locations/europe-west2/keyRings/rocketmakers-secrets/cryptoKeys/rocketmakers-secrets"
	instanceCount := 2

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// Set the path to the Terraform code that will be tested.
		TerraformDir: "../../../config/gcp/gitlab-ci",

		Vars: map[string]interface{}{
			"runner_tag":             runnerTag,
			"encrypted_gitlab_token": encryptedGitlabToken,
			"crypto_key_self_link":   kmsKeyName,
			"instance_count":         instanceCount,
		},
	})

	client, err := createGitlabApiClient()
	require.NoError(t, err)

	// Clean up resources at the end of the test.
	defer terraform.Destroy(t, terraformOptions)

	// Create resources
	// Run "terraform init" and "terraform apply". Fail the test if there are any errors.
	terraform.InitAndApply(t, terraformOptions)

	// Allow time for the runner to become active
	waitSeconds := 10
	fmt.Printf("\nWaiting %v seconds to allow the runner to become active...\n\n", waitSeconds)
	time.Sleep(time.Duration(waitSeconds) * time.Second)

	// Get runners with the specified tag
	tags := []string{runnerTag}
	runners, _, err := client.Runners.ListRunners(&gitlab.ListRunnersOptions{
		TagList: &tags,
	})
	require.NoError(t, err)

	// There should be the same number as specified via the instance_count terraform variable
	assert.Equal(t, len(runners), instanceCount)

	fmt.Printf("Verifying status of %v runners with tag: %v\n\n", len(runners), tags)
	var runnerIds []int
	for _, runner := range runners {
		runnerIds = append(runnerIds, runner.ID)

		fmt.Printf("Description: %v\n", runner.Description)
		fmt.Printf("Name: %v\n", runner.Name)
		fmt.Printf("Active: %v\n", runner.Active)
		fmt.Printf("Online: %v\n", runner.Online)
		fmt.Printf("Status: %v\n", runner.Status)

		fmt.Println("---")

		assert.True(t, runner.Active, "Runner is active")
		assert.True(t, runner.Online, "Runner is online")
		assert.Equal(t, runner.Status, "online", "Runner status is online")
	}

	fmt.Println("Deleting regsitered runners...")
	for _, runnerId := range runnerIds {
		client.Runners.DeleteRegisteredRunnerByID(runnerId, nil)
	}

	fmt.Println("🚀 Done 🚀")
	// TODO: Check there are no resources after destroying at the end of the test?
}
