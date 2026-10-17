resource "azurerm_storage_account" "datalake" {
  name                     = "st${replace(local.resource_prefix, "-", "")}01"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true # Ativa a estrutura ADLS Gen2 para o Unity Catalog

  tags = local.global_tags
}

resource "azurerm_storage_container" "metastore_container" {
  name                  = "unity-catalog-metastore"
  # CORRIGIDO: Retornado para name por conta da versão ~> 3.100 especificada no seu providers.tf
  storage_account_name  = azurerm_storage_account.datalake.name 
  container_access_type = "private"
}
