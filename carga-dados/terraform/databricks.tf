# ==============================================================================
# 0. DECLARAÇÃO DE RECURSOS DE CONTEXTO DA AZURE
# ==============================================================================

# Captura dinamicamente os dados da identidade atual que está executando o script
data "azurerm_client_config" "current" {}

# ==============================================================================
# 1. ELEVAÇÃO DE PERMISSÃO IAM NA AZURE (REQUISITO DE SEGURANÇA)
# ==============================================================================

# No bloco azurerm_role_assignment (Linha 14):
resource "azurerm_role_assignment" "tf_access_connector_contributor" {
  scope                = var.databricks_access_connector_id != null ? var.databricks_access_connector_id : "/subscriptions/cad7880a-5cb0-4584-8efc-e0238c52be5f/resourceGroups/rg-dbx-lowcost-${var.environment}/providers/Microsoft.Databricks/accessConnectors/ac-dbx-lowcost-${var.environment}"
  role_definition_name = "Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

# No bloco databricks_storage_credential:
resource "databricks_storage_credential" "external_creds" {
  name = "cred-storage-${local.catalog_name}"
  
  azure_managed_identity {
    access_connector_id = var.databricks_access_connector_id != null ? var.databricks_access_connector_id : "/subscriptions/cad7880a-5cb0-4584-8efc-e0238c52be5f/resourceGroups/rg-dbx-lowcost-${var.environment}/providers/Microsoft.Databricks/accessConnectors/ac-dbx-lowcost-${var.environment}"
  }

  depends_on = [
    azurerm_role_assignment.tf_access_connector_contributor
  ]
}
# Registra a URL do container da Azure como um local de armazenamento confiável
resource "databricks_external_location" "catalog_storage" {
  name            = "ext-location-${local.catalog_name}"
  url             = var.catalog_storage_root
  credential_name = databricks_storage_credential.external_creds.name
  comment         = "Localização externa gerenciada para o catálogo da aplicação de carga"
}

# ==============================================================================
# 3. GOVERNANÇA DE DADOS (CATÁLOGO, SCHEMAS E VOLUMES)
# ==============================================================================

# Cria o catálogo da aplicação apontando para a raiz física parametrizada no tfvars
resource "databricks_catalog" "carga" {
  name         = local.catalog_name
  comment      = "Catálogo da aplicação de carga para o projeto carga-dados"
  storage_root = var.catalog_storage_root  
  owner        = "account users"

  depends_on = [
    databricks_external_location.catalog_storage
  ]
}

# Cria as gavetas lógicas de banco de dados para Alunos
resource "databricks_schema" "student" {
  catalog_name = databricks_catalog.carga.name
  name         = local.student_schema_name
}

# Cria as gavetas lógicas de banco de dados para Cursos
resource "databricks_schema" "course" {
  catalog_name = databricks_catalog.carga.name
  name         = local.course_schema_name
}

# Configura o volume gerenciado para a recepção dos arquivos brutos/landing zone
resource "databricks_volume" "arquivos_brutos" {
  catalog_name = databricks_catalog.carga.name
  schema_name  = databricks_schema.student.name
  name         = local.raw_volume_name
  volume_type  = "MANAGED"
}

