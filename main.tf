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
}

# Create a resource group
resource "azurerm_resource_group" "example" {
  name      = "example-resources"
  location  = "West Europe"
}

# --- Módulo de Rede ---
module "network" {
  source              = "./modules/network"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  vnet_name           = var.vnet_name
  vnet_address_space  = var.vnet_address_space
  frontend_subnet_name = "frontend-subnet"
  backend_subnet_name  = "backend-subnet"
  database_subnet_name = "database-subnet"
}
 
# --- Módulo de Banco de Dados ---
module "database" {
  source              = "./modules/database"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  vnet_id             = module.network.vnet_id
  database_subnet_id  = module.network.database_subnet_id
  postgres_server_name = var.postgres_server_name
  postgres_db_name     = var.postgres_db_name
}
 
# --- Módulo de App Services e Application Gateway ---
module "app_services" {
  source              = "./modules/app_services"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  vnet_id             = module.network.vnet_id
  frontend_subnet_id  = module.network.frontend_subnet_id
  backend_subnet_id   = module.network.backend_subnet_id
  app_gateway_subnet_id = module.network.app_gateway_subnet_id
  database_server_name  = module.database.postgres_server_name
}
