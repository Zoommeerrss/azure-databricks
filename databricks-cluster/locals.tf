locals {
  env             = "dev"
  project_name    = "dbx-lowcost"
  resource_prefix = "${local.project_name}-${local.env}"
  
  # Leitura dinâmica da flag liga/desliga do cluster
  settings       = yamldecode(file("${path.module}/config/settings.yaml"))
  enable_cluster = local.settings.enable_cluster

  global_tags = {
    Environment = local.env
    Project     = "Databricks-LowCost-Lab"
    ManagedBy   = "Terraform"
    CostCenter  = "Auditoria-DataQuality"
  }
}
