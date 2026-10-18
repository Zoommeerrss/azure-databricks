variable "environment" {
  type        = string
  description = "Ambiente atual de execução (dev ou main)"
}

variable "git_branch" {
  type        = string
  description = "A branch do repositório Git que o job deve clonar dinamicamente (dev ou main)"
}

variable "databricks_catalog_name" {
  type        = string
  description = "O nome exato do catálogo padrão criado automaticamente pelo Workspace"
}

variable "autotermination_minutes" {
  type        = number
  default     = 10
  description = "Tempo de inatividade em minutos para o cluster Single Node desligar sozinho"
}
