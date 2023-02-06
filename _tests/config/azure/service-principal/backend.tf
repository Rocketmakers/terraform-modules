terraform {
  # Config given in terratest code
  backend "azurerm" {
    container_name       = "terraform-modules-testing"
    key                  = "service-principal.tfstate"
    resource_group_name  = "Terratest"
    storage_account_name = "rocketmakersterratest"
    subscription_id      = "68bb123f-6027-4e99-8ab0-a01fb16cdd79"
    tenant_id            = "09e95bcb-540c-433b-8597-3e94ab4119e5"
    use_msi              = false
  }
}
