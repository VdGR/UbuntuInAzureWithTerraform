variable "location" {
  type        = string
  description = "location"
}

variable "azure_size" {
  type        = string
  description = "Size of Azure"
  
}
variable "rg_name" {
  type        = string
  description = "name of resource group"
  
}

variable "vnet_name" {
  type        = string
  description = "name of vnet"
}

variable "subnet_name" {
  type        = string
  description = "name of subnet"
}

variable "storage_account_type" {
  type        = string
  description = "Storage account type"
  
}

variable "timezone" {
  type        = string
  description = "timezone"
  
}

variable "daily_recurrence_time" {
  type        = string
  description = "daily_recurrence_time for shutdown"
  
}

variable "linux_virtual_machine_name" {
  type        = string
  description = "Linux VM name in Azure"
}

variable "linux_virtual_machine_admin_username" {
  type        = string
  description = "Linux VM username"
}

variable "linux_virtual_machine_admin_password" {
  type        = string
  description = "Linux VM password"
}







