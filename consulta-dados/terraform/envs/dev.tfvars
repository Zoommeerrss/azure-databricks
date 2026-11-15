# ==============================================================================
# AMBIENTE
# ==============================================================================

environment = "dev"

# ==============================================================================
# DATABRICKS
# ==============================================================================

# Adicione ambas no seu envs/dev.tfvars:
databricks_workspace_id        = "/subscriptions/resource_group_id/resourceGroups/rg-dbx-lowcost-dev/providers/Microsoft.Databricks/workspaces/dbw-dbx-lowcost-dev"
databricks_access_connector_id = "/subscriptions/resource_group_id/resourceGroups/rg-managed-dbx-lowcost-dev/providers/Microsoft.Databricks/accessConnectors/unity-catalog-access-connector"
databricks_workspace_url        = "https://adb-XXXXXXXXXXXXXXXX.X.azuredatabricks.net/"
catalog_storage_root            = "abfss://unity-catalog-metastore@stdbxlowcostdev01.dfs.core.windows.net/"
databricks_token                = "dapiXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
databricks_workspace_numeric_id = "1111111111111111"
databricks_storage_credential_name = "NOME_DA_CREDENCIAL_EXISTENTE"

# ==============================================================================
# GIT
# ==============================================================================

git_branch = "dev"

# ==============================================================================
# TERRAFORM BACKEND
# ==============================================================================

resource_group_name  = "rg-dbx-lowcost-dev"
storage_account_name = "stdbxlowcostdev01"
container_name       = "unity-catalog-metastore"