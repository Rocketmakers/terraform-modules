package awsgitlabci

import (
	"fmt"
	"os"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/sts"
)

func ensureEnvironment(varName string) error {
	varValue := os.Getenv(varName)
	if varValue == "" {
		return fmt.Errorf("Missing %v variable\n", varName)
	}
	return nil
}

type AwsAssumeRoleOptions struct {
	Region      string
	SessionName string
	RoleArn     string
}

// Usage:
// go run sts_assume_role.go
func StsAssumeRole(options *AwsAssumeRoleOptions) (*sts.Credentials, error) {
	err := ensureEnvironment("AWS_ACCESS_KEY_ID")
	if err != nil {
		return nil, err
	}
	err = ensureEnvironment("AWS_SECRET_ACCESS_KEY")
	if err != nil {
		return nil, err
	}

	// Initialize a session in us-west-2 that the SDK will use to load
	// credentials from the shared credentials file ~/.aws/credentials.
	sess, err := session.NewSession(&aws.Config{
		Region: &options.Region,
	})

	if err != nil {
		fmt.Println("NewSession Error", err)
		return nil, err
	}

	// Create a STS client
	svc := sts.New(sess)

	roleToAssumeArn := options.RoleArn
	sessionName := options.SessionName
	result, err := svc.AssumeRole(&sts.AssumeRoleInput{
		RoleArn:         &roleToAssumeArn,
		RoleSessionName: &sessionName,
	})

	if err != nil {
		fmt.Println("AssumeRole Error", err)
		return nil, err
	}

	return result.Credentials, nil
}
