package rmgitlab

import (
	"strings"
	"testing"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/xanzy/go-gitlab"
)

/**
Remove Gitlab test runners after Tests
*/
func RemoveGitlabTestRunners(client *gitlab.Client, t *testing.T, gitlabProjectId string, runnerName string) {
	listRunnersOptions := &gitlab.ListProjectRunnersOptions{}
	
	logger.Log(t, "Fetching Runners")
	runners,_, err := client.Runners.ListProjectRunners(gitlabProjectId, listRunnersOptions)
	
	if err != nil {
		logger.Logf(t, "\nError fetching runners %v", err)
	}

	for _, s := range runners {
		if strings.Contains(s.Description, runnerName) {
			logger.Logf(t, "\nRemoving Runner %v", s.ID)
			_, err := client.Runners.RemoveRunner(s.ID)
			if err != nil {
				logger.Logf(t, "\nError removing runner %v", err)
			}

			logger.Logf(t, "\nRemoved Runner %v", s.ID)
		}
	}
}