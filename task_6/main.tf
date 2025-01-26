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
  name     = "SAS-RG-${random_id.randomId.hex}"
  location = "North Europe"
}

# Create a Storage Account
resource "azurerm_storage_account" "sa" {
  name                     = "mysa${random_id.randomId.hex}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create a Storage Container
resource "azurerm_storage_container" "sc" {
  name                  = "my-container"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}

# Generate a SAS token for Blob Storage
data "azurerm_storage_account_sas" "sas" {
  connection_string = azurerm_storage_account.sa.primary_connection_string
  https_only        = true
  resource_types {
    service   = true
    container = true
    object    = true
  }
  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }
  start  = "2025-01-26T00:00:00Z"
  expiry = "2025-01-28T00:00:00Z"
  permissions {
    read    = true
    add     = false
    create  = false
    write   = false
    delete  = false
    list    = true
    update  = false
    process = false
    filter  = false
    tag     = false
  }
}

# Create Queue service
resource "azurerm_storage_queue" "queue" {
  name                 = "myqueue"
  storage_account_name = azurerm_storage_account.sa.name
}

# Generate a SAS token for Queue
data "azurerm_storage_account_sas" "sas_queue" {
  connection_string = azurerm_storage_account.sa.primary_connection_string
  https_only        = true
  resource_types {
    service   = true
    container = true
    object    = true
  }
  services {
    blob  = false
    queue = true
    table = false
    file  = false
  }
  start  = "2025-01-26T00:00:00Z"
  expiry = "2025-01-28T00:00:00Z"
  permissions {
    read    = true
    add     = false
    create  = false
    write   = false
    delete  = false
    list    = true
    update  = false
    process = false
    filter  = false
    tag     = false
  }
}

# Create File service
resource "azurerm_storage_share" "share" {
  name                 = "myshare"
  quota                = 50
  storage_account_name = azurerm_storage_account.sa.name
}

# Generate a SAS token for File
data "azurerm_storage_account_sas" "sas_file" {
  connection_string = azurerm_storage_account.sa.primary_connection_string
  https_only        = true
  resource_types {
    service   = true
    container = true
    object    = true
  }
  services {
    blob  = false
    queue = false
    table = false
    file  = true
  }
  start  = "2025-01-26T00:00:00Z"
  expiry = "2025-01-28T00:00:00Z"
  permissions {
    read    = true
    add     = false
    create  = false
    write   = false
    delete  = false
    list    = true
    update  = false
    process = false
    filter  = false
    tag     = false
  }
}

#Create Table service
resource "azurerm_storage_table" "table" {
  name                 = "mytable"
  storage_account_name = azurerm_storage_account.sa.name
}

# Generate a SAS token for Table
data "azurerm_storage_account_sas" "sas_table" {
  connection_string = azurerm_storage_account.sa.primary_connection_string
  https_only        = true
  resource_types {
    service   = true
    container = true
    object    = true
  }
  services {
    blob  = false
    queue = false
    table = true
    file  = false
  }
  start  = "2025-01-26T00:00:00Z"
  expiry = "2025-01-28T00:00:00Z"
  permissions {
    read    = true
    add     = false
    create  = false
    write   = false
    delete  = false
    list    = false
    update  = false
    process = false
    filter  = false
    tag     = false
  }
}

# Output SAS for blob, queue, share and table
output "sas_url_blob" {
  value     = "${azurerm_storage_account.sa.primary_blob_endpoint}${azurerm_storage_container.sc.name}${data.azurerm_storage_account_sas.sas.sas}"
  sensitive = true
}

output "sas_url_share" {
  value     = "${azurerm_storage_account.sa.primary_file_endpoint}${azurerm_storage_share.share.name}${data.azurerm_storage_account_sas.sas_file.sas}"
  sensitive = true
}  

output "sas_url_queue" {
  value     = "${azurerm_storage_account.sa.primary_queue_endpoint}${azurerm_storage_queue.queue.name}${data.azurerm_storage_account_sas.sas_queue.sas}"
  sensitive = true
}

output "sas_url_table" {
  value     = "${azurerm_storage_account.sa.primary_table_endpoint}${azurerm_storage_table.table.name}${data.azurerm_storage_account_sas.sas_table.sas}"
  sensitive = true
}

