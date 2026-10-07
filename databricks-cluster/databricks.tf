# 1. Databricks Workspace (Standard SKU para controle financeiro)
resource "azurerm_databricks_workspace" "db_workspace" {
  name                = "dbw-${local.resource_prefix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "standard"

  custom_parameters {
    no_public_ip        = true
    virtual_network_id  = azurerm_virtual_network.vnet.id
    public_subnet_name  = azurerm_subnet.public_subnet.name
    private_subnet_name = azurerm_subnet.private_subnet.name
  }

  tags = local.global_tags
}

# 2. Estrutura do Unity Catalog
resource "databricks_metastore" "metastore" {
  name          = "metastore-${local.resource_prefix}"
  storage_root  = "abfss://${azurerm_storage_container.metastore_container.name}@${azurerm_storage_account.datalake.name}.dfs.core.windows.net/"
  force_destroy = true
}

resource "databricks_catalog" "dev_catalog" {
  metastore_id = databricks_metastore.metastore.id
  name         = "dev_catalog"
  comment      = "Catálogo principal focado em desenvolvimento"
}

resource "databricks_schema" "student_schema" {
  catalog_name = databricks_catalog.dev_catalog.name
  name         = "student"
  comment      = "Schema estruturado para auditoria de alunos"
}

resource "databricks_schema" "course_schema" {
  catalog_name = databricks_catalog.dev_catalog.name
  name         = "course"
  comment      = "Schema estruturado para auditoria de cursos"
}

# 3. Cluster Single Node Condicional
resource "databricks_cluster" "single_node" {
  count                   = local.enable_cluster ? 1 : 0
  cluster_name            = "cls-single-node-lowcost"
  spark_version           = "14.3.x-scala2.12"
  node_type_id            = "Standard_DS3_v2"
  autotermination_minutes = var.autotermination_minutes
  data_security_mode      = "USER_ISOLATION" # Requisito mandatório para conformidade com Unity Catalog

  spark_conf = {
    "spark.databricks.cluster.profile" : "singleNode"
    "spark.master" : "local[*]"
  }

  custom_tags = {
    "ResourceClass" = "SingleNode"
  }
}

# 4. Job Orquestrado Sequencial (Desacoplado - Clone via Runtime Task)
resource "databricks_job" "pipeline_automatizado" {
  name = "Job-Auditoria-Sequencial-Com-Requirements"

  # ----------------------------------------------------------------------------
  # TAREFA 1: Verificação da Carga (Gatilho Inicial)
  # ----------------------------------------------------------------------------
  task {
    task_key = "1_Verificar_Status_Carga"

    spark_python_task {
      python_file = "check_carga.py" 
    }

    git_source {
      url      = "https://github.com"
      provider = "gitHub"
      branch   = "main"
    }

    library {
      requirements = "requirements.txt"
    }

    existing_cluster_id = local.enable_cluster ? databricks_cluster.single_node.id : null
  }

  # ----------------------------------------------------------------------------
  # TAREFA 2: Consulta e Dashboard (Garante a Ordem Sequencial)
  # ----------------------------------------------------------------------------
  task {
    task_key = "2_Consulta_e_Verificacao"

    depends_on {
      task_key = "1_Verificar_Status_Carga"
    }

    spark_python_task {
      python_file = "dashboard_consulta.py"
    }

    git_source {
      url      = "https://github.com"
      provider = "gitHub"
      branch   = "main"
    }

    library {
      requirements = "requirements.txt"
    }

    existing_cluster_id = local.enable_cluster ? databricks_cluster.single_node.id : null
  }
}
