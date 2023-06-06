package azurescalablegitlabci

import (
	"backendconfig"
	"os"
	"path/filepath"
	"testing"
	"time"

	"rmgitlab"
	"rmutils"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/xanzy/go-gitlab"
	"k8s.io/apimachinery/pkg/util/wait"
	"github.com/gruntwork-io/terratest/modules/azure"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestAzureGitlabCi(t *testing.T) {
	runnerTag := "azure-3308e4b9-3e83-470e-bb39-9cca0666b0fc"
	gitlabMaxRunners := 3
	gitlabProjectId := "33153506"
	gitlabBranch := "develop"
	projectPrefix := "testing"
	runnerMachineName := "auto-scale-"
	primaryLocation := "West Europe"
	retryInterval := 5 * time.Second
	retryTimeout := 300 * time.Second
	numberOfPipelines := 5

	ipAddress, err := rmutils.GetMachineExternalIPAddress()
	require.NoError(t, err)

	backendConfigOptions := backendconfig.AzureBackendConfigOptions{
		Key: "scalable-gitlab-ci.tfstate",
	}
	backendConfig := backendconfig.GetAzureBackendBucketConfig(&backendConfigOptions)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		BackendConfig: backendConfig,
		TerraformDir:  "../../../config/azure/scalable-gitlab-ci",
		Vars: map[string]interface{}{
			"project_prefix":      projectPrefix,
			"runner_tag":          runnerTag,
			"gitlab_max_runners":  gitlabMaxRunners,
			"runner_machine_name": runnerMachineName + "%s",
			"cidr_range":          ipAddress.String() + "/32",
			"max_builds_per_machine": 3,
			"resource_group_name": backendConfig["resource_group_name"],
			"primary_location": primaryLocation,
		},
	})

	// Get the token from Environment Variables
	gitlabToken, err := rmgitlab.GetGitlabTokenFromEnvironmentVariables()
	require.NoError(t, err)

	// Create the gitlab AP client early to catch errors
	client, err := rmgitlab.CreateGitlabApiClient(gitlabToken)
	require.NoError(t, err)

	defer rmgitlab.RemoveGitlabTestRunners(client, t, gitlabProjectId, projectPrefix+"-ci")

	// Remove the lock file so we get the latest providers each time
	lockFilePath := filepath.Join(terraformOptions.TerraformDir, ".terraform.lock.hcl")
	os.Remove(lockFilePath)

	// This has to occur before the init stage https://github.com/gruntwork-io/terratest/issues/511#issuecomment-619873137
	defer terraform.Destroy(t, terraformOptions)

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
			"AZURE":"true",
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
		list := azure.GetVirtualMachinesForResourceGroup(t, backendConfig["resource_group_name"].(string), backendConfig["subscription_id"].(string))
		if len(list) == 0 {
			logger.Logf(t, "Currently no VM instances in Azure which include name %s\n", runnerMachineName)
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
	orchestrator_public_ip_address := terraform.Output(t, terraformOptions, "orchestrator_public_ip_address")
	assert.NotNil(t, orchestrator_public_ip_address)

	orchestrator_private_key := terraform.Output(t, terraformOptions, "orchestrator_private_key")
	assert.NotNil(t, orchestrator_private_key)

	runner_principal_id := terraform.Output(t, terraformOptions, "runner_principal_id")
	assert.NotNil(t, runner_principal_id)

	runner_client_id := terraform.Output(t, terraformOptions, "runner_client_id")
	assert.NotNil(t, runner_client_id)

	runner_client_secret := terraform.Output(t, terraformOptions, "runner_client_secret")
	assert.NotNil(t, runner_client_secret)

	logger.Log(t, "🚀 Done 🚀")
}
