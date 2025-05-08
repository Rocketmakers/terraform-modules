locals {
  labels = length(var.runner_labels) > 0 ? "--labels ${join(",", var.runner_labels)}" : ""

  # Adapted from https://brendanthompson.com/posts/2021/09/github-actions-self-hosted-runner-on-azure
  install_github_runner_data = <<EOF
#cloud-config
runcmd:
- echo "Installing Docker"
- curl -sSL https://get.docker.com/ | sh
- [su, ${var.username}, -c, 'usermod -aG docker ${var.username}']
- echo "Setting up Docker prune"
- (crontab -l 2>/dev/null; echo '${var.docker_prune_cron_schedule} docker system prune -f -a --volumes') | crontab -
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
  instances      = 1
  admin_username = var.username

  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location

  sku = var.vm_size

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

  lifecycle {
    ignore_changes = [instances]

    replace_triggered_by = [terraform_data.replace_runner]
  }
}

resource "azurerm_monitor_autoscale_setting" "ci" {
  name                = "${var.name}-vm-autoscale"
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.ci_box.id

  profile {
    name = "default"

    capacity {
      default = 1
      minimum = var.min_instance_count
      maximum = var.max_instance_count
    }

    rule {
      metric_trigger {
        metric_name              = "Percentage CPU"
        metric_resource_id       = azurerm_linux_virtual_machine_scale_set.ci_box.id
        time_grain               = "PT1M"
        statistic                = "Average"
        time_window              = "PT5M"
        time_aggregation         = "Average"
        operator                 = "GreaterThan"
        threshold                = var.autoscale_max_cpu_percentage
        metric_namespace         = "microsoft.compute/virtualmachinescalesets"
        divide_by_instance_count = true
      }

      scale_action {
        direction = "Increase"
        type      = "ExactCount"
        value     = var.max_instance_count
        cooldown  = var.autoscale_max_cooldown
      }
    }

    rule {
      metric_trigger {
        metric_name              = "Percentage CPU"
        metric_resource_id       = azurerm_linux_virtual_machine_scale_set.ci_box.id
        time_grain               = "PT1M"
        statistic                = "Average"
        time_window              = "PT15M"
        time_aggregation         = "Average"
        operator                 = "LessThan"
        threshold                = var.autoscale_min_cpu_percentage
        divide_by_instance_count = true
      }

      scale_action {
        direction = "Decrease"
        type      = "ExactCount"
        value     = var.min_instance_count
        cooldown  = var.autoscale_min_cooldown
      }
    }
  }
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
