data "azurerm_client_config" "current" {}

data "azurerm_subscription" "current" {}

data "azurerm_resource_group" "core" {
  name = var.resource_group
}

module "shared_ci" {
  source                     = "../../shared/ci"
  names                      = tolist(azurerm_public_ip.ci[*].name)
  username                   = local.username
  runner_tags                = local.runner_tags
  gitlab_token               = var.runner_registration_token
  gitlab_runner_concurrency  = var.gitlab_runner_concurrency
  gitlab_runner_version      = var.gitlab_runner_version
  gitlab_runner_docker_image = var.gitlab_runner_docker_image
  gitlab_runner_locked       = var.gitlab_runner_locked
  docker_prune_cron_schedule = var.docker_prune_cron_schedule
}

resource "azurerm_virtual_network" "ci" {
  name                = "${data.azurerm_resource_group.core.name}-network"
  address_space       = var.network_address_space
  resource_group_name = data.azurerm_resource_group.core.name
  location            = var.primary_location
}

resource "azurerm_subnet" "ci" {
  name                 = "${data.azurerm_resource_group.core.name}-subnet"
  resource_group_name  = data.azurerm_resource_group.core.name
  virtual_network_name = azurerm_virtual_network.ci.name
  address_prefixes     = var.network_subnet_address_prefixes
}

resource "azurerm_network_security_group" "ci" {
  name                = "${data.azurerm_resource_group.core.name}-nsg"
  location            = azurerm_virtual_network.ci.location
  resource_group_name = data.azurerm_resource_group.core.name

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

resource "azurerm_public_ip" "ci" {
  count               = var.instance_count
  name                = "${data.azurerm_resource_group.core.name}-ci-${count.index + 1}"
  resource_group_name = data.azurerm_resource_group.core.name
  location            = azurerm_network_security_group.ci.location
  allocation_method   = var.public_ip_allocation_method
  sku                 = var.public_ip_sku
}

resource "azurerm_network_interface" "ci" {
  count               = var.instance_count
  name                = "${data.azurerm_resource_group.core.name}-nic-${count.index + 1}"
  resource_group_name = azurerm_subnet.ci.resource_group_name
  location            = azurerm_public_ip.ci[count.index].location

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.ci.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.ci[count.index].id
  }
}

resource "tls_private_key" "ci_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

data "azurerm_key_vault" "core" {
  name                = var.key_vault_name
  resource_group_name = data.azurerm_resource_group.core.name
}

resource "azurerm_virtual_machine" "ci_box" {
  count                 = var.instance_count
  name                  = "${var.project_prefix}-ci-vm-${count.index + 1}"
  resource_group_name   = data.azurerm_resource_group.core.name
  location              = azurerm_network_interface.ci[count.index].location
  network_interface_ids = [azurerm_network_interface.ci[count.index].id]
  vm_size               = var.vm_size

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  # If we don't do this and we destroy our CI box, then we'll be unable to recreate it as the disk will
  # already exist
  delete_os_disk_on_termination = true

  storage_os_disk {
    name              = "${var.project_prefix}-ci-${count.index + 1}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.project_prefix}-ci-${count.index + 1}"
    admin_username = local.username
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/app/.ssh/authorized_keys"
      key_data = tls_private_key.ci_ssh.public_key_openssh
    }
  }

  identity {
    type = "SystemAssigned"
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = local.username
      timeout     = "500s"
      private_key = tls_private_key.ci_ssh.private_key_pem
      host        = azurerm_public_ip.ci[count.index].ip_address
    }

    inline = module.shared_ci.provisioner_commands[count.index]
  }
}

###################
# Key vault access
###################
resource "azurerm_key_vault_access_policy" "ci" {
  count = var.instance_count

  key_vault_id = data.azurerm_key_vault.core.id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = azurerm_virtual_machine.ci_box[count.index].identity[0].principal_id

  key_permissions = [
    "get",
    "decrypt",
    "list",
  ]

  secret_permissions = [
    "get",
    "list",
  ]
}

resource "azurerm_role_assignment" "ci" {
  count                = var.instance_count
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Reader"
  principal_id         = azurerm_virtual_machine.ci_box[count.index].identity[0].principal_id
}

##################################
# Azure Container Registry access
##################################
data "azurerm_container_registry" "core" {
  name                = var.container_registry_name
  resource_group_name = data.azurerm_resource_group.core.name
}

resource "azurerm_role_assignment" "acr" {
  count                = var.instance_count
  scope                = data.azurerm_container_registry.core.id
  role_definition_name = "AcrPush"
  principal_id         = azurerm_virtual_machine.ci_box[count.index].identity[0].principal_id
}

locals {
  runner_tags            = concat([var.project_prefix], var.runner_tags)
  username               = "app"
}
