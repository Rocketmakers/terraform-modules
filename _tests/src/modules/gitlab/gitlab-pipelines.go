package rmgitlab

import (
	"log"

	"rmutils"

	"github.com/xanzy/go-gitlab"
)

/**
Create and trigger a Pipeline on the test project
*/
func CreateGitlabPipelineTrigger(client *gitlab.Client, gitlabProjectId string, gitlabBranch string, gitlabToken string) (*gitlab.PipelineTrigger, error) {

	// Create Trigger
	addPipelineOptions := &gitlab.AddPipelineTriggerOptions{
		Description: gitlab.String("Pipeline trigger for Scalable Gitlab Runner Module"),
	}

	newPipelineTrigger, _, err := client.PipelineTriggers.AddPipelineTrigger(gitlabProjectId, addPipelineOptions)

	if err != nil {
		log.Printf("Could not create pipeline trigger", err)
		return nil, err
	}

	return newPipelineTrigger, nil
}

/*
Check the status of the pipeline created as part of the test
*/
func HaveAllTestPipelinesSucceeded(client *gitlab.Client, gitlabProjectId string, pipelineIds []int) bool {
	arr := []bool{}
	for _, s := range pipelineIds {
		pipeline, _, err := client.Pipelines.GetPipeline(gitlabProjectId, s)
		if err != nil {
			log.Fatal(err)
		}

		log.Printf("Pipeline %v = %s\n", s, pipeline.Status)
		arr = append(arr, pipeline.Status == "success")
	}

	return rmutils.AllItemsTrue(arr) == len(pipelineIds)
}
