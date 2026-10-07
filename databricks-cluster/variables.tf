variable "location" {
  type        = string
  default     = "East US"
  description = "Região da Azure onde os recursos serão implantados"
}

variable "autotermination_minutes" {
  type        = number
  default     = 10
  description = "Tempo de inatividade em minutos para o cluster desligar sozinho"
}
