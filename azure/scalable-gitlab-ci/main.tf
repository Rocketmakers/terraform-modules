data "azurerm_client_config" "current" {}

data "azurerm_subscription" "current" {}

data "azurerm_resource_group" "ci" {
  name = var.resource_group_name
}

resource "azuread_application" "orchestrator" {
  display_name = "${var.resource_group_name}-orchestrator"
  owners       = [data.azurerm_client_config.current.object_id]
}

resource "azuread_service_principal" "orchestrator" {
  application_id = azuread_application.orchestrator.application_id
  owners         = [data.azurerm_client_config.current.object_id]
}

resource "azuread_service_principal_password" "orchestrator" {
  service_principal_id = azuread_service_principal.orchestrator.object_id
}

resource "azuread_application" "runner" {
  display_name = "${var.resource_group_name}-runner"
  owners       = [data.azurerm_client_config.current.object_id]
}

resource "azuread_service_principal" "runner" {
  application_id = azuread_application.runner.application_id
  owners         = [data.azurerm_client_config.current.object_id]
}

resource "azuread_service_principal_password" "runner" {
  service_principal_id = azuread_service_principal.runner.object_id
}

resource "azurerm_role_assignment" "orchestrator_subscription_reader" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Reader"
  principal_id         = azuread_service_principal.orchestrator.object_id
}

resource "azurerm_role_assignment" "orchestrator_resource_group_contributor" {
  scope                = data.azurerm_resource_group.ci.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.orchestrator.object_id
}

resource "azurerm_storage_account" "sa" {
  name                     = "${lower(replace(var.project_prefix, "/\\W/", ""))}cicache"
  resource_group_name      = data.azurerm_resource_group.ci.name
  location                 = data.azurerm_resource_group.ci.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "sc" {
  name                  = "${var.project_prefix}-ci-cache"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}

data "azurerm_key_vault_secret" "registration_token" {
  name         = var.registration_token_secret_name
  key_vault_id = var.registration_token_key_vault_id
}

module "shared_ci" {
  source                          = "../../shared/ci-provisioner-commands"
  name                            = azurerm_public_ip.ci.name
  username                        = var.username
  runner_tags                     = var.runner_tags
  gitlab_token                    = data.azurerm_key_vault_secret.registration_token.value
  gitlab_orchestrator_concurrency = var.gitlab_runner_concurrency
  gitlab_runner_version           = var.gitlab_runner_version
  gitlab_runner_docker_image      = var.gitlab_runner_docker_image
  gitlab_runner_locked            = var.gitlab_runner_locked
}

resource "azurerm_virtual_network" "ci" {
  name                = "${data.azurerm_resource_group.ci.name}-network"
  address_space       = var.network_address_space
  resource_group_name = data.azurerm_resource_group.ci.name
  location            = var.primary_location
}

resource "azurerm_subnet" "ci" {
  name                 = "${data.azurerm_resource_group.ci.name}-subnet"
  resource_group_name  = data.azurerm_resource_group.ci.name
  virtual_network_name = azurerm_virtual_network.ci.name
  address_prefixes     = var.network_subnet_address_prefixes
  service_endpoints    = var.subnet_service_endpoints
}

resource "azurerm_network_security_group" "ci" {
  name                = "${data.azurerm_resource_group.ci.name}-nsg"
  location            = azurerm_virtual_network.ci.location
  resource_group_name = data.azurerm_resource_group.ci.name

  security_rule {
    name                       = "ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = var.trusted_cidr_ranges
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "ci" {
  subnet_id                 = azurerm_subnet.ci.id
  network_security_group_id = azurerm_network_security_group.ci.id
}

resource "azurerm_public_ip" "ci" {
  name                = "${data.azurerm_resource_group.ci.name}-${var.name}"
  resource_group_name = data.azurerm_resource_group.ci.name
  location            = azurerm_network_security_group.ci.location
  allocation_method   = var.public_ip_allocation_method
  sku                 = var.public_ip_sku
}

resource "azurerm_network_interface" "ci" {
  name                = "${data.azurerm_resource_group.ci.name}-${var.name}-nic"
  resource_group_name = azurerm_subnet.ci.resource_group_name
  location            = azurerm_public_ip.ci.location

  ip_configuration {
    name                          = "ci-config"
    subnet_id                     = azurerm_subnet.ci.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ci.id
  }
}

resource "tls_private_key" "orchestrator_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

data "azurerm_key_vault" "core" {
  name                = var.key_vault_name
  resource_group_name = data.azurerm_resource_group.core.name
}

resource "azurerm_linux_virtual_machine" "ci_box" {
  name                            = "${var.project_prefix}-${var.name}-vm"
  resource_group_name             = data.azurerm_resource_group.ci.name
  location                        = azurerm_network_interface.ci.location
  network_interface_ids           = [azurerm_network_interface.ci.id]
  size                            = var.orchestrator_vm_size
  admin_username                  = var.username
  computer_name                   = "${var.project_prefix}-${var.name}"
  disable_password_authentication = true

  source_image_reference {
    publisher = var.image_config.publisher
    offer     = var.image_config.offer
    sku       = var.image_config.sku
    version   = var.image_config.version
  }

  os_disk {
    name                 = "${var.project_prefix}-${var.name}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = var.disk_size_gb
  }

  admin_ssh_key {
    username   = var.username
    public_key = tls_private_key.orchestrator_ssh.public_key_openssh
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "runner_subscription_contributor" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.runner.object_id
}

##################################
# Azure Container Registry Access
##################################
data "azurerm_resource_group" "core" {
  name = var.core_resource_group_name
}

data "azurerm_container_registry" "core" {
  name                = var.container_registry_name
  resource_group_name = data.azurerm_resource_group.core.name
}

resource "azurerm_role_assignment" "runner_acr_push" {
  scope                = data.azurerm_container_registry.core.id
  role_definition_name = "AcrPush"
  principal_id         = azuread_service_principal.runner.object_id
}

# We want to run this separately so that the instance is created and the internal ip is attached to azurerm_virtual_network.ci
# This allows us to run docker-machine create within our provisioning so that the ssh keys are created before multiple jobs try to start up instances
resource "null_resource" "orchestrator_provisioner" {
  triggers = {
    instance_id = azurerm_linux_virtual_machine.ci_box.id
  }

  provisioner "file" {
    connection {
      type        = "ssh"
      user        = var.username
      timeout     = "500s"
      private_key = tls_private_key.orchestrator_ssh.private_key_pem
      host        = azurerm_public_ip.ci.ip_address
    }

    content     = <<-EOF
  [[runners]]
    limit = ${var.gitlab_runner_concurrency}
    builds_dir = "/tmp/builds"
    [runners.docker]
      image = "${var.gitlab_runner_docker_image}"
      volumes = ["/var/run/docker.sock:/var/run/docker.sock", "/cache", "/tmp/builds:/tmp/builds"]
    [runners.machine]
      IdleCount = ${var.idle_count}
      IdleTime = ${var.idle_time_seconds}
      MaxBuilds = ${var.max_builds_per_machine}
      MachineName = "auto-scale-%s"
      MachineDriver = "azure"
      MachineOptions = [
        "azure-subscription-id=${data.azurerm_subscription.current.subscription_id}",
        "azure-location=${var.primary_location}",
        "azure-ssh-user=gitlab",
        "azure-size=${var.runner_vm_size}",
        "azure-resource-group=${data.azurerm_resource_group.ci.name}",
        "azure-vnet=${azurerm_virtual_network.ci.name}",
        "azure-subnet=${azurerm_subnet.ci.name}",
        "azure-use-private-ip",
        "azure-client-id=${azuread_application.orchestrator.application_id}",
        "azure-client-secret=${nonsensitive(azuread_service_principal_password.orchestrator.value)}",
        "engine-install-url=${var.engine_install_url}"
      ]
    [runners.cache]
      Type = "azure"
      Path = "gitlab-runner"
      Shared = true
      [runners.cache.azure]
        AccountName = "${azurerm_storage_account.sa.name}"
        AccountKey = "${nonsensitive(azurerm_storage_account.sa.primary_access_key)}"
        ContainerName = "${azurerm_storage_container.sc.name}"
        StorageDomain = "blob.core.windows.net"
EOF
    destination = module.shared_ci.config_template_path
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = var.username
      timeout     = "500s"
      private_key = tls_private_key.orchestrator_ssh.private_key_pem
      host        = azurerm_public_ip.ci.ip_address
    }

    inline = concat(
      module.shared_ci.init_docker,
      module.shared_ci.init_docker_machine,
      [
        nonsensitive("sudo -i docker-machine create --driver azure --azure-subscription-id ${data.azurerm_subscription.current.subscription_id} --azure-client-id ${azuread_application.orchestrator.application_id} --azure-client-secret ${azuread_service_principal_password.orchestrator.value} --azure-location ${var.primary_location} --azure-size ${var.runner_vm_size} --azure-ssh-user gitlab --azure-resource-group ${data.azurerm_resource_group.ci.name} --azure-vnet ${azurerm_virtual_network.ci.name} --azure-subnet ${azurerm_subnet.ci.name} --azure-use-private-ip --azure-no-public-ip --engine-install-url ${var.engine_install_url} test-runner"),
        "sudo -i docker-machine rm -y test-runner"
      ],
      module.shared_ci.init_gitlab_runner,
      module.shared_ci.register_gitlab_runner
    )
  }
}
