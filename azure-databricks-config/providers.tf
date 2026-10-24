terraform {
  required_version = ">= 1.0"
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.0" 
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Lê o histórico de rede e do workspace criados na outra pasta
data "terraform_remote_state" "infra_base" {
  backend = "local"
  config = {
    path = "${path.module}/../azure-databricks-basic-infra/terraform.tfstate"
  }
}

# Conecta nativamente usando a URL descoberta
provider "databricks" {
  host      = data.terraform_remote_state.infra_base.outputs.databricks_workspace_url
  auth_type = "azure-cli"
}

# Provider básico necessário apenas para o data source calcular o ID interno
provider "azurerm" {
  features {}
}

# 🚀 A MÁGICA AQUI: Consulta o Workspace na Azure para descobrir o ID numérico dele sozinho
data "azurerm_databricks_workspace" "existing_dbw" {
  name                = "dbw-dbx-lowcost-${var.environment}"
  resource_group_name = "rg-dbx-lowcost-${var.environment}"
}