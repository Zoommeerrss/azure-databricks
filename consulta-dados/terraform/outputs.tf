# ==============================================================================
# METADADOS DOS CÓDIGOS E WORKSPACE
# ==============================================================================

output "notebook_workspace_path" {
  value       = databricks_notebook.nb_carga.path
  description = "Caminho absoluto do Notebook de Carga dentro do Workspace do Databricks"
}

output "workspace_base_directory" {
  value       = local.workspace_base_path
  description = "Diretório base onde todos os artefatos deste repositório foram publicados"
}

# ==============================================================================
# METADADOS DO ORQUESTRADOR (JOB)
# ==============================================================================

output "databricks_job_id" {
  value       = databricks_job.pipeline_carga.id
  description = "O ID numérico único gerado pelo Databricks para o Job de Carga"
}

output "databricks_job_name" {
  value       = databricks_job.pipeline_carga.name
  description = "O nome exato do Job registrado no painel do Databricks"
}

# ==============================================================================
# METADADOS DE GOVERNANÇA (CONEXÃO)
# ==============================================================================

output "target_catalog_name" {
  value       = local.databricks_catalog_name
  description = "Nome do Catálogo do Unity Catalog mapeado dinamicamente para este ambiente"
}
