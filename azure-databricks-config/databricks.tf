# ==============================================================================
# DATABRICKS PLATFORM CONFIGURATION
# ==============================================================================

resource "databricks_cluster" "single_node" {
  count                   = local.enable_cluster ? 1 : 0
  cluster_name            = "cls-single-node-interactive-${var.environment}"
  spark_version           = "14.3.x-scala2.12"
  node_type_id            = "Standard_F4s_v2"
  autotermination_minutes = var.autotermination_minutes
  data_security_mode      = "USER_ISOLATION"

  azure_attributes {
    availability = "ON_DEMAND_AZURE"
  }

  spark_conf = {
    "spark.databricks.cluster.profile" = "singleNode"
    "spark.master"                     = "local[*]"
  }

  custom_tags = {
    ResourceClass = "SingleNode"
  }
}
