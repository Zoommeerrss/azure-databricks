# envs/dev.tfvars

# Identificação do Ambiente Lógico
environment              = "dev"

# Conexão Lógica Databricks
databricks_workspace_id  = "/subscriptions/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/resourceGroups/rg-dbx-lowcost-dev/providers/Microsoft.Databricks/workspaces/dbw-dbx-lowcost-dev"
databricks_workspace_url = "https://adb-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.3.azuredatabricks.net/"
databricks_token         = "dapicXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
databricks_workspace_numeric_id = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

# Conexão Física do Backend (Responsabilidade do Terraform)
resource_group_name      = "rg-dbx-lowcost-dev"
storage_account_name     = "stdbxlowcostdev01"
container_name           = "unity-catalog-metastore"
