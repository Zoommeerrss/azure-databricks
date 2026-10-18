variable "databricks_workspace_url" {
  type        = string
  description = "A URL de acesso ao Workspace Databricks criada pelo projeto anterior"
}

variable "environment" {
  type        = string
  description = "Ambiente atual de execução (dev ou main)"
}

variable "git_branch" {
  type        = string
  description = "A branch do repositório Git que o job deve clonar dinamicamente (dev ou main)"
}

variable "autotermination_minutes" {
  type        = number
  default     = 10
  description = "Tempo de inatividade em minutos para o cluster Single Node desligar sozinho"
}
