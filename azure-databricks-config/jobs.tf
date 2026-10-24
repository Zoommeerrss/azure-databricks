# ==============================================================================
# 1. PIPELINE DE CARGA (Conectado ao Repositório do Projeto de Carga)
# ==============================================================================
resource "databricks_job" "pipeline_carga" {
  name                = "Pipeline-Automatizado-Carga-${var.environment}"
  max_concurrent_runs = 1

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

    # 🔥 CORRIGIDO: Adicionado o índice [0] para casar com o recurso interativo criado com count
    existing_cluster_id = local.enable_cluster ? databricks_cluster.single_node[0].id : null
  }

  tags = local.global_tags
}

# ==============================================================================
# 2. PIPELINE DE CONSULTA (Conectado ao Repositório do Projeto de Consulta)
# ==============================================================================
resource "databricks_job" "pipeline_consulta" {
  name                = "Pipeline-Automatizado-Consulta-${var.environment}"
  max_concurrent_runs = 1

  git_source {
    url      = "https://github.com" # ⚠️ Sua URL real de Consulta
    provider = "gitHub"
    branch   = var.git_branch
  }

  task {
    task_key = "Consulta_Dashboard"

    notebook_task {
      notebook_path = "nb_consulta_dashboard.ipynb"
      source        = "GIT"
    }

    library {
      requirements = "requirements.txt"
    }

    # 🔥 CORRIGIDO: Adicionado o índice [0] para casar com o recurso interativo criado com count
    existing_cluster_id = local.enable_cluster ? databricks_cluster.single_node[0].id : null
  }

  tags = local.global_tags
}