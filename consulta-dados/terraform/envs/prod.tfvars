# envs/prod.tfvars

# Identificação do Ambiente Lógico
environment              = "prod"

# Conexão Lógica Databricks
databricks_workspace_id  = "/subscriptions/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/resourceGroups/rg-dbx-lowcost-prod/providers/Microsoft.Databricks/workspaces/dbw-dbx-lowcost-prod"
databricks_workspace_url = "https://adb-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.3.azuredatabricks.net/"

# Deve comecar com dapic
databricks_token         = ""

# Workspace ID
databricks_workspace_numeric_id = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

# Conexão Física do Backend (Responsabilidade do Terraform)
resource_group_name      = "rg-dbx-lowcost-prod"
storage_account_name     = "stdbxlowcostprod01"
container_name           = "unity-catalog-metastore"
