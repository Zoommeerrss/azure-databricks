# envs/dev.tfvars

# Identificação do Ambiente Lógico
environment              = "dev"

# Conexão Lógica Databricks
databricks_workspace_id  = "/subscriptions/cad7880a-5cb0-4584-8efc-e0238c52be5f/resourceGroups/rg-dbx-lowcost-dev/providers/Microsoft.Databricks/workspaces/dbw-dbx-lowcost-dev"
databricks_workspace_url = "https://adb-7405614968083539.19.azuredatabricks.net/"
databricks_token         = "dapi0a77feb7b4344e5898be7fd86eb60de9-3"
databricks_workspace_numeric_id = "7405614968083539"

# Conexão Física do Backend (Responsabilidade do Terraform)
resource_group_name      = "rg-dbx-lowcost-dev"
storage_account_name     = "stdbxlowcostdev01"
container_name           = "unity-catalog-metastore"
