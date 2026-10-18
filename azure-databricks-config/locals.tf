locals {
  # Vincula o ambiente para composição de nomes
  env = var.environment

  # Lê de forma segura a sua flag de controle de custos do cluster via arquivo YAML
  _settings      = yamldecode(file("${path.module}/config/settings.yaml"))
  enable_cluster = local._settings.enable_cluster

  # 🚀 DECLARAÇÃO DAS TAGS: Resolve o erro "No declaration found"
  global_tags = {
    Environment = local.env
    Project     = "Databricks-LowCost-Lab"
    ManagedBy   = "Terraform"
    CostCenter  = "Auditoria-DataQuality-${local.env}"
    
    # Como este projeto usa apenas o provider do Databricks, removemos o data source da Azure 
    # que gerava acoplamento e mantemos a rastreabilidade do ecossistema de forma limpa.
    Layer       = "Logical-Configuration"
  }
}
