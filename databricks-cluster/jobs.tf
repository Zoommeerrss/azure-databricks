# ==============================================================================
# DEFINIÇÃO DO JOB AUTOMATIZADO (WORKFLOW) NO DATABRICKS
# ==============================================================================
resource "databricks_job" "pipeline_estudantes" {
  # Adiciona o sufixo dinâmico para isolar os ambientes (-dev ou -prod)
  name = "Pipeline-Automatizado-Alunos-Cursos-${local.env}"

  # Mantém um histórico de execuções limpo para economizar metadados
  max_concurrent_runs = 1

  # Configuração unificada do repositório Git para todas as tarefas
  git_source {
    url      = "https://github.com"
    provider = "gitHub"
    branch   = var.git_branch
  }

  # ----------------------------------------------------------------------------
  # TAREFA 1: Executar o Script Python de Carga de Dados
  # ----------------------------------------------------------------------------
  task {
    task_key = "Carga_Dados_Estudantes"

    spark_python_task {
      python_file = "check_carga.py" 
      source      = "GIT"
    }

    library {
      requirements = "requirements.txt"
    }

    # Corrigido: Aponta para o cluster correto ('single_node') com tratamento seguro de count
    existing_cluster_id = local.enable_cluster ? databricks_cluster.single_node[0].id : null
  }

  # ----------------------------------------------------------------------------
  # TAREFA 2: Executar o Script Python de Consulta (Dashboard) após a Carga
  # ----------------------------------------------------------------------------
  task {
    task_key = "Consulta_Dashboard"

    depends_on {
      task_key = "Carga_Dados_Estudantes"
    }

    spark_python_task {
      python_file = "dashboard_consulta.py"
      source      = "GIT"
    }

    library {
      requirements = "requirements.txt"
    }

    # Corrigido: Aponta para o cluster correto ('single_node') com tratamento seguro de count
    existing_cluster_id = local.enable_cluster ? databricks_cluster.single_node[0].id : null
  }

  # Corrigido: Aponta para a variável de tags correta definida no seu locals.tf
  tags = local.global_tags
}
