output "databricks_workspace_url" {
  description = "A URL de acesso ao Workspace do Databricks gerado na Azure"
  value       = azurerm_databricks_workspace.db_workspace.workspace_url
}
