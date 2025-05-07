package rmutils

import (
	"net"
	"github.com/glendc/go-external-ip"
	"fmt"
	"os"
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

func WriteTfvarsFile(vars map[string]interface{}, fileName string) error {
	file, err := os.Create(fileName)
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

	return nil
}
