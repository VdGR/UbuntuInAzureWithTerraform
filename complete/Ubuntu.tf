# Create public IP for Ubuntu
resource "azurerm_public_ip" "Ubuntu_publicip" {
  name                = "Ubuntu_publicip"
  location            = var.location
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
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "UbuntuIPConfig"
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
  
  location           = var.location
  enabled            = true

  daily_recurrence_time = var.daily_recurrence_time
  timezone              = var.timezone

  notification_settings {
    enabled         = false
    time_in_minutes = "60"
  }
}

# Create Ubuntu virtual machine
resource "azurerm_linux_virtual_machine" "UbuntuVM" {
  name                  = var.linux_virtual_machine_name
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.Ubuntu_nic.id]
  size                  = var.azure_size

  os_disk {      
    name                 = "${var.linux_virtual_machine_name}-os-disk"
    caching              = "ReadWrite"
    storage_account_type = var.storage_account_type
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name                   = var.linux_virtual_machine_name
  admin_username                  = var.linux_virtual_machine_admin_username
  admin_password                  = var.linux_virtual_machine_admin_password
  disable_password_authentication = false

 
  admin_ssh_key {
    username   = var.linux_virtual_machine_admin_username
    public_key = tls_private_key.Ubuntu_ssh.public_key_openssh
  }

  connection {
		type        = "ssh"
		host        = self.public_ip_address
		user        = var.linux_virtual_machine_admin_username
		password    = var.linux_virtual_machine_admin_password
		# Default timeout is 5 minutes
		timeout     = "4m"
  }

  provisioner "file" {
    source      = "./files/${var.bash-file}"
    destination = "/tmp/${var.bash-file}"
  }
  
  provisioner "remote-exec" {

    inline = [
      "chmod +x /tmp/${var.bash-file}",
      "sed -i -e 's/\r$//' /tmp/${var.bash-file}",
      "sudo bash /tmp/${var.bash-file}",
    ]
  }

}

