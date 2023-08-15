terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.61.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.1"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 1.7.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg_microshop" {
  name     = "rg-schouls-${var.environment}"
  location = var.location
}

resource "azurerm_container_app_environment" "cae_microshop" {
  name                       = "cae-schouls-${var.environment}"
  location                   = azurerm_resource_group.rg_microshop.location
  resource_group_name        = azurerm_resource_group.rg_microshop.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics.id
}

resource "azurerm_log_analytics_workspace" "log_analytics" {
  name                = "log-schouls-${var.environment}"
  location            = azurerm_resource_group.rg_microshop.location
  resource_group_name = azurerm_resource_group.rg_microshop.name
  sku                 = "PerGB2018"
}

resource "random_string" "secret" {
  length  = 16
  special = false
}

resource "random_string" "appsetting" {
  length  = 16
  special = false
}

locals {
  secret_ref = "secret"
  container_secrets = [
    { name = (local.secret_ref), value = random_string.secret.result }
  ]
  container_settings = [
    { name = "appsetting", value = random_string.appsetting.result }
  ]
}

module "container_app" {
  source                       = "./modules/container-app"
  application_name             = "foo"
  container_app_environment_id = azurerm_container_app_environment.cae_microshop.id
  image_name                   = "nginx:latest"
  resource_group_id            = azurerm_resource_group.rg_microshop.id
  port                         = 80
  transport                    = "Tcp"
  allow_external_traffic       = false
  ingress_enabled              = true
  location                     = azurerm_resource_group.rg_microshop.location
  secrets                      = local.container_secrets
  appsettings                  = local.container_settings
}
