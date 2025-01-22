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
  name     = "TableStorage-RG-${random_id.randomId.hex}"
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

# Create Azure Table
resource "azurerm_storage_table" "storage-table" {
  name                 = "employeedata"
  storage_account_name = azurerm_storage_account.sa.name
}