# terraform/providers.tf

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.0"
    }
  }

  # 🚀 CORRIGIDO: Agora o estado está 100% isolado do projeto de carga
  backend "azurerm" {
    key = "consulta-dados.tfstate"
  }
}

provider "databricks" {
  host  = var.databricks_workspace_url
  token = var.databricks_token
}

# 🚀 CORRIGIDO: Utiliza o data source oficial que captura os metadados da sessão ativa
data "databricks_current_config" "current" {}
