package awsgitlabci

import (
	"backendconfig"
	"fmt"
	"gitlabapi"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestAwsGitlabCi(t *testing.T) {
	// Construct the terraform options with default retryable errors to handle the most common
	// retryable errors in terraform testing.
	runnerTag := "aws-f91e8708-cc7c-4916-95aa-3f70a215b983"
	instanceCount := 2

	assumedCredentials, err := StsAssumeRole(&AwsAssumeRoleOptions{
		Region:      "eu-west-2",
		SessionName: "TerratestGitlabCI",
		RoleArn:     "arn:aws:iam::971573726931:role/internal-gitlab-runners-deployment",
	})

	if err != nil {
		fmt.Printf("Error assuming role: %v", err)
		return
	}

	backendConfigOptions := backendconfig.AwsBackendConfigOptions{
		Key: "gitlab-ci",
	}
	backendConfig := backendconfig.GetAwsBackendBucketConfig(&backendConfigOptions)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		BackendConfig: backendConfig,
		TerraformDir:  "../../../config/aws/gitlab-ci",
		Vars: map[string]interface{}{
			"runner_tag":     runnerTag,
			"instance_count": instanceCount,
			"aws_region":     "eu-west-2",

			"aws_access_key":    *assumedCredentials.AccessKeyId,
			"aws_secret_key":    *assumedCredentials.SecretAccessKey,
			"aws_session_token": *assumedCredentials.SessionToken,
		},
	})

	gitlabapi.TestGcpGitlabCi(t, &gitlabapi.TestGitlabRunnerOptions{
		RunnerTag:        runnerTag,
		InstanceCount:    instanceCount,
		TerraformOptions: terraformOptions,
	})

	fmt.Println("🚀 Done 🚀")
}
