# terraform/providers.tf

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.0"
    }
  }

  # Responsabilidade Ajustada: Apenas a identificação do estado isolado
  backend "azurerm" {
    key = "carga-dados.tfstate"
  }
}

provider "databricks" {
  host  = var.databricks_workspace_url
  token = var.databricks_token
}

# 🚀 CORRIGIDO: Utiliza o data source oficial que captura os metadados da sessão ativa
data "databricks_current_config" "current" {}