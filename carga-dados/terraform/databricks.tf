# ==============================================================================
# 0. DECLARAÇÃO DE RECURSOS DE CONTEXTO DA AZURE
# ==============================================================================

# Captura dinamicamente os dados da identidade atual que está executando o script
data "azurerm_client_config" "current" {}

# ==============================================================================
# 1. ELEVAÇÃO DE PERMISSÃO IAM NA AZURE (REQUISITO DE SEGURANÇA)
# ==============================================================================

resource "azurerm_role_assignment" "tf_access_connector_contributor" {
  scope                = var.databricks_access_connector_id != null ? var.databricks_access_connector_id : "/subscriptions/cad7880a-5cb0-4584-8efc-e0238c52be5f/resourceGroups/rg-dbx-lowcost-${var.environment}/providers/Microsoft.Databricks/accessConnectors/ac-dbx-lowcost-${var.environment}"
  role_definition_name = "Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "databricks_storage_credential" "external_creds" {
  name = "cred-storage-${local.catalog_name}"
  
  azure_managed_identity {
    access_connector_id = var.databricks_access_connector_id != null ? var.databricks_access_connector_id : "/subscriptions/cad7880a-5cb0-4584-8efc-e0238c52be5f/resourceGroups/rg-dbx-lowcost-${var.environment}/providers/Microsoft.Databricks/accessConnectors/ac-dbx-lowcost-${var.environment}"
  }

  depends_on = [
    azurerm_role_assignment.tf_access_connector_contributor
  ]
}

resource "databricks_external_location" "catalog_storage" {
  name            = "ext-location-${local.catalog_name}"
  url             = var.catalog_storage_root
  credential_name = databricks_storage_credential.external_creds.name
  comment         = "Localização externa gerenciada para o catálogo da aplicação de carga"

  depends_on = [
    azurerm_role_assignment.connector_storage_contributor
  ]
}

# ==============================================================================
# 2. PERMISSÃO DE ACESSO AO DATA LAKE PARA O CONECTOR GERENCIADO
# ==============================================================================

data "azurerm_databricks_access_connector" "managed_connector" {
  name                = "unity-catalog-access-connector"
  resource_group_name = "rg-managed-dbx-lowcost-${var.environment}"
}

resource "azurerm_role_assignment" "connector_storage_contributor" {
  scope                = "/subscriptions/cad7880a-5cb0-4584-8efc-e0238c52be5f/resourceGroups/rg-dbx-lowcost-${var.environment}/providers/Microsoft.Storage/storageAccounts/stdbxlowcostdev01"
  role_definition_name = "Storage Blob Data Contributor"
  
  principal_id         = data.azurerm_databricks_access_connector.managed_connector.identity[0].principal_id
}

# ==============================================================================
# 3. GOVERNANÇA DE DADOS (CATÁLOGO, SCHEMAS E VOLUMES)
# ==============================================================================

resource "databricks_catalog" "carga" {
  name         = local.catalog_name
  comment      = "Catálogo da aplicação de carga para o projeto carga-dados"
  storage_root = var.catalog_storage_root  
  owner        = "account users"

  depends_on = [
    databricks_external_location.catalog_storage
  ]
}

resource "databricks_schema" "student" {
  catalog_name = databricks_catalog.carga.name
  name         = local.student_schema_name
}

resource "databricks_schema" "course" {
  catalog_name = databricks_catalog.carga.name
  name         = local.course_schema_name
}

resource "databricks_volume" "arquivos_brutos" {
  catalog_name = databricks_catalog.carga.name
  schema_name  = databricks_schema.student.name
  name         = local.raw_volume_name
  volume_type  = "MANAGED"
}
