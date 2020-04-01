# Configure the Microsoft Azure Provider
provider "azurerm" {
    # The "feature" block is required for AzureRM provider 2.x. 
    # If you're using version 1.x, the "features" block is not allowed.
    version = "~>2.0"
    features {}

    subscription_id = "231dfc13-ea87-4e0e-8836-4c8a2e9bcd79"
    client_id       = "99d30371-e38d-47d2-83e9-4619ce010114"
    client_secret   = "]=wd_W/8zJj49IXpveWUkUxQp96nqUVO"
    tenant_id       = "3fd5f87e-a8af-4c01-b089-74fbec75866e"
}

# Create a resource group if it doesn't exist
resource "azurerm_resource_group" "terraform_group" {
    name     = "test-rancher-group"
    location = "uksouth"

    tags = {
        environment = "Rancher Terraform"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "terraform_network" {
    name                = "rancher-network"
    address_space       = ["10.0.0.0/16"]
    location            = "uksouth"
    resource_group_name = azurerm_resource_group.terraform_group.name

    tags = {
        environment = "Rancher Terraform"
    }
}

# Create subnet
resource "azurerm_subnet" "terraform_subnet" {
    name                 = "rancher-subnet"
    resource_group_name  = azurerm_resource_group.terraform_group.name
    virtual_network_name = azurerm_virtual_network.terraform_network.name
    address_prefix       = "10.0.1.0/24"
}

# Create public IPs
resource "azurerm_public_ip" "terraform_public_ip" {
    name                         = "rancher-public-ip"
    location                     = "uksouth"
    resource_group_name          = azurerm_resource_group.terraform_group.name
    allocation_method            = "Dynamic"

    tags = {
        environment = "Rancher Terraform"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "terraform_nsg" {
    name                = "rancher-network-security-group"
    location            = "uksouth"
    resource_group_name = azurerm_resource_group.terraform_group.name
    
    tags = {
        environment = "Rancher Terraform"
    }
}
resource "azurerm_network_security_rule" "ssh" {
    name                       = "SSH"
    network_security_group_name = azurerm_network_security_group.terraform_nsg.name
    resource_group_name        = azurerm_resource_group.terraform_group.name
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
}

resource "azurerm_network_security_rule" "http" {
    name                       = "HTTP"
    network_security_group_name = azurerm_network_security_group.terraform_nsg.name
    resource_group_name        = azurerm_resource_group.terraform_group.name
    priority                   = 1011
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
}

resource "azurerm_network_security_rule" "etcd_client_requests" {
    name                       = "etcd_client_requests"
    network_security_group_name = azurerm_network_security_group.terraform_nsg.name
    resource_group_name        = azurerm_resource_group.terraform_group.name
    priority                   = 1021
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "2379"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
}

resource "azurerm_network_security_rule" "kublet" {
    name                       = "kublet"
    network_security_group_name = azurerm_network_security_group.terraform_nsg.name
    resource_group_name        = azurerm_resource_group.terraform_group.name
    priority                   = 1031
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "10250"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
}

resource "azurerm_network_security_rule" "api_server" {
    name                       = "api_server"
    network_security_group_name = azurerm_network_security_group.terraform_nsg.name
    resource_group_name        = azurerm_resource_group.terraform_group.name
    priority                   = 1041
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
}

# Create network interface
resource "azurerm_network_interface" "terraform_nic" {
    name                      = "rancher-nic"
    location                  = "uksouth"
    resource_group_name       = azurerm_resource_group.terraform_group.name

    ip_configuration {
        name                          = "rancher-nic-config"
        subnet_id                     = azurerm_subnet.terraform_subnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.terraform_public_ip.id
    }

    tags = {
        environment = "Rancher Terraform"
    }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
    network_interface_id      = azurerm_network_interface.terraform_nic.id
    network_security_group_id = azurerm_network_security_group.terraform_nsg.id
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.terraform_group.name
    }
    
    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "storage_account" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = azurerm_resource_group.terraform_group.name
    location                    = "uksouth"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "Rancher Terraform"
    }
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "terraform_vm" {
    name                  = "test-rancher"
    location              = "uksouth"
    resource_group_name   = azurerm_resource_group.terraform_group.name
    network_interface_ids = [azurerm_network_interface.terraform_nic.id]
    size                  = "Standard_D2s_v3"

    os_disk {
        name              = "rancher-os-disk"
        caching           = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    computer_name  = "test-rancher"
    admin_username = "evouser"
    disable_password_authentication = true
        
    admin_ssh_key {
        username       = "evouser"
        public_key     = file("/Users/scorpio/keys/aao_rancher_rsa.pub")
    }

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.storage_account.primary_blob_endpoint
    }

    tags = {
        environment = "Rancher Terraform"
    }
}
