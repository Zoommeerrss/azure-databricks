locals {
  env             = var.environment
  project_name    = var.project_name
  resource_prefix = "${local.project_name}-${local.env}"

  global_tags = {
    Environment    = local.env
    Project        = var.project_name
    ManagedBy      = "Terraform"
    CostCenter     = "Auditoria-DataQuality-${local.env}"
    ProjectOwner   = "Emerzoom"
    SubscriptionId = data.azurerm_subscription.current.subscription_id
  }
}
