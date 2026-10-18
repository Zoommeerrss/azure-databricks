output "databricks_job_id" {
  description = "O ID do pipeline de orquestração sequencial gerado no Databricks"
  value       = databricks_job.pipeline_automatizado.id
}
