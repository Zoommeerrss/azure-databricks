# ==============================================================================
# AMBIENTE
# ==============================================================================

environment = "dev"

# ==============================================================================
# DATABRICKS
# ==============================================================================

# Adicione ambas no seu envs/dev.tfvars:
databricks_workspace_id        = "/subscriptions/cad7880a-5cb0-4584-8efc-e0238c52be5f/resourceGroups/rg-dbx-lowcost-dev/providers/Microsoft.Databricks/workspaces/dbw-dbx-lowcost-dev"
databricks_access_connector_id = "/subscriptions/cad7880a-5cb0-4584-8efc-e0238c52be5f/resourceGroups/rg-dbx-lowcost-dev/providers/Microsoft.Databricks/accessConnectors/unity-catalog-access-connector"
databricks_workspace_url        = "https://adb-7405605472483628.8.azuredatabricks.net/"
catalog_storage_root            = "abfss://unity-catalog-metastore@stdbxlowcostdev01.dfs.core.windows.net/"
databricks_token                = "dapi4d3671607b8026fc372d88afa75f07ac-3"
databricks_workspace_numeric_id = "7405605472483628"
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