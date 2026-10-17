resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-${local.resource_prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  
  # 🔥 CONDICIONAL: 90 dias para produção (main) para conformidade, 30 dias para dev (economia)
  retention_in_days   = local.env == "main" ? 90 : 30

  tags = local.global_tags
}

resource "azurerm_monitor_diagnostic_setting" "dbx_telemetry" {
  name                       = "ds-${local.resource_prefix}"
  target_resource_id         = azurerm_databricks_workspace.db_workspace.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  # CORRIGIDO: Coleta de logs de auditoria ativa em ambos os ambientes
  enabled_log {
    category_group = "allLogs"
  }

  # 🔥 BLOCO DINÂMICO (dynamic block): Só injeta o bloco 'metric' se o ambiente for 'main'.
  # Como o Databricks emite erro 400 em métricas padrão, isso blinda o ambiente de dev.
  dynamic "metric" {
    for_each = local.env == "main" ? ["AllMetrics"] : []
    content {
      category = metric.value
      enabled  = true
    }
  }
}
