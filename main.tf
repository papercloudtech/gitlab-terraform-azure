terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id != null ? var.azure_subscription_id : null
  tenant_id       = var.azure_tenant_id != null ? var.azure_tenant_id : null
  client_id       = var.azure_client_id != null ? var.azure_client_id : null
  client_secret   = var.azure_client_secret != null ? var.azure_client_secret : null
}


resource "azurerm_resource_group" "git-lab-rg" {
  name     = "git-lab-resources"
  location = var.resource_location
}

resource "azurerm_virtual_network" "gitlab-vnet" {
  name                = "git-lab-vn"
  resource_group_name = azurerm_resource_group.git-lab-rg.name
  location            = azurerm_resource_group.git-lab-rg.location
  address_space       = ["10.0.0.0/16"] # 255.255.0.0
}

resource "azurerm_subnet" "gitlab-subnet" {
  name                 = "wg-subnet"
  resource_group_name  = azurerm_resource_group.git-lab-rg.name
  virtual_network_name = azurerm_virtual_network.gitlab-vnet.name
  address_prefixes     = ["10.0.0.0/24"] # 255.255.255.0
}

resource "azurerm_network_security_group" "gitlab-securitygroup" {
  name                = "wg-nsg"
  resource_group_name = azurerm_resource_group.git-lab-rg.name
  location            = azurerm_resource_group.git-lab-rg.location
  security_rule {
    name                       = "AllgitlabPorts"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["22", "80", "443"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "wg-subnet-nsg" {
  subnet_id                 = azurerm_subnet.gitlab-subnet.id
  network_security_group_id = azurerm_network_security_group.gitlab-securitygroup.id
}

resource "azurerm_public_ip" "gitlab-publicip" {
  name                = "gitlabip"
  resource_group_name = azurerm_resource_group.git-lab-rg.name
  location            = azurerm_resource_group.git-lab-rg.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "gitlab-ni" {
  name                = "gitlab-ni"
  resource_group_name = azurerm_resource_group.git-lab-rg.name
  location            = azurerm_resource_group.git-lab-rg.location
  ip_configuration {
    name                          = "wg-ip-config"
    subnet_id                     = azurerm_subnet.gitlab-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.gitlab-publicip.id
  }
}

resource "azurerm_linux_virtual_machine" "gitlab-vm" {
  name                            = "gitlab-vm"
  resource_group_name             = azurerm_resource_group.git-lab-rg.name
  location                        = azurerm_resource_group.git-lab-rg.location
  size                            = var.vm_size 
  admin_username                  = var.ssh_username
  admin_password                  = var.ssh_password
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.gitlab-ni.id,
  ]

  admin_ssh_key {
    username   = var.ssh_username
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    name                 = "gitlab-os-disk"
    disk_size_gb         = 30
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
  custom_data = base64encode(templatefile("scripts/git-lab.sh", {root_password = var.gitlab_root_password,domain_name = var.domain_name}))
}

output "public_ip" {
  value = azurerm_linux_virtual_machine.gitlab-vm.public_ip_address
}

resource "local_file" "vm_ip" {
    content  = azurerm_linux_virtual_machine.gitlab-vm.public_ip_address
    filename = "outputs/vm_ip.txt"
}
