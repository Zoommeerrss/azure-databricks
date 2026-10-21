# ==============================================================================
# 1. VERSÕES DOS PROVEDORES E CONFIGURAÇÃO DE BACKEND
# ==============================================================================
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.0"
    }
  }

  # Estado do projeto de carga salvo de forma 100% isolada
  backend "azurerm" {
    key = "carga-dados.tfstate"
  }
}

# ==============================================================================
# 2. PROVEDOR DATABRICKS (CONEXÃO ISOLADA DE MÁXIMA COMPATIBILIDADE)
# ==============================================================================
provider "databricks" {
  # 🚀 RESOLVIDO: Removido o atributo problemático. O provedor agora usa apenas o host.
  # O token de autenticação é injetado de forma invisível e segura pela esteira de CI/CD
  host = var.databricks_workspace_url
}
