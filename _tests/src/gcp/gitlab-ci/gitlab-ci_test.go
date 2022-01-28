package gitlabci

import (
	"context"
	"fmt"
	"hash/crc32"
	"os"
	"testing"
	"time"

	b64 "encoding/base64"

	kms "cloud.google.com/go/kms/apiv1"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/xanzy/go-gitlab"
	kmspb "google.golang.org/genproto/googleapis/cloud/kms/v1"
	"google.golang.org/protobuf/types/known/wrapperspb"
)

func decryptSymmetric(kmsKey string, ciphertextBase64 string) (string, error) {
	// Convert from base64 encoded string to byte array
	ciphertext, err := b64.StdEncoding.DecodeString(ciphertextBase64)
	if err != nil {
		return "", fmt.Errorf("failed to base64 decode the ciphertext: %v", err)
	}
	ciphertextBytes := []byte(ciphertext)

	// Create the client.
	ctx := context.Background()
	client, err := kms.NewKeyManagementClient(ctx)
	if err != nil {
		return "", fmt.Errorf("failed to create kms client: %v", err)
	}
	defer client.Close()

	// Optional, but recommended: Compute ciphertext's CRC32C.
	crc32c := func(data []byte) uint32 {
		t := crc32.MakeTable(crc32.Castagnoli)
		return crc32.Checksum(data, t)
	}
	ciphertextCRC32C := crc32c(ciphertextBytes)

	// Build the request.
	req := &kmspb.DecryptRequest{
		Name:             kmsKey,
		Ciphertext:       ciphertextBytes,
		CiphertextCrc32C: wrapperspb.Int64(int64(ciphertextCRC32C)),
	}

	// Call the API.
	result, err := client.Decrypt(ctx, req)
	if err != nil {
		return "", fmt.Errorf("failed to decrypt ciphertext: %v", err)
	}

	// Optional, but recommended: perform integrity verification on result.
	// For more details on ensuring E2E in-transit integrity to and from Cloud KMS visit:
	// https://cloud.google.com/kms/docs/data-integrity-guidelines
	if int64(crc32c(result.Plaintext)) != result.PlaintextCrc32C.Value {
		return "", fmt.Errorf("Decrypt: response corrupted in-transit")
	}

	return string(result.Plaintext), nil
}

func createGitlabApiClient() (*gitlab.Client, error) {
	gitlabApiToken := os.Getenv("GITLAB_API_TOKEN")
	return gitlab.NewClient(gitlabApiToken)
}

func expectRunnersWithTags(t *testing.T, client *gitlab.Client, tags []string) {
	runners, _, err := client.Runners.ListRunners(&gitlab.ListRunnersOptions{
		TagList: &tags,
	})
	require.NoError(t, err)

	fmt.Printf("Found %v runners with tags: %v\n\n", len(runners), tags)
	assert.Greater(t, len(runners), 0)

	for _, runner := range runners {
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
}

func TestGcpGitlabCi(t *testing.T) {
	// Construct the terraform options with default retryable errors to handle the most common
	// retryable errors in terraform testing.
	runnerTag := "gcp-d7500544-e29d-451b-bd3f-083065f46b67"
	encryptedGitlabToken := "CiQA8kio5uT0OO1WRtZMB6V9zrDpLcFF92VrK6tLLY7XOr4TG94SPQD9t8BCTtEelpIo1iTjjtDH5Vm3x6lE0ftB/9l/cex5zaYUWKr8Gpw3AgbNZIkE/DV1n6ZCqg6E3D0ee7o="
	kmsKeyName := "projects/rocketmakers-developers/locations/europe-west2/keyRings/rocketmakers-secrets/cryptoKeys/rocketmakers-secrets"

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		// Set the path to the Terraform code that will be tested.
		TerraformDir: "../../../config/gcp/gitlab-ci",

		Vars: map[string]interface{}{
			"runner_tag":             runnerTag,
			"encrypted_gitlab_token": encryptedGitlabToken,
			"crypto_key_self_link":   kmsKeyName,
		},
	})

	gitlabToken, err := decryptSymmetric(kmsKeyName, encryptedGitlabToken)
	require.NoError(t, err)

	client, err := createGitlabApiClient()

	// Clean up resources at the end of the test.
	// TODO: Replace with DeleteRegisteredRunnerByID using the ID from expectRunnersWithTags
	defer client.Runners.DeleteRegisteredRunner(&gitlab.DeleteRegisteredRunnerOptions{
		Token: &gitlabToken,
	})
	defer terraform.Destroy(t, terraformOptions)

	// Create resources
	// Run "terraform init" and "terraform apply". Fail the test if there are any errors.
	terraform.InitAndApply(t, terraformOptions)

	// Allow time for the runner to become active
	waitSeconds := 10
	fmt.Printf("Waiting %v seconds to allow the runner to become active...", waitSeconds)
	time.Sleep(time.Duration(waitSeconds) * time.Second)

	// Check the runner is active
	expectRunnersWithTags(t, client, []string{runnerTag})

	// TODO: Check there are no resources after destroying at the end of the test?
}
