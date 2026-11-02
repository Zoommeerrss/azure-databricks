# ==============================================================================
# AMBIENTE
# ==============================================================================

variable "environment" {
  type        = string
  description = "Identificador do ambiente (dev ou main)"
}

# ==============================================================================
# DATABRICKS WORKSPACE
# ==============================================================================

variable "databricks_workspace_id" {
  type        = string
  description = "Resource ID do Workspace Databricks"
}

variable "databricks_workspace_url" {
  type        = string
  description = "URL do Workspace Databricks"
}

variable "databricks_workspace_numeric_id" {
  type        = string
  description = "ID numérico do Workspace Databricks"
}

# ==============================================================================
# GIT
# ==============================================================================

variable "git_branch" {
  type        = string
  description = "Branch utilizada pelos Jobs Databricks"
}

# ==============================================================================
# BACKEND TERRAFORM
# ==============================================================================

variable "resource_group_name" {
  type        = string
  description = "Resource Group do backend Terraform"
}

variable "storage_account_name" {
  type        = string
  description = "Storage Account do backend Terraform"
}

variable "container_name" {
  type        = string
  description = "Container do backend Terraform"
}

# ==============================================================================
# SEGURANÇA
# ==============================================================================

variable "databricks_token" {
  type        = string
  description = "Token de acesso ao Databricks"
  sensitive   = true
}

variable "catalog_storage_root" {
  type        = string
  description = "Caminho do contêiner ADLS Gen2 na Azure que servirá de storage root para o catálogo"
}

variable "databricks_storage_credential_name" {
  type        = string
  description = "Nome da credencial de armazenamento já existente no Unity Catalog"
}

variable "databricks_access_connector_id" {
  type        = string
  description = "ID do Access Connector mapeado na Azure pela infraestrutura básica corporativa"
}