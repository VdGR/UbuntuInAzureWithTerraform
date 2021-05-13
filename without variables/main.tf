# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.26"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "TutorialRGA"
  location = "West Europe"
}

# Create a virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = "TutorialVnet"
  address_space       = ["192.168.0.0/16"]
  location            = "West Europe"
  resource_group_name = azurerm_resource_group.rg.name
}

# Create subnet
resource "azurerm_subnet" "subnet" {
  name                 = "TutorialSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["192.168.1.0/24"]
}

# Create Network Security Group for Linux
resource "azurerm_network_security_group" "Linux_nsg" {
  name                = "Linux_nsg"
  location            = "West Europe"
  resource_group_name = azurerm_resource_group.rg.name

  #SSH
  security_rule {
    name                       = "Allow-SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

 
}

# Create public IP for Ubuntu
resource "azurerm_public_ip" "Ubuntu_publicip" {
  name                = "Ubuntu_publicip"
  location            = "West Europe"
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

# Associate NSG with the NIC of Ubuntu
resource "azurerm_network_interface_security_group_association" "UbuntuNICNSG" {
  network_interface_id      = azurerm_network_interface.Ubuntu_nic.id
  network_security_group_id = azurerm_network_security_group.Linux_nsg.id
}

# Create network interface for Ubuntu
resource "azurerm_network_interface" "Ubuntu_nic" {
  name                = "Ubuntu_nic"
  location            = "West Europe"
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "UbuntuIpConfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = azurerm_public_ip.Ubuntu_publicip.id
  }
}

# Create SSH key for Ubuntu
resource "tls_private_key" "Ubuntu_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Auto shutdown for UbuntuVM
resource "azurerm_dev_test_global_vm_shutdown_schedule" "UbuntuVM-AutoShutdown" {
  virtual_machine_id = azurerm_linux_virtual_machine.UbuntuVM.id
  
  location           = "West Europe"
  enabled            = true

  daily_recurrence_time = "2000" 
  timezone              = "Central European Standard Time" 

  notification_settings {
    enabled         = false
    time_in_minutes = "60"
  }
}

# Create Ubuntu virtual machine
resource "azurerm_linux_virtual_machine" "UbuntuVM" {
  name                  = "Ubuntu"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.Ubuntu_nic.id]
  size                  = "Standard_B1ms"

  os_disk {      
    name                 = "Ubuntu-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name                   = "Ubuntu"
  admin_username                  = "Robin"
  admin_password                  = "User12345"
  disable_password_authentication = false

 
  admin_ssh_key {
    username   = "Robin"
    public_key = tls_private_key.Ubuntu_ssh.public_key_openssh
  }

}

