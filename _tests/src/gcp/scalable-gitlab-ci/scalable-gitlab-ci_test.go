package gcpscalablegitlabci

import (
	"backendconfig"
	"os"
	"path/filepath"
	"testing"
	"time"

	"rmgcp"
	"rmgitlab"
	"rmutils"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/xanzy/go-gitlab"
	"k8s.io/apimachinery/pkg/util/wait"

	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestGcpGitlabCi(t *testing.T) {
	// Construct the terraform options with default retryable errors to handle the most common
	// retryable errors in terraform testing.
	runnerTag := "gcp-6faab9c3-9d73-4d51-ad84-d777b2d0cef0"
	gitlabMaxRunners := 3
	gitlabProjectId := "33153506"
	gcpProjectId := "terraform-testing-317911"
	gitlabBranch := "develop"
	projectPrefix := "testing"
	gcpProjectZone := "europe-west1-b"
	gcpProjectRegion := "europe-west1"
	runnerMachineName := "auto-scale-"
	retryInterval := 5 * time.Second
	retryTimeout := 300 * time.Second
	numberOfPipelines := 5

	ipAddress, err := rmutils.GetMachineExternalIPAddress()
	require.NoError(t, err)

	backendConfigOptions := backendconfig.GcsBackendConfigOptions{
		Prefix: "gcp/scalable-gitlab-ci",
	}
	backendConfig := backendconfig.GetGcsBackendBucketConfig(&backendConfigOptions)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		BackendConfig: backendConfig,
		TerraformDir:  "../../../config/gcp/scalable-gitlab-ci",
		Vars: map[string]interface{}{
			"project_prefix":      projectPrefix,
			"runner_tag":          runnerTag,
			"gcp_project_region":  gcpProjectRegion,
			"gcp_project_zone":    gcpProjectZone,
			"gitlab_max_runners":  gitlabMaxRunners,
			"runner_machine_name": runnerMachineName + "%s",
			"cidr_range":          ipAddress.String() + "/32",
		},
	})

	cleanUp := os.Getenv("CLEANUP_AFTER_TESTS") != "false"

	// Get the token from Environment Variables
	gitlabToken, err := rmgitlab.GetGitlabTokenFromEnvironmentVariables()
	require.NoError(t, err)

	// Create the gitlab AP client early to catch errors
	client, err := rmgitlab.CreateGitlabApiClient(gitlabToken)
	require.NoError(t, err)

	
	// Remove the lock file so we get the latest providers each time
	lockFilePath := filepath.Join(terraformOptions.TerraformDir, ".terraform.lock.hcl")
	os.Remove(lockFilePath)
	
	if (cleanUp) {
		defer rmgitlab.RemoveGitlabTestRunners(client, t, gitlabProjectId, projectPrefix+"-ci")
		// This has to occur before the init stage https://github.com/gruntwork-io/terratest/issues/511#issuecomment-619873137
		defer terraform.Destroy(t, terraformOptions)
	}

	// Create resources
	// Run "terraform init" and "terraform apply". Fail the test if there are any errors.
	terraform.InitAndApply(t, terraformOptions)

	// Allow time for the runner to become active
	waitSeconds := 60
	logger.Logf(t, "\nWaiting %v seconds to allow the runner to become active...\n\n", waitSeconds)
	time.Sleep(time.Duration(waitSeconds) * time.Second)

	// Trigger multiple pipelines
	logger.Log(t, "\nCreating Pipeline Triggers\n")
	trigger, err := rmgitlab.CreateGitlabPipelineTrigger(client, t, gitlabProjectId, gitlabBranch, gitlabToken)
	require.NoError(t, err)

	// Trigger
	runPipelineTriggerOptions := &gitlab.RunPipelineTriggerOptions{
		Ref:   gitlab.String(gitlabBranch),
		Token: gitlab.String(trigger.Token),
		Variables: map[string]string{
			"GCP":"true",
		},
	}

	pipelineIds := []int{}
	// Trigger multiple jobs to ensure orchestrator creates multiple VM's
	for i := 0; i < numberOfPipelines; i++ {
		pipeline, _, err := client.PipelineTriggers.RunPipelineTrigger(gitlabProjectId, runPipelineTriggerOptions)
		require.NoError(t, err)
		pipelineIds = append(pipelineIds, pipeline.ID)
	}

	defer client.PipelineTriggers.DeletePipelineTrigger(gitlabProjectId, trigger.ID)

	instancePollErr := wait.PollImmediate(retryInterval, retryTimeout, func() (bool, error) {
		list, err := rmgcp.ListVMInstancesForProject(t, gcpProjectId, gcpProjectZone, runnerMachineName)
		if err != nil {
			logger.Logf(t, "%s", err)
		}
		if len(list) == 0 {
			logger.Logf(t, "Currently no VM instances in GCP which include name %s\n", runnerMachineName)
		}

		return len(list) >= gitlabMaxRunners, nil
	})

	assert.NoError(t, instancePollErr, "Expecting to find VM's associated with the scalable CI")

	logger.Log(t, "Checking Pipelines Succeed")
	pipelineSucceededErr := wait.PollImmediate(retryInterval, retryTimeout, func() (bool, error) {
		return rmgitlab.HaveAllTestPipelinesSucceeded(client, t, gitlabProjectId, pipelineIds), nil
	})

	assert.NoError(t, pipelineSucceededErr, "Expecting to all test pipelines to succeed")

	logger.Logf(t, "\nWaiting %v to allow the VM's to spin down...\n\n", retryTimeout)
	time.Sleep(retryTimeout)

	// // Exit code 2 means there are changes in the plan
	// // Exit code 1 means there was an error in the plan
	exit_code := terraform.PlanExitCode(t, terraformOptions)
	assert.Equal(t, 0, exit_code, "Expecting plan with no changes")

	// Run assertions before the terraform resources are destroyed
	orchestrator_service_account_key := terraform.Output(t, terraformOptions, "orchestrator_service_account_key")
	assert.NotNil(t, orchestrator_service_account_key)

	orchestrator_service_account_email := terraform.Output(t, terraformOptions, "orchestrator_service_account_email")
	assert.NotNil(t, orchestrator_service_account_email)

	runner_service_account_key := terraform.Output(t, terraformOptions, "runner_service_account_key")
	assert.NotNil(t, runner_service_account_key)

	runner_service_account_email := terraform.Output(t, terraformOptions, "runner_service_account_email")
	assert.NotNil(t, runner_service_account_email)

	logger.Log(t, "🚀 Done 🚀")
}
