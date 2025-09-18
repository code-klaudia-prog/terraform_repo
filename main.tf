# Create resources
resource "azurerm_resource_group" "rg_windows_server" {
  name     = "rg-windows-server-example"
  location = "East US"
}

# Create virtual network
resource "azurerm_virtual_network" "vnet_windows_server" {
  name                = "vnet-windows-server-example"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg_windows_server.location
  resource_group_name = azurerm_resource_group.rg_windows_server.name
}

# Create subnet
resource "azurerm_subnet" "subnet_windows_server" {
  name                 = "subnet-windows-server-example"
  resource_group_name  = azurerm_resource_group.rg_windows_server.name
  virtual_network_name = azurerm_virtual_network.vnet_windows_server.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Creat network interface
resource "azurerm_network_interface" "nic_windows_server" {
  name                = "nic-windows-server-example"
  location            = azurerm_resource_group.rg_windows_server.location
  resource_group_name = azurerm_resource_group.rg_windows_server.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet_windows_server.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Create a Windows VM
resource "azurerm_windows_virtual_machine" "vm_windows_server" {
  name                = "vm-windows-server-example"
  resource_group_name = azurerm_resource_group.rg_windows_server.name
  location            = azurerm_resource_group.rg_windows_server.location
  size                = "Standard_D2s_v3"
  admin_username      = "vmadmin"
  admin_password      = "Password12345!"
  network_interface_ids = [
    azurerm_network_interface.nic_windows_server.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
}