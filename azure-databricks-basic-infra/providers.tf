terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0" # Use a versão estável do seu laboratório
    }
  }
}

provider "azurerm" {
  features {}
}

# Data source necessário para capturar o ID da assinatura para as tags do locals
data "azurerm_subscription" "current" {}
