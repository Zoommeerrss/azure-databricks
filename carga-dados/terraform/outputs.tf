# ==============================================================================
# PROJETO CARGA-DADOS: METADADOS DE SAÍDA (APPLICATION ONLY)
# ==============================================================================

output "workspace_base_directory" {
  description = "Diretório base lógico configurado para o ambiente"
  value       = local.workspace_base_path
}

output "notebook_workspace_path" {
  description = "Caminho relativo de execução do notebook principal da aplicação"
  value       = "nb_carga_dados.ipynb"
}

output "catalog_name" {
  description = "Catálogo criado e gerenciado por esta aplicação"
  value       = databricks_catalog.carga.name
}

output "student_schema_name" {
  description = "Schema destinado aos dados de estudantes"
  value       = databricks_schema.student.name
}

output "course_schema_name" {
  description = "Schema destinado aos dados de cursos"
  value       = databricks_schema.course.name
}

output "raw_volume_name" {
  description = "Volume gerenciado para recepção dos arquivos brutos"
  value       = databricks_volume.arquivos_brutos.name
}

output "databricks_job_id" {
  description = "ID numérico do Job de Carga criado"
  value       = databricks_job.pipeline_carga.id
}

output "databricks_job_name" {
  description = "Nome do Job de Carga criado"
  value       = databricks_job.pipeline_carga.name
}
