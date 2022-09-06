package gitlabrunners

import (
	"context"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"
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
	GitLabProjectId  string
	ExpectedNumberOfInstances int
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

	log.Println("Checking for VM Instances in zone", zone)
	it := instancesClient.List(ctx, req)
	for {
					instance, err := it.Next()
					if err == iterator.Done {
						break
					}
					if err != nil {
						return nil, err
					}
					log.Printf("Found VM Instance %s", instance.GetName())
					if strings.Contains(instance.GetName(), "auto-scale-") {
						arr = append(arr, instance.GetName())
					}
	}
	return arr, nil
}

/**
	Create and trigger a Pipeline on the test project
*/
func createGitlabPipelineTrigger(client *gitlab.Client, gitlabProjectId string, gitlabBranch string, gitlabToken string) (*gitlab.PipelineTrigger, error) {
	
	// Create Trigger
	addPipelineOptions := &gitlab.AddPipelineTriggerOptions {
		Description: gitlab.String("Pipeline trigger for Scalable Gitlab Runner Module"),
	}
	
	newPipelineTrigger, _, err := client.PipelineTriggers.AddPipelineTrigger(gitlabProjectId, addPipelineOptions)

	if err != nil {
		return nil, fmt.Errorf("Could not create pipeline trigger", err)
	}
	
	return newPipelineTrigger, nil
}

func TestCIRunners(t *testing.T, opt *TestScalableGitlabRunnerOptions, assertions func (t *testing.T, terraformOptions *terraform.Options)) {
	terraformOptions := opt.TerraformOptions
	gitlabProjectId := opt.GitLabProjectId
	cleanUp := os.Getenv("CLEANUP") != "false"
	gitlabBranch := "develop"

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
	
	// Allow time for the runner to become active
	waitSeconds := 60
	fmt.Printf("\nWaiting %v seconds to allow the runner to become active...\n\n", waitSeconds)
	time.Sleep(time.Duration(waitSeconds) * time.Second)
	
	// Trigger multiple pipelines
	fmt.Printf("\nCreating Pipeline Triggers")
	trigger, err := createGitlabPipelineTrigger(client, gitlabProjectId, gitlabBranch, gitlabToken)
	require.NoError(t, err)

	// Trigger
	runPipelineTriggerOptions := &gitlab.RunPipelineTriggerOptions {
		Ref: gitlab.String(gitlabBranch),
		Token: gitlab.String(trigger.Token),
	}

	numberOfPipelines := 5
	// Trigger multiple jobs to ensure orchestrator creates multiple VM's
	for i := 0; i < numberOfPipelines; i++ {
		_, _, err := client.PipelineTriggers.RunPipelineTrigger(gitlabProjectId, runPipelineTriggerOptions)
		require.NoError(t, err)
	}

	if (cleanUp) {

		listPipelinesOptions := &gitlab.ListProjectPipelinesOptions {
			Source: gitlab.String("trigger"),
		}
		defer client.Pipelines.ListProjectPipelines(gitlabProjectId,listPipelinesOptions)

		// Clean up resources at the end of the test.
		defer client.PipelineTriggers.DeletePipelineTrigger(gitlabProjectId, trigger.ID)

		defer terraform.Destroy(t, terraformOptions)
	}

	const retryInterval = 1 * time.Second
	const retryTimeout = 30 * time.Second
	pollErr := wait.PollImmediate(retryInterval, retryTimeout, func() (bool, error) {
		list, err := listVMInstancesForProject(opt.ProjectID, "europe-west1-b")
		if err != nil {
			log.Printf("%s", err)
		}
		if len(list) == 0 {
			log.Println("Currently no VM instances in GCP which include name auto-scale-")
		}

		return len(list) >= opt.ExpectedNumberOfInstances, nil
	})

	assert.Equal(t, pollErr, nil, "Expecting to find VM's associated with the scalable CI");
	
	// Allow time for the runner to become active
	vmSpinDownWaitSeconds := 300
	fmt.Printf("\nWaiting %v seconds to allow the VM's to spin down...\n\n", vmSpinDownWaitSeconds)
	time.Sleep(time.Duration(vmSpinDownWaitSeconds) * time.Second)
	// // Exit code 2 means there are changes in the plan
	// // Exit code 1 means there was an error in the plan
	exit_code := terraform.PlanExitCode(t, terraformOptions)
	assert.Equal(t, 0, exit_code, "Expecting plan with no changes")
}
