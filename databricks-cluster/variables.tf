variable "location" {
  type        = string
  default     = "East US"
  description = "Região da Azure onde os recursos serão implantados"
}

variable "project_name" {
  type        = string
  default     = "auditoria"
  description = "Nome base do projeto utilizado para compor o prefixo dos recursos"
}

variable "environment" {
  type        = string
  description = "Ambiente atual (dev ou prod)"
}

variable "git_branch" {
  type        = string
  description = "A ramificação do repositório Git correspondente ao ambiente (ex: main ou dev)"
}

variable "autotermination_minutes" {
  type        = number
  default     = 10
  description = "Tempo de inatividade em minutos para o cluster desligar sozinho"
}

variable "force_enable_cluster" {
  type        = bool
  default     = true
  description = "Força a criação do cluster mesmo se o ambiente for dev (útil para testes)"
}
