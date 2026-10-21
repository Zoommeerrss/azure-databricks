variable "environment" {
  type        = string
  description = "Identificador do ambiente (dev ou prod)"
}

variable "databricks_workspace_id" {
  type        = string
  description = "O ID do recurso do Workspace na Azure (Injetado via Variável de Pipeline)"
}

variable "databricks_workspace_url" {
  type        = string
  description = "A URL de conexão do Workspace do Databricks (Injetada via Variável de Pipeline)"
}
