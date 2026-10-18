output "databricks_job_carga_id" {
  description = "O ID do pipeline de orquestração do Projeto de Carga"
  value       = databricks_job.pipeline_carga.id
}

output "databricks_job_consulta_id" {
  description = "O ID do pipeline de orquestração do Projeto de Consulta"
  value       = databricks_job.pipeline_consulta.id
}
