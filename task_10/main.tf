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

# Generate a random id for the sql server name
resource "random_id" "randomId" {
  byte_length = 8
}

# Create a resource group 
resource "azurerm_resource_group" "rg" {
  name     = "cosmosdb-RG-${random_id.randomId.hex}"
  location = "North Europe"
}

# Create a CosmosDB account
resource "azurerm_cosmosdb_account" "cosmosdb" {
  name                = "cosmosdb-${random_id.randomId.hex}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"
  consistency_policy {
    consistency_level = "Session"
  }
  geo_location {
    location          = azurerm_resource_group.rg.location
    failover_priority = 0
  }
  geo_location {
    location          = "France Central"
    failover_priority = 1
  }
}

# CosmosDB Database
resource "azurerm_cosmosdb_sql_database" "database" {
  name                = "SampleDB"
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.cosmosdb.name
}

# CosmosDB Container
resource "azurerm_cosmosdb_sql_container" "container" {
  name                = "Items"
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.cosmosdb.name
  database_name       = azurerm_cosmosdb_sql_database.database.name
  partition_key_path  = "/category"
  throughput          = 400
}

# Outputs
output "cosmosdb_endpoint" {
  value = azurerm_cosmosdb_account.cosmosdb.endpoint
}

output "cosmosdb_key" {
  value     = azurerm_cosmosdb_account.cosmosdb.primary_key
  sensitive = true
}