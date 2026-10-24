# ==============================================================================
# METADADOS DOS CÓDIGOS E WORKSPACE
# ==============================================================================

output "notebook_workspace_path" {
  # 🚀 CORRIGIDO: Alterado de nb_carga para nb_consulta
  value       = databricks_notebook.nb_consulta.path
  description = "Caminho absoluto do Notebook de Consulta dentro do Workspace"
}

output "workspace_base_directory" {
  value       = local.workspace_base_path
  description = "Diretório base onde todos os artefatos deste repositório foram publicados"
}

# ==============================================================================
# METADADOS DO ORQUESTRADOR (JOB)
# ==============================================================================

output "databricks_job_id" {
  # 🚀 CORRIGIDO: Alterado de pipeline_carga para pipeline_consulta
  value       = databricks_job.pipeline_consulta.id
  description = "O ID único do Job 2 de Consulta"
}

output "databricks_job_name" {
  # 🚀 CORRIGIDO: Alterado de pipeline_carga para pipeline_consulta
  value       = databricks_job.pipeline_consulta.name
  description = "Nome exato do Job registrado"
}

# ==============================================================================
# METADADOS DE GOVERNANÇA (CONEXÃO)
# ==============================================================================

output "target_catalog_name" {
  value       = local.databricks_catalog_name
  description = "Nome do Catálogo do Unity Catalog mapeado dinamicamente para este ambiente"
}
