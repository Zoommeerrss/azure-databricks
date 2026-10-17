output "workspace_url" {
  value       = azurerm_databricks_workspace.db_workspace.workspace_url
  description = "URL oficial do Workspace do Databricks gerada pela Azure"
}

output "job_id" {
  value       = databricks_job.pipeline_estudantes.id
  description = "ID do Job Orquestrado Sequencial criado para as chamadas via API de Pipeline"
}
