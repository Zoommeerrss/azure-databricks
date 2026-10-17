resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-${local.resource_prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = local.global_tags
}

resource "azurerm_monitor_diagnostic_setting" "dbx_telemetry" {
  name                       = "ds-${local.resource_prefix}"
  target_resource_id         = azurerm_databricks_workspace.db_workspace.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  # CORRIGIDO: Sintaxe oficial para capturar todos os logs de auditoria do Databricks
  enabled_log {
    category_group = "allLogs"
  }

  # Mantém a coleta de métricas de performance ativada
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
