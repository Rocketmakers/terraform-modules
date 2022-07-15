package gitlabrunners

import (
	"context"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"testing"
	"time"

	compute "cloud.google.com/go/compute/apiv1"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/xanzy/go-gitlab"
	"google.golang.org/api/iterator"
	computepb "google.golang.org/genproto/googleapis/cloud/compute/v1"
	"k8s.io/apimachinery/pkg/util/wait"
)

type TestScalableGitlabRunnerOptions struct {
	RunnerTag        string
	ProjectID   		 string
	TerraformOptions *terraform.Options
}

/**
Get token from Environment Variables
*/
func getGitlabTokenFromEnvironmentVariables()(string, error) {
	variableName := "GITLAB_TOKEN"
	gitlabApiToken := os.Getenv(variableName)
	if gitlabApiToken == "" {
		return "", fmt.Errorf("Missing %v variable", variableName)
	}
	return gitlabApiToken, nil
}

/**
Creates a Gitlab Api Client
*/
func createGitlabApiClient(token string) (*gitlab.Client, error) {
	return gitlab.NewClient(token)
}

/**
	Function queries the GCP VM instances endpoint and retrieves a list of VM's that are currently running in the project
	Uses the default GCP project 
*/
func listVMInstancesForProject(projectID string, zone string) ([]string, error) {
	arr := []string{}
	ctx := context.Background()
	instancesClient, err := compute.NewInstancesRESTClient(ctx)
	if err != nil {
		return nil, err
	}
	defer instancesClient.Close()

	req := &computepb.ListInstancesRequest{
					Project: projectID,
					Zone:    zone,
	}

	it := instancesClient.List(ctx, req)
	log.Println("Instances found in zone %s:\n", zone)
	for {
					instance, err := it.Next()
					if err == iterator.Done {
						break
					}
					if err != nil {
						return nil, err
					}
					arr = append(arr, instance.GetName())
	}
	return arr, nil
}
// glpat-2TE3zrcsT6J7-sLszwoA

/**
	Create and trigger a Pipeline on the test project
*/
func triggerGitlabPipeline(client *gitlab.Client, gitlabProjectId string, gitlabBranch string, gitlabToken string) (*gitlab.PipelineTrigger, error) {
	
	// Create Trigger
	addPipelineOptions := &gitlab.AddPipelineTriggerOptions {
		Description: gitlab.String("Pipeline trigger for Scalable Gitlab Runner Module"),
	}
	
	newPipelineTrigger, _, err := client.PipelineTriggers.AddPipelineTrigger(gitlabProjectId, addPipelineOptions)

	if err != nil {
		return nil, fmt.Errorf("Could not create pipeline trigger", err)
	}

	// Trigger
	opt := &gitlab.RunPipelineTriggerOptions {
		Ref: gitlab.String(gitlabBranch),
		Token: gitlab.String(newPipelineTrigger.Token),
	}
	
	pipelines, _, err := client.PipelineTriggers.RunPipelineTrigger("33153506", opt)

	if err != nil {
		return nil, fmt.Errorf("Could not trigger pipeline trigger", err)
	}

	fmt.Errorf("Could not trigger pipeline trigger", pipelines)

	return newPipelineTrigger, nil
}

func TestCIRunners(t *testing.T, opt *TestScalableGitlabRunnerOptions, assertions func (t *testing.T, terraformOptions *terraform.Options)) {
	// runnerTag := opt.RunnerTag
	terraformOptions := opt.TerraformOptions
	cleanUp := os.Getenv("CLEANUP") != "false"

	// Get the token from Environment Variables
	gitlabToken, err := getGitlabTokenFromEnvironmentVariables()
	require.NoError(t, err)

	// Create the gitlab AP client early to catch errors
	client, err := createGitlabApiClient(gitlabToken)
	require.NoError(t, err)

	
	// Remove the lock file so we get the latest providers each time
	lockFilePath := filepath.Join(terraformOptions.TerraformDir, ".terraform.lock.hcl")
	os.Remove(lockFilePath)
	
	// Create resources
	// Run "terraform init" and "terraform apply". Fail the test if there are any errors.
	terraform.InitAndApply(t, terraformOptions)
	
	// // Allow time for the runner to become active
	waitSeconds := 10
	fmt.Printf("\nWaiting %v seconds to allow the runner to become active...\n\n", waitSeconds)
	time.Sleep(time.Duration(waitSeconds) * time.Second)
	
	trigger, err := triggerGitlabPipeline(client, "33153506", "develop", gitlabToken)
	require.NoError(t, err)

	if (cleanUp) {
		// Clean up resources at the end of the test.
		defer client.PipelineTriggers.DeletePipelineTrigger("33153506", trigger.ID)
		defer terraform.Destroy(t, terraformOptions)
	}

	// // Get runners with the specified tag
	// tags := []string{runnerTag}
	// runners, _, err := client.Runners.ListRunners(&gitlab.ListRunnersOptions{
	// 	TagList: &tags,
	// })
	// require.NoError(t, err)

	// // There should be the same number as specified via the instance_count terraform variable
	// assert.Equal(t, len(runners), instanceCount, "Checking expected number of registered runners")

	// fmt.Printf("Verifying status of %v runners with tag: %v\n\n", len(runners), tags)
	// var runnerIds []int
	// for _, runner := range runners {
	// 	runnerIds = append(runnerIds, runner.ID)

	// 	fmt.Printf("Description: %v\n", runner.Description)
	// 	fmt.Printf("Name: %v\n", runner.Name)
	// 	fmt.Printf("Active: %v\n", runner.Active)
	// 	fmt.Printf("Online: %v\n", runner.Online)
	// 	fmt.Printf("Status: %v\n", runner.Status)

	// 	fmt.Println("---")

	// 	assert.True(t, runner.Active, "Expecting runner to be active")
	// 	assert.True(t, runner.Online, "Expecting runner to be online")
	// 	assert.Equal(t, "online", runner.Status, "Expecting runner status to be online")
	// }

	// if (cleanUp) {
	// 	fmt.Println("Deleting regsitered runners...")
	// 	for _, runnerId := range runnerIds {
	// 		fmt.Printf("Deleting runner: %v\n", runnerId)
	// 		_, err := client.Runners.DeleteRegisteredRunnerByID(runnerId, nil)
	
	// 		if err != nil {
	// 			fmt.Printf("Failed to delete runner: %v\n", runnerId)
	// 			fmt.Println(err)
	// 		}
	// 	}
	// }

	const retryInterval = 1 * time.Second
	const retryTimeout = 30 * time.Second
	wait.PollImmediate(retryInterval, retryTimeout, func() (bool, error) {
		list, err := listVMInstancesForProject(opt.ProjectID, "europe-west1-d")
		if err != nil {
			fmt.Printf("%v:\n", err)
		}
		return len(list) >= 1, nil
	})

	// // Exit code 2 means there are changes in the plan
	// // Exit code 1 means there was an error in the plan
	exit_code := terraform.PlanExitCode(t, terraformOptions)
	assert.Equal(t, 0, exit_code, "Expecting plan with no changes")

	// // Run assertions before the terraform resources are destroyed
	// assertions(t, terraformOptions)
}
