# Define the Azure provider
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
}

# Generate a random index to create a globally unique name
resource "random_id" "randomId" {
  byte_length = 8
}

# Create a resource group 
resource "azurerm_resource_group" "rg" {
  name     = "FileShare-RG-${random_id.randomId.hex}"
  location = "North Europe"
}

# Create a storage account
resource "azurerm_storage_account" "sa" {
  name                     = "mysa${random_id.randomId.hex}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# File Share
resource "azurerm_storage_share" "ss" {
  name                 = "myfileshare"
  storage_account_name = azurerm_storage_account.sa.name
  quota                = 5
}

# Output Connection Details for Mounting
output "connection_string" {
  value = azurerm_storage_account.sa.primary_connection_string
  sensitive = true
}

output "file_share_mount_command_windows" {
  value = "net use Z: \\${azurerm_storage_account.sa.name}.file.core.windows.net\\myfileshare /u:${azurerm_storage_account.sa.name} ${azurerm_storage_account.sa.primary_access_key}"
  sensitive = true
}

output "file_share_mount_command_linux" {
  value = "sudo mount -t cifs //${azurerm_storage_account.sa.name}.file.core.windows.net/myfileshare /mnt/myfileshare -o vers=3.0,username=${azurerm_storage_account.sa.name},password=${azurerm_storage_account.sa.primary_access_key},dir_mode=0777,file_mode=0777,serverino"
  sensitive = true
}