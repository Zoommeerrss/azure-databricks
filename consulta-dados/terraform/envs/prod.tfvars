# envs/prod.tfvars

# Identificação do Ambiente Lógico
environment              = "prod"

# Conexão Lógica Databricks
databricks_workspace_id  = "/subscriptions/cad7880a-5cb0-4584-8efc-e0238c52be5f/resourceGroups/rg-dbx-lowcost-prod/providers/Microsoft.Databricks/workspaces/dbw-dbx-lowcost-prod"
databricks_workspace_url = "https://adb-7405615700808623.3.azuredatabricks.net/"
databricks_token         = "dapic632837ff9aa330e3240a7ad2978930b-3"
databricks_workspace_numeric_id = "7405615700808623"

# Conexão Física do Backend (Responsabilidade do Terraform)
resource_group_name      = "rg-dbx-lowcost-prod"
storage_account_name     = "stdbxlowcostprod01"
container_name           = "unity-catalog-metastore"
