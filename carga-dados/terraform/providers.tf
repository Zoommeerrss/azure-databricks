# terraform/providers.tf

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.0"
    }
    # ADICIONADO: Declarado para habilitar os recursos de IAM e Contexto da Azure
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  # Responsabilidade Ajustada: Apenas a identificação do estado isolado
  backend "azurerm" {
    key = "carga-dados.tfstate"
  }
}

# ADICIONADO: Bloco explícito com o argumento obrigatório "features" ativado
provider "azurerm" {
  features {}
}

provider "databricks" {
  host  = var.databricks_workspace_url
  token = var.databricks_token
}

# 🚀 CORRIGIDO: Utiliza o data source oficial que captura os metadados da sessão ativa
data "databricks_current_config" "current" {}

