locals {
  # Vincula o ambiente para composição de nomes
  env = var.environment

  # 🚀 AUTOMÁTICO: O nome exato do seu catálogo fica travado aqui no Terraform, sem trabalho manual
  databricks_catalog_name = "dbw_dbx_lowcost_dev_7405615700808623"

  # Lê de forma segura a sua flag de controle de custos do cluster via arquivo YAML
  _settings      = yamldecode(file("${path.module}/config/settings.yaml"))
  enable_cluster = local._settings.enable_cluster

  global_tags = {
    Environment = local.env
    Project     = "Databricks-LowCost-Lab"
    ManagedBy   = "Terraform"
    CostCenter  = "Auditoria-DataQuality-${local.env}"
    Layer       = "Logical-Configuration"
  }
}