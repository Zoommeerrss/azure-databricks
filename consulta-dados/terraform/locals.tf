locals {
  # Vincula o ambiente para composição de nomes (dev ou prod)
  env = var.environment

  # O nome do catálogo se adapta de forma dinâmica conforme o ambiente atual
  databricks_catalog_name = "dbw_dbx_lowcost_${local.env}"

  # 🚀 CORRIGIDO: Fronteira restabelecida! A pasta base agora é exclusiva deste projeto analítico
  workspace_base_path = "/Workspace/Production/consulta-dados_${local.env}"

  # Tags organizacionais aplicadas aos recursos deste projeto analítico
  global_tags = {
    Environment = local.env
    Project     = "Databricks-LowCost-Lab"
    ManagedBy   = "Terraform"
    CostCenter  = "Analytics-Dashboards-${local.env}"
    Layer       = "Data-App-Consulta"
  }
}
