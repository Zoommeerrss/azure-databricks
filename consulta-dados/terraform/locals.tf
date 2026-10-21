locals {
  # Vincula o ambiente para composição de nomes (dev ou prod)
  env = var.environment

  # Nome do catálogo correspondente ao ambiente
  databricks_catalog_name = "dbw_dbx_lowcost_${local.env}_7405611752750506"

  # 🚀 ISOLAMENTO: Pasta exclusiva da camada de consulta dentro do Workspace
  workspace_base_path = "/Workspace/Production/consulta-dados_${local.env}"

  # Tags organizacionais aplicadas aos recursos do projeto analítico
  global_tags = {
    Environment = local.env
    Project     = "Databricks-LowCost-Lab"
    ManagedBy   = "Terraform"
    CostCenter  = "Auditoria-DataQuality-${local.env}"
    Layer       = "Data-App-Consulta"
  }
}
