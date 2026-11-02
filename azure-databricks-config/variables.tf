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

variable "databricks_workspace_numeric_id" {
  type        = string
  description = "O ID do Workspace mapeado nos arquivos envs/dev/prod.tfvars"
  default     = null
}

# 🔥 Variável para o Schema Student
variable "schema_student_name" {
  type        = string
  default     = "student"
  description = "Nome do schema voltado para dados de estudantes"
}

# 🔥 Variável para o Schema Course
variable "schema_course_name" {
  type        = string
  default     = "course"
  description = "Nome do schema voltado para dados de cursos"
}

variable "data_admin_users" {
  description = "Usuários administradores do Databricks"
  type        = list(string)
  default     = []
}

