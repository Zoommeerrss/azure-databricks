locals {
  # Vincula o ambiente para composição de nomes (dev ou prod)
  env = var.environment

  # 🚀 AUTOMÁTICO: O nome do catálogo se adapta de forma dinâmica conforme o ambiente atual
  databricks_catalog_name = "dbw_dbx_lowcost_${local.env}_7405611752750506"

  # 🚀 ISOLAMENTO: Define a pasta base exclusiva para este projeto dentro do Workspace por ambiente
  workspace_base_path = "/Workspace/Production/carga-dados_${local.env}"

  # Tags organizacionais aplicadas aos recursos deste projeto de carga
  global_tags = {
    Environment = local.env
    Project     = "Databricks-LowCost-Lab"
    ManagedBy   = "Terraform"
    CostCenter  = "Auditoria-DataQuality-${local.env}"
    Layer       = "Data-App-Carga"
  }
}
