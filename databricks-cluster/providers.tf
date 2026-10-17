terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100" # Se mantiver a versão 3.x, use storage_account_name no storage.tf!
    }
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.40"
    }
  }
}

provider "azurerm" {
  features {}
}

# Configuração corrigida para autenticação integrada com a Azure
provider "databricks" {
  host                        = azurerm_databricks_workspace.db_workspace.workspace_url
  auth_type                   = "azure-cli" # Usa a mesma sessão do seu terminal ou pipeline da Azure
}

# Captura dinâmica da assinatura logada via Azure CLI
data "azurerm_subscription" "current" {}