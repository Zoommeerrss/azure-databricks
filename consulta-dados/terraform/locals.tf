locals {
  # Vincula o ambiente para composição de nomes (dev ou prod)
  env = var.environment

  # O nome do catálogo próprio desta aplicação analítica
  databricks_catalog_name = "dbw_dbx_lowcost_${local.env}"

  # 🚀 ADICIONADO: Referência do catálogo de ingestão que este projeto vai consumir.
  # O nome pode ser passado via variável de entrada ou mantendo a previsibilidade do padrão.
  source_catalog_name = "catalog_carga_${local.env}"

  # 🚀 CORRIGIDO: Alterado para '/Shared' para manter os projetos na mesma estrutura pública
  workspace_base_path = "/Shared/Production/consulta-dados_${local.env}"

  # Tags organizacionais aplicadas aos recursos deste projeto analítico
  global_tags = {
    Environment = local.env
    Project     = "Databricks-LowCost-Lab"
    ManagedBy   = "Terraform"
    CostCenter  = "Analytics-Dashboards-${local.env}"
    Layer       = "Data-App-Consulta"
  }
}
