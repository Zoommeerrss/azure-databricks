locals {
  # Vincula os locais às variáveis de entrada do Terraform
  env             = var.environment
  project_name    = var.project_name
  resource_prefix = "${local.project_name}-${local.env}"
  
  # Mantém a sua excelente leitura dinâmica do arquivo YAML de configurações
  settings       = yamldecode(file("${path.module}/config/settings.yaml"))
  enable_cluster = local.settings.enable_cluster

  global_tags = {
    Environment = local.env
    Project     = "Databricks-LowCost-Lab"
    ManagedBy   = "Terraform"
    
    # Segrega automaticamente os custos no mesmo pilar gerencial (ex: Auditoria-DataQuality-dev)
    CostCenter  = "Auditoria-DataQuality-${local.env}"
    
    # Consome o ID da assinatura descoberto pelo data source do providers.tf
    SubscriptionId = data.azurerm_subscription.current.subscription_id
  }
}
