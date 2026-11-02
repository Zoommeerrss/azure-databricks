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

provider "azurerm" {
  features {}
}

# Adicionado para resolver o erro de recurso não declarado no databricks.tf
data "azurerm_client_config" "current" {}

# Consulta o Workspace na Azure para descobrir as propriedades dele sozinho
data "azurerm_databricks_workspace" "existing_dbw" {
  name                = "dbw-dbx-lowcost-${var.environment}"
  resource_group_name = "rg-dbx-lowcost-${var.environment}"
}

# Conecta nativamente usando a URL descoberta diretamente da Azure
provider "databricks" {
  host         = data.azurerm_databricks_workspace.existing_dbw.workspace_url
  # AJUSTE: Força o provedor a usar o ID correto descoberto pelo Data Source, eliminando o mismatch
  workspace_id = data.azurerm_databricks_workspace.existing_dbw.workspace_id
  auth_type    = "azure-cli"
}
