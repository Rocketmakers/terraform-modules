package rmgitlab

import (
	"log"
	"strings"

	"github.com/xanzy/go-gitlab"
)

/**
Remove Gitlab test runners after Tests
*/
func RemoveGitlabTestRunners(client *gitlab.Client, gitlabProjectId string, runnerName string) {
	listRunnersOptions := &gitlab.ListProjectRunnersOptions{}
	
	log.Println("Fetching Runners")
	runners,_, err := client.Runners.ListProjectRunners(gitlabProjectId, listRunnersOptions)
	
	if err != nil {
		log.Printf("\nError fetching runners %v", err)
	}

	for _, s := range runners {
		if strings.Contains(s.Description, runnerName) {
			log.Printf("\nRemoving Runner %v", s.ID)
			_, err := client.Runners.RemoveRunner(s.ID)
			if err != nil {
				log.Printf("\nError removing runner %v", err)
			}

			log.Printf("\nRemoved Runner %v", s.ID)
		}
	}
}