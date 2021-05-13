
resource "local_file" "Ubuntu_private_key" {
    content  = tls_private_key.Ubuntu_ssh.private_key_pem 
    filename = "Ubuntu_private_key.pem"
}

output "Ubuntu_ip" {
  value = azurerm_linux_virtual_machine.UbuntuVM.public_ip_address
}
output "Ubuntu_username" {
  value = azurerm_linux_virtual_machine.UbuntuVM.admin_username
}
output "Ubuntu_password" {
  value = azurerm_linux_virtual_machine.UbuntuVM.admin_password
}





