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
  name     = "Lifecycle-RG"
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

# Create a container in the storage account
resource "azurerm_storage_container" "sc" {
  name                  = "lifecycle-container"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}

# Create Lifecycle Policy
resource "azurerm_storage_management_policy" "policy" {
  storage_account_id = azurerm_storage_account.sa.id

  rule {
    name    = "lifecycle-policy"
    enabled = true

    filters {
      blob_types   = ["blockBlob"]
      prefix_match = [""]
    }

    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than = 30
        delete_after_days_since_modification_greater_than       = 90
      }
    }
  }
}