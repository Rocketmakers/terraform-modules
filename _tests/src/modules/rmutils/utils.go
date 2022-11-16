package rmutils

import (
	"net"
	"github.com/glendc/go-external-ip"
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


/**
Get the IP address of the current machine
*/
func GetMachineExternalIPAddress() (net.IP, error) {
	consensus := externalip.DefaultConsensus(nil, nil)
	return consensus.ExternalIP()
}