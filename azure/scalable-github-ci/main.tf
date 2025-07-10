locals {
  labels = length(var.runner_labels) > 0 ? "--labels ${join(",", var.runner_labels)}" : ""

  # Adapted from https://brendanthompson.com/posts/2021/09/github-actions-self-hosted-runner-on-azure
  install_github_runner_data = <<EOF
#cloud-config
runcmd:
- echo "Installing Docker"
- curl -sSL https://get.docker.com/ | sh
- [su, ${var.username}, -c, 'usermod -aG docker ${var.username}']
- echo "Downloading GitHub runner installer"
- [mkdir, '/actions-runner']
- cd /actions-runner
- [curl, -o, 'actions-runner.tar.gz', -L, 'https://github.com/actions/runner/releases/download/v${var.github_runner_version}/actions-runner-linux-x64-${var.github_runner_version}.tar.gz']
- [tar, -xzf, 'actions-runner.tar.gz']
- [chmod, -R, 777, '/actions-runner']
- echo "Retrieving GitHub runner token"
- "curl -s -X POST -H 'Accept: application/vnd.github+json' -H 'Authorization: Bearer ${var.github_api_token}' -H 'X-GitHub-Api-Version: 2022-11-28' 'https://api.github.com/repos/${var.github_organisation}/actions/runners/registration-token' > .runner_token_output"
- |
  cat .runner_token_output | sed -n 's/.*"token": "\([^"]*\)".*/\1/p' > .runner_token
- echo "Registering GitHub runner"
- export ACTIONS_RUNNER_INPUT_REPLACE=true
- [su, ${var.username}, -c, '/actions-runner/config.sh --url https://github.com/${var.github_organisation} --token $(cat /actions-runner/.runner_token) ${local.labels}']
- ./svc.sh install
- ./svc.sh start
- [rm, '/actions-runner/actions-runner.tar.gz']
EOF
}

# Ensures that the runner scale set is replaced if the provisioning script changes - sha256 to mask sensitive data
resource "terraform_data" "replace_runner" {
  input = sha256(local.install_github_runner_data)
}

data "azurerm_client_config" "current" {}

data "azurerm_subscription" "current" {}

data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}

resource "azurerm_virtual_network" "ci" {
  name                = "${data.azurerm_resource_group.this.name}-network"
  address_space       = var.network_address_space
  resource_group_name = data.azurerm_resource_group.this.name
  location            = var.primary_location
}

resource "azurerm_subnet" "ci" {
  name                 = "${data.azurerm_resource_group.this.name}-subnet"
  resource_group_name  = data.azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.ci.name
  address_prefixes     = var.network_subnet_address_prefixes
  service_endpoints    = var.subnet_service_endpoints
}

resource "azurerm_network_security_group" "ci" {
  name                = "${data.azurerm_resource_group.this.name}-nsg"
  location            = azurerm_virtual_network.ci.location
  resource_group_name = data.azurerm_resource_group.this.name

  security_rule {
    name                       = "ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = var.ssh_cidr_ranges
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "ci" {
  subnet_id                 = azurerm_subnet.ci.id
  network_security_group_id = azurerm_network_security_group.ci.id
}

resource "tls_private_key" "ci_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_storage_account" "this" {
  name                     = format("sa%s", replace(var.name, "-", ""))
  resource_group_name      = data.azurerm_resource_group.this.name
  location                 = data.azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
}

resource "azurerm_linux_virtual_machine_scale_set" "ci_box" {
  name           = "${var.name}-vm"
  instances      = 0
  admin_username = var.username

  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location

  sku = var.vm_size

  encryption_at_host_enabled = var.encryption_at_host_enabled

  source_image_reference {
    publisher = var.image_config.publisher
    offer     = var.image_config.offer
    sku       = var.image_config.sku
    version   = var.image_config.version
  }

  os_disk {
    caching              = "ReadWrite"
    disk_size_gb         = var.disk_size
    storage_account_type = "Standard_LRS"
  }

  disable_password_authentication = true
  admin_ssh_key {
    username   = var.username
    public_key = tls_private_key.ci_ssh.public_key_openssh
  }

  identity {
    type = "SystemAssigned"
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.this.primary_blob_endpoint
  }

  custom_data = base64encode(local.install_github_runner_data)

  network_interface {
    name    = "${data.azurerm_resource_group.this.name}-${var.name}-nic"
    primary = true

    ip_configuration {
      name      = "ci"
      primary   = true
      subnet_id = azurerm_subnet.ci.id
    }
  }

  scale_in {
    rule = var.scale_in_rule
  }

  lifecycle {
    ignore_changes = [instances]

    replace_triggered_by = [terraform_data.replace_runner]
  }
}

##################################
# Azure AutoScaler Container App #
##################################

resource "azurerm_log_analytics_workspace" "ci" {
  name                = "${var.name}-ci-logs"
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location
  sku                 = var.autoscaler_log_workspace_sku
  retention_in_days   = var.autoscaler_log_workspace_retention_in_days
}

resource "azurerm_container_app_environment" "ci" {
  name                       = "${var.name}-ci"
  resource_group_name        = data.azurerm_resource_group.this.name
  location                   = data.azurerm_resource_group.this.location
  log_analytics_workspace_id = azurerm_log_analytics_workspace.ci.id
}

resource "random_string" "github_secret" {
  length  = 32
  special = false
}

locals {
  secrets = [
    { name = "registry-password", value = sensitive(data.azurerm_container_registry.core.admin_password) },
    { name = "github-secret", value = random_string.github_secret.result },
    { name = "github-api-token", value = var.github_api_token },
    { name = "github-subscription-id", value = data.azurerm_subscription.current.subscription_id },
  ]
  envs = [
    { name = "GITHUB_SECRET", secret_name = "github-secret" },
    { name = "GITHUB_API_TOKEN", secret_name = "github-api-token" },
    { name = "AZURE_SUBSCRIPTION_ID", secret_name = "github-subscription-id" },
    { name = "AZURE_RESOURCE_GROUP_NAME", value = data.azurerm_resource_group.this.name },
    { name = "AZURE_VM_SCALE_SET_NAME", value = azurerm_linux_virtual_machine_scale_set.ci_box.name },
    { name = "MAX_RUNNERS", value = var.max_instance_count },
    { name = "SCALE_DOWN_RUNNERS", value = "true" },
    { name = "GITHUB_REPO", value = var.github_organisation },
  ]
}

resource "azurerm_container_app" "autoscaler" {
  name                         = "${var.name}-ci-autoscaler"
  container_app_environment_id = azurerm_container_app_environment.ci.id
  resource_group_name          = data.azurerm_resource_group.this.name
  revision_mode                = var.autoscaler_revision_mode

  template {
    container {
      name   = "main"
      image  = "ghcr.io/rocketmakers/github-autoscaler:${var.autoscaler_version}"
      cpu    = var.autoscaler_cpu
      memory = var.autoscaler_memory

      dynamic "env" {
        for_each = local.envs
        content {
          name        = env.value["name"]
          secret_name = try(env.value["secret_name"], null)
          value       = try(env.value["value"], null)
        }
      }
    }

    # We need min replicas otherwise GitHub will cancel the request while starting up
    min_replicas = 1
  }

  identity {
    type = "SystemAssigned"
  }

  dynamic "secret" {
    for_each = local.secrets
    content {
      name  = secret.value["name"]
      value = secret.value["value"]
    }
  }

  ingress {
    target_port      = 3000
    external_enabled = true
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}

resource "azurerm_role_assignment" "autoscaler_resource_group" {
  scope                = data.azurerm_resource_group.this.id
  role_definition_name = "Reader"
  principal_id         = azurerm_container_app.autoscaler.identity[0].principal_id
}

resource "azurerm_role_assignment" "autoscaler_resource_groupvmss" {
  scope                = azurerm_linux_virtual_machine_scale_set.ci_box.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_container_app.autoscaler.identity[0].principal_id
}


##################################
# Azure Container Registry access
##################################
data "azurerm_container_registry" "core" {
  name                = var.container_registry_name
  resource_group_name = var.container_registry_resource_group_name
}

resource "azurerm_role_assignment" "acr" {
  scope                = data.azurerm_container_registry.core.id
  role_definition_name = "AcrPush"
  principal_id         = azurerm_linux_virtual_machine_scale_set.ci_box.identity[0].principal_id
}
