output "workspace_url" {
  value       = "https://${azurerm_databricks_workspace.db_workspace.workspace_url}"
  description = "URL do Workspace do Databricks criado na Azure"
}

output "job_id" {
  value       = databricks_job.pipeline_automatizado.id
  description = "ID do Job Orquestrado Sequencial criado para as chamadas via API de Pipeline"
}
