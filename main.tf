# Azure Provider source and version being used
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
  subscription_id = "615c8b72-88d7-44d5-8f42-66370abbcb05"
  client_id       = "7e14f56c-1903-4fc5-a0e5-6f69d587ed55"
  tenant_id       = "fec9a3b0-dce5-4ee9-a086-fe9cd205cc62"
}

# Create a resource group
resource "azurerm_resource_group" "example" {
  name      = "example-resources"
  location  = "West Europe"
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "example" {
  name                = "example-network"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  address_space       = ["10.0.0.0/16"]
}
