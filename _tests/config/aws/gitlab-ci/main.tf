module gitlab_ci {
  source = "../../../../aws/gitlab-ci"

  availability_zones = ["a", "b"]
  cidr_ranges = [
    # Rocketmakers office
    "212.139.176.173",
  ]
  encrypted_gitlab_token = "AQICAHg12jDlvNJ/GP8ilAvSbzMZOODNi/D58G2Sh7CBISsa0AFHtysY2Cuhc5NayHFUbrREAAAAcjBwBgkqhkiG9w0BBwagYzBhAgEAMFwGCSqGSIb3DQEHATAeBglghkgBZQMEAS4wEQQMX8q5Dc4cX87WVxOXAgEQgC913jn8AJz6jtgSUdHWaftjgLR/V8ZhIUvU3gVzUPsN+Wydr3HDBhtz3fDRmPkv8Q=="
  project_prefix         = "terratest"

  # The following are provided via test code
  runner_tags    = [var.runner_tag]
  instance_count = var.instance_count
}
