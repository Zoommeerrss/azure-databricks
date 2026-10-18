# ==============================================================================
# 1. PIPELINE DE CARGA (Conectado ao Repositório do Projeto de Carga)
# ==============================================================================
resource "databricks_job" "pipeline_carga" {
  name                = "Pipeline-Automatizado-Carga-${var.environment}"
  max_concurrent_runs = 1

  # 🔥 REPOSITÓRIO ISOLADO 1: Aponta estritamente para o projeto-carga-dados
  git_source {
    url      = "https://github.com" # ⚠️ Insira sua URL real
    provider = "gitHub"
    branch   = var.git_branch
  }

  task {
    task_key = "Carga_Dados_Estudantes"

    # 🔥 CORRIGIDO: Alterado para notebook real (.ipynb) no padrão nb_
    notebook_task {
      notebook_path = "nb_carga_dados.ipynb" 
      source        = "GIT"
    }

    library {
      requirements = "requirements.txt"
    }

    # Mantém a sua excelente inteligência dinâmica do arquivo YAML de configurações
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

  # 🔥 REPOSITÓRIO ISOLADO 2: Aponta estritamente para o projeto-consulta-dados
  git_source {
    url      = "https://github.com" # ⚠️ Insira sua URL real
    provider = "gitHub"
    branch   = var.git_branch
  }

  task {
    task_key = "Consulta_Dashboard"

    # 🔥 CORRIGIDO: Alterado para notebook real (.ipynb) no padrão nb_
    notebook_task {
      notebook_path = "nb_consulta_dashboard.ipynb"
      source        = "GIT"
    }

    library {
      requirements = "requirements.txt"
    }

    existing_cluster_id = local.enable_cluster ? databricks_cluster.single_node[0].id : null
  }

  tags = local.global_tags
}
