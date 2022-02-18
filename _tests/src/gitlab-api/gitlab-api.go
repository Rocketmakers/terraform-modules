package gitlabapi

import (
	"fmt"
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/xanzy/go-gitlab"
)

type TestGitlabRunnerOptions struct {
	RunnerTag        string
	InstanceCount    int
	TerraformOptions *terraform.Options
}

func createGitlabApiClient() (*gitlab.Client, error) {
	variableName := "GITLAB_TOKEN"
	gitlabApiToken := os.Getenv(variableName)
	if gitlabApiToken == "" {
		return nil, fmt.Errorf("Missing %v variable", variableName)
	}
	return gitlab.NewClient(gitlabApiToken)
}

func TestGitlabCi(t *testing.T, opt *TestGitlabRunnerOptions) {
	runnerTag := opt.RunnerTag
	instanceCount := opt.InstanceCount
	terraformOptions := opt.TerraformOptions

	// Create the gitlab AP client early to catch errors
	client, err := createGitlabApiClient()
	require.NoError(t, err)

	// Clean up resources at the end of the test.
	defer terraform.Destroy(t, terraformOptions)

	// Remove the lock file so we get the latest providers each time
	lockFilePath := filepath.Join(terraformOptions.TerraformDir, ".terraform.lock.hcl")
	os.Remove(lockFilePath)

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
		assert.Equal(t, "online", runner.Status, "Runner status is online")
	}

	fmt.Println("Deleting regsitered runners...")
	for _, runnerId := range runnerIds {
		fmt.Printf("Deleting runner: %v\n", runnerId)
		_, err := client.Runners.DeleteRegisteredRunnerByID(runnerId, nil)

		if err != nil {
			fmt.Printf("Failed to delete runner: %v\n", runnerId)
			fmt.Println(err)
		}
	}
}
