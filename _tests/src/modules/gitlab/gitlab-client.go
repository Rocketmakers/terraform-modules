package rmgitlab

import (
	"fmt"
	"os"

	"github.com/xanzy/go-gitlab"
)

/**
Creates a Gitlab Api Client
*/
func CreateGitlabApiClient(token string) (*gitlab.Client, error) {
	return gitlab.NewClient(token)
}

/**
Get token from Environment Variables
*/
func GetGitlabTokenFromEnvironmentVariables() (string, error) {
	variableName := "GITLAB_TOKEN"
	gitlabApiToken := os.Getenv(variableName)
	if gitlabApiToken == "" {
		return "", fmt.Errorf("Missing %v variable", variableName)
	}
	return gitlabApiToken, nil
}
