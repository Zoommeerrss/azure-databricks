# ==============================================================================
# 1. ESTRUTURA DO UNITY CATALOG
# ==============================================================================
resource "databricks_catalog" "environment_catalog" {
  name           = "${var.environment}_catalog" 
  comment        = "Catálogo principal focado no ambiente de ${var.environment}"
  isolation_mode = "ISOLATED"
}

resource "databricks_schema" "student_schema" {
  catalog_name = databricks_catalog.environment_catalog.name
  name         = "student"
}

resource "databricks_schema" "course_schema" {
  catalog_name = databricks_catalog.environment_catalog.name
  name         = "course"
}

# ==============================================================================
# 2. CLUSTER INTERATIVO OPCIONAL (Apenas para Desenvolvimento Manual/Ad-hoc)
# ==============================================================================
resource "databricks_cluster" "single_node" {
  count                   = local.enable_cluster ? 1 : 0
  cluster_name            = "cls-single-node-interactive"
  spark_version           = "14.3.x-scala2.12"
  node_type_id            = "Standard_D4s_v5" 
  autotermination_minutes = var.autotermination_minutes
  data_security_mode      = "USER_ISOLATION" 

  azure_attributes {
    availability = "ON_DEMAND_AZURE"
  }

  spark_conf = {
    "spark.databricks.cluster.profile" : "singleNode"
    "spark.master" : "local[*]"
  }
}

# ==============================================================================
# 3. JOB 1: PIPELINE DE CARGA (Isolado e Apontado para seu Próprio Repositório)
# ==============================================================================
resource "databricks_job" "job_carga" {
  name = "Job-ETL-Carga-${var.environment}"

  # 🔥 CORRIGIDO: O bloco git_source fica no nível global do Job conforme exigido pelo provider
  git_source {
    url      = "https://github.com" # ⚠️ Sua URL real de Carga
    provider = "gitHub"
    branch   = var.git_branch
  }

  task {
    task_key = "Carga_Dados_Estudantes"

    notebook_task {
      notebook_path = "nb_carga_dados.ipynb" 
      source        = "GIT"
    }

    library {
      requirements = "requirements.txt"
    }

    new_cluster {
      spark_version = "14.3.x-scala2.12"
      node_type_id  = "Standard_D4s_v5"
      spark_conf = {
        "spark.databricks.cluster.profile" : "singleNode"
        "spark.master" : "local[*]"
      }
      azure_attributes {
        availability = "ON_DEMAND_AZURE"
      }
    }
  }
}

# ==============================================================================
# 4. JOB 2: PIPELINE DE CONSULTA (Isolado e Apontado para o outro Repositório)
# ==============================================================================
resource "databricks_job" "job_consulta" {
  name = "Job-Analitico-Consulta-${var.environment}"

  # 🔥 CORRIGIDO: git_source global isolado para o repositório de consulta
  git_source {
    url      = "https://github.com" # ⚠️ Sua URL real de Consulta
    provider = "gitHub"
    branch   = var.git_branch
  }

  task {
    task_key = "Consulta_e_Verificacao"

    notebook_task {
      notebook_path = "nb_consulta_dashboard.ipynb"
      source        = "GIT"
    }

    library {
      requirements = "requirements.txt"
    }

    new_cluster {
      spark_version = "14.3.x-scala2.12"
      node_type_id  = "Standard_D4s_v5"
      spark_conf = {
        "spark.databricks.cluster.profile" : "singleNode"
        "spark.master" : "local[*]"
      }
      azure_attributes {
        availability = "ON_DEMAND_AZURE"
      }
    }
  }
}
