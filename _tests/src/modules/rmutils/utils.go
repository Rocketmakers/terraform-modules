package rmutils

import (
	"net"
	"github.com/glendc/go-external-ip"
	"fmt"
	"os"
	"path/filepath"
	"testing"

	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/stretchr/testify/require"
)

func AllItemsTrue(b []bool) int {
	n := 0
	for _, v := range b {
		if v {
			n++
		}
	}
	return n
}

/*
*
Get the IP address of the current machine
*/
func GetMachineExternalIPAddress() (net.IP, error) {
	consensus := externalip.DefaultConsensus(nil, nil)
	return consensus.ExternalIP()
}

func WriteTfvarsFile(t *testing.T, vars map[string]interface{}, fileName string) error {
	// Resolve the relative path to an absolute path
	absoluteVarsFilePath, err := filepath.Abs(fileName)
	require.NoError(t, err, "Failed to resolve absolute path for vars file")

	file, err := os.Create(absoluteVarsFilePath)
	if err != nil {
		return err
	}
	defer file.Close()

	for key, value := range vars {
		var valueStr string
		switch v := value.(type) {
		case string:
			valueStr = v
		case int:
			valueStr = fmt.Sprintf("%d", v)
		case float64:
			valueStr = fmt.Sprintf("%f", v)
		default:
			return fmt.Errorf("unsupported type for key %s: %T", key, value)
		}

		_, err := file.WriteString(fmt.Sprintf("%s = \"%s\"\n", key, valueStr))
		if err != nil {
			return err
		}
	}

	logger.Log(t, "Written vars file to ", absoluteVarsFilePath)
	if os.Getenv("WRITE_VARS_FILE_AND_EXIT") == "true" {
		t.Skip("Exiting early after writing vars file")
	}

	return nil
}
