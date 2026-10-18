locals {
  env             = var.environment
  project_name    = var.project_name
  resource_prefix = "${local.project_name}-${local.env}"

  global_tags = {
    Environment    = local.env
    Project        = "Databricks-LowCost-Lab"
    ManagedBy      = "Terraform"
    CostCenter     = "Auditoria-DataQuality-${local.env}"
    SubscriptionId = data.azurerm_subscription.current.subscription_id
  }
}
