package azurescalablegitlabci

import (
	"backendconfig"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/xanzy/go-gitlab"
	"k8s.io/apimachinery/pkg/util/wait"

	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
)

func TestAzureGitlabCi(t *testing.T) {
	runnerTag := ""
	gitlabMaxRunners := 3
	gitlabProjectId := ""
	azureProjectId := ""
	gitlabBranch := "develop"
	projectPrefix := "testing"
	azureProjectZone := "europe-west1-b"
	azureProjectRegion := "europe-west1"
	runnerMachineName := "auto-scale-"
	retryInterval := 5 * time.Second
	retryTimeout := 300 * time.Second
	numberOfPipelines := 5

	backendConfigOptions := backendconfig.AzureBackendConfigOptions{
		Key: "gitlab-ci.tfstate",
	}
	backendConfig := backendconfig.GetAzureBackendBucketConfig(&backendConfigOptions)

}
