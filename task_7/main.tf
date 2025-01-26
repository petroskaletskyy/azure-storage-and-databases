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
  name     = "Secure-RG-${random_id.randomId.hex}"
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

# Create a Blob Container
resource "azurerm_storage_container" "sc" {
  name                  = "mycontainer"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}

# Assign RBAC Role to a User
resource "azurerm_role_assignment" "ra" {
  scope                = azurerm_storage_account.sa.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = "b0dc8408-266c-4fc9-a13e-66fa45f4ba84"
}

resource "azurerm_role_assignment" "reader_assigmrnt" {
  principal_id         = "b0dc8408-266c-4fc9-a13e-66fa45f4ba84"
  role_definition_name = "Reader"
  scope                = azurerm_resource_group.rg.id
}

# Create a Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "Linux-VM-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create a Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "Linux-VM-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.100.0/24"]
}

# Create a Network Security Group (NSG)
resource "azurerm_network_security_group" "nsg" {
  name                = "Linux-VM-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # Allow SSH (Port 22)
  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Associate NSG with Subnet
resource "azurerm_subnet_network_security_group_association" "subnet_nsg" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Create a Public IP Address
resource "azurerm_public_ip" "public_ip" {
  name                = "Linux-VM-public-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# Create a Network Interface
resource "azurerm_network_interface" "nic" {
  name                = "Linux-VM-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

# Manage SSH Public Key
resource "azurerm_ssh_public_key" "ssh_key" {
  name                = "Linux-VM-ssh-key"
  resource_group_name = azurerm_resource_group.rg.name
  location            = "West Europe"
  public_key          = file("~/.ssh/Linux-VM_key.pub")
}


# Create a Linux Virtual Machine
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "Linux-VM-vm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_B1s"
  admin_username      = "azureuser"
  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]
  admin_ssh_key {
    username   = "azureuser"
    public_key = azurerm_ssh_public_key.ssh_key.public_key
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
  identity {
    type = "SystemAssigned"
  }
  custom_data = filebase64("custom_data.sh")
}

# Assign STorage Blob Data Reader Role to the VM
resource "azurerm_role_assignment" "vm_ra" {
  scope                = azurerm_storage_account.sa.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_linux_virtual_machine.vm.identity[0].principal_id
}

output "vm_ip" {
  value = azurerm_public_ip.public_ip.ip_address
}
