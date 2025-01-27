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
  name     = "sql-db-RG-${random_id.randomId.hex}"
  location = "North Europe"
}

# Create a SQL Server
resource "azurerm_mssql_server" "sqlserver" {
  name                         = "sql-server-${random_id.randomId.hex}"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = var.admin_username
  administrator_login_password = var.admin_password
}

# Create a SQL Database
resource "azurerm_mssql_database" "sqldb" {
  name         = "test-db"
  server_id    = azurerm_mssql_server.sqlserver.id
  collation    = "SQL_Latin1_General_CP1_CI_AS"
  max_size_gb  = 4
  sku_name     = "GP_S_Gen5_1"
  min_capacity = 1
  auto_pause_delay_in_minutes = 60
}

#Add a Firewall rule to allow access to the SQL Server
resource "azurerm_mssql_firewall_rule" "firewall" {
  name             = "AllowMyIP"
  server_id        = azurerm_mssql_server.sqlserver.id
  start_ip_address = var.ip
  end_ip_address   = var.ip
}

# Output the SQL Server and Database connection Strings
output "sql_server_fqdn" {
  value = azurerm_mssql_server.sqlserver.fully_qualified_domain_name
}