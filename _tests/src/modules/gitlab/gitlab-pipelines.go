package rmgitlab

import (
	"rmutils"
	"testing"
	"github.com/xanzy/go-gitlab"
	"github.com/gruntwork-io/terratest/modules/logger"
)

/**
Create and trigger a Pipeline on the test project
*/
func CreateGitlabPipelineTrigger(client *gitlab.Client, t *testing.T, gitlabProjectId string, gitlabBranch string, gitlabToken string) (*gitlab.PipelineTrigger, error) {

	// Create Trigger
	addPipelineOptions := &gitlab.AddPipelineTriggerOptions{
		Description: gitlab.String("Pipeline trigger for Scalable Gitlab Runner Module"),
	}

	newPipelineTrigger, _, err := client.PipelineTriggers.AddPipelineTrigger(gitlabProjectId, addPipelineOptions)

	if err != nil {
		logger.Logf(t, "Could not create pipeline trigger", err)
		return nil, err
	}

	return newPipelineTrigger, nil
}

/*
Check the status of the pipeline created as part of the test
*/
func HaveAllTestPipelinesSucceeded(client *gitlab.Client, t *testing.T, gitlabProjectId string, pipelineIds []int) bool {
	arr := []bool{}
	for _, s := range pipelineIds {
		pipeline, _, err := client.Pipelines.GetPipeline(gitlabProjectId, s)
		if err != nil {
			logger.Log(t, err)
		}

		logger.Logf(t, "Pipeline %v = %s\n", s, pipeline.Status)
		arr = append(arr, pipeline.Status == "success")
	}

	return rmutils.AllItemsTrue(arr) == len(pipelineIds)
}
