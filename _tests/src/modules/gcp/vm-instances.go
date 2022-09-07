package rmgcp

import (
	"context"
	"log"
	"strings"

	compute "cloud.google.com/go/compute/apiv1"
	"google.golang.org/api/iterator"
	computepb "google.golang.org/genproto/googleapis/cloud/compute/v1"
)

/**
Function queries the GCP VM instances endpoint and retrieves a list of VM's that are currently running in the project
Uses the default GCP project
*/
func ListVMInstancesForProject(projectID string, zone string, runnerMachineName string) ([]string, error) {
	arr := []string{}
	ctx := context.Background()
	instancesClient, err := compute.NewInstancesRESTClient(ctx)
	
	if err != nil {
		return nil, err
	}
	defer instancesClient.Close()

req := &computepb.ListInstancesRequest{
		Project: projectID,
		Zone:    zone,
	}

	log.Println("Checking for VM Instances in zone", zone)
	it := instancesClient.List(ctx, req)
	for {
		instance, err := it.Next()
		if err == iterator.Done {
			break
		}
		if err != nil {
			return nil, err
		}
		log.Printf("Found VM Instance %s\n", instance.GetName())
		if strings.Contains(instance.GetName(), runnerMachineName) {
			arr = append(arr, instance.GetName())
		}
	}
	return arr, nil
}