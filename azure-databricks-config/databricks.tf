# ==============================================================================
# 1. REFERÊNCIA AO UNITY CATALOG EXISTENTE (Data Source Direto)
# ==============================================================================
# 🚀 AUTOMÁTICO: Lê o catálogo direto do valor configurado no seu locals.tf
data "databricks_catalog" "environment_catalog" {
  name = local.databricks_catalog_name
}

resource "databricks_schema" "student_schema" {
  catalog_name = data.databricks_catalog.environment_catalog.name
  name         = "student"
}

resource "databricks_schema" "course_schema" {
  catalog_name = data.databricks_catalog.environment_catalog.name
  name         = "course"
}


# ==============================================================================
# 2. CLUSTER INTERATIVO OPCIONAL (Ajustado para contornar Cota da Azure)
# ==============================================================================
resource "databricks_cluster" "single_node" {
  count                   = local.enable_cluster ? 1 : 0
  cluster_name            = "cls-single-node-interactive"
  spark_version           = "14.3.x-scala2.12"
  
  # 🚀 SOLUÇÃO DA COTA: SKU F4s_v2 que passa pelas restrições da sua assinatura
  node_type_id            = "Standard_F4s_v2" 
  autotermination_minutes = var.autotermination_minutes
  data_security_mode      = "USER_ISOLATION" 

  azure_attributes {
    availability = "ON_DEMAND_AZURE"
  }

  spark_conf = {
    "spark.master" : "local[*]"
  }
}

# ==============================================================================
# 3. JOB 1: PIPELINE DE CARGA (Isolado e Apontado para seu Próprio Repositório)
# ==============================================================================
resource "databricks_job" "job_carga" {
  name = "Job-ETL-Carga-${var.environment}"

  git_source {
    url      = "https://github.com" # ⚠️ Insira sua URL real de Carga
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

    # 🚀 CORRIGIDO: Alterado para Standard_F4s_v2 para evitar o erro de QuotaExceeded do Azure
    new_cluster {
      spark_version = "14.3.x-scala2.12"
      node_type_id  = "Standard_F4s_v2"
      spark_conf = {
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

  git_source {
    url      = "https://github.com" # ⚠️ Insira sua URL real de Consulta
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

    # 🚀 CORRIGIDO: Alterado para Standard_F4s_v2 para evitar o erro de QuotaExceeded do Azure
    new_cluster {
      spark_version = "14.3.x-scala2.12"
      node_type_id  = "Standard_F4s_v2"
      spark_conf = {
        "spark.master" : "local[*]"
      }
      azure_attributes {
        availability = "ON_DEMAND_AZURE"
      }
    }
  }
}
