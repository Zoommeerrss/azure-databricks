# ==============================================================================
# VARIÁVEIS LÓGICAS (DATABRICKS)
# ==============================================================================

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

# 🚀 ADICIONE ESTE BLOCO: Declaração obrigatória para o Token funcionar no providers.tf
variable "databricks_token" {
  type        = string
  description = "Token de Acesso Pessoal (PAT) copiado estaticamente do console do Databricks"
  sensitive   = true # Mascara o token nos logs de terminal e esteira por segurança
}

# ==============================================================================
# VARIÁVEIS FÍSICAS DO BACKEND (AZURE)
# ==============================================================================

variable "resource_group_name" {
  type        = string
  description = "Nome do grupo de recursos onde está a Storage Account do estado"
  default     = null # Permite passar batido se não mapeado no runtime lógico
}

variable "storage_account_name" {
  type        = string
  description = "Nome da Storage Account que armazena os estados"
  default     = null
}

variable "container_name" {
  type        = string
  description = "Nome do container de blobs do estado"
  default     = null
}

variable "databricks_workspace_numeric_id" {
  type        = string
  description = "O ID do Workspace mapeado nos arquivos envs/dev/prod.tfvars"
  default     = null
}