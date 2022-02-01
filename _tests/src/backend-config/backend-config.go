package backendconfig

func GetGcsBackendBucketName() string {
	return "rocketmakers-terratest"
}

type AzureBackendConfigOptions struct {
	Key string
}

func GetAzureBackendBucketConfig(options *AzureBackendConfigOptions) map[string]interface{} {
	return map[string]interface{}{
		"resource_group_name":  "Terratest",
		"storage_account_name": "rocketmakersterratest",
		"container_name":       "terraform-modules-testing",
		"use_msi":              false,
		"subscription_id":      "68bb123f-6027-4e99-8ab0-a01fb16cdd79",
		"tenant_id":            "09e95bcb-540c-433b-8597-3e94ab4119e5",
		"key":                  options.Key,
	}
}
