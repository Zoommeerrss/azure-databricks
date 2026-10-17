# ==============================================================================
# 1. DATABRICKS WORKSPACE (Premium SKU para suporte ao Unity Catalog)
# ==============================================================================
resource "azurerm_databricks_workspace" "db_workspace" {
  name                = "dbw-${local.resource_prefix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "premium"

  managed_resource_group_name = "rg-databricks-lab"

  custom_parameters {
    no_public_ip        = true
    virtual_network_id  = azurerm_virtual_network.vnet.id
    
    public_subnet_name                                  = azurerm_subnet.public_subnet.name
    public_subnet_network_security_group_association_id = azurerm_subnet_network_security_group_association.public_assoc.id 
    
    private_subnet_name                                 = azurerm_subnet.private_subnet.name
    private_subnet_network_security_group_association_id = azurerm_subnet_network_security_group_association.private_assoc.id 
  }

  tags = local.global_tags

  depends_on = [
    azurerm_subnet_network_security_group_association.public_assoc,
    azurerm_subnet_network_security_group_association.private_assoc
  ]
}

# ==============================================================================
# 2. ESTRUTURA DO UNITY CATALOG (Corrigido para Default Storage em Dev)
# ==============================================================================
resource "databricks_metastore" "metastore" {
  count         = local.env == "main" ? 1 : 0
  name          = "metastore-${local.resource_prefix}"
  storage_root  = "abfss://${azurerm_storage_container.metastore_container.name}@${azurerm_storage_account.datalake.name}.dfs.core.windows.net/"
  force_destroy = true
}

resource "databricks_catalog" "environment_catalog" {
  # 🔥 CORRIGIDO: Se for dev, passa null. O Databricks usará o Default Storage automático da conta,
  # eliminando o erro de 'Metastore storage root URL does not exist'.
  metastore_id = local.env == "main" ? databricks_metastore.metastore[0].id : null
  name         = "${local.env}_catalog" 
  comment      = "Catálogo principal focado no ambiente de ${local.env}"
}

resource "databricks_schema" "student_schema" {
  catalog_name = databricks_catalog.environment_catalog.name
  name         = "student"
  comment      = "Schema estruturado para auditoria de alunos"
}

resource "databricks_schema" "course_schema" {
  catalog_name = databricks_catalog.environment_catalog.name
  name         = "course"
  comment      = "Schema estruturado para auditoria de cursos"
}

# ==============================================================================
# 3. CLUSTER SINGLE NODE CONDICIONAL (Corrigido para SKU estável em Free-Tier)
# ==============================================================================
resource "databricks_cluster" "single_node" {
  count                   = local.enable_cluster ? 1 : 0
  cluster_name            = "cls-single-node-lowcost"
  spark_version           = "14.3.x-scala2.12"
  node_type_id            = "Standard_F4s_v2" # 🔥 CORRIGIDO: VM leve de computação otimizada (resolve o WorkerEnv not found)
  autotermination_minutes = var.autotermination_minutes
  data_security_mode      = "USER_ISOLATION" 

  spark_conf = {
    "spark.databricks.cluster.profile" : "singleNode"
    "spark.master" : "local[*]"
  }

  custom_tags = {
    "ResourceClass" = "SingleNode"
  }
}

# ==============================================================================
# 4. JOB ORQUESTRADO SEQUENCIAL (Multi-Ambiente)
# ==============================================================================
resource "databricks_job" "pipeline_automatizado" {
  name = "Job-Auditoria-Sequencial-Com-Requirements-${local.env}"

  git_source {
    url      = "https://github.com"
    provider = "gitHub"
    branch   = var.git_branch  
  }

  task {
    task_key = "1_Verificar_Status_Carga"
    spark_python_task {
      python_file = "check_carga.py" 
      source      = "GIT"
    }
    library { requirements = "requirements.txt" }
    existing_cluster_id = local.enable_cluster ? databricks_cluster.single_node[0].id : null
  }

  task {
    task_key = "2_Consulta_e_Verificacao"
    depends_on { task_key = "1_Verificar_Status_Carga" }
    spark_python_task {
      python_file = "dashboard_consulta.py"
      source      = "GIT"
    }
    library { requirements = "requirements.txt" }
    existing_cluster_id = local.enable_cluster ? databricks_cluster.single_node[0].id : null
  }
}
