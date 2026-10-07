# Definição do Job Automatizado (Workflow) no Databricks
resource "databricks_job" "pipeline_estudantes" {
  name = "Pipeline-Automatizado-Alunos-Cursos"

  # Mantém um histórico de execuções limpo para economizar metadados
  max_concurrent_runs = 1

  # TAREFA 1: Executar o Notebook de Carga de Dados
  task {
    task_key = "Carga_Dados_Estudantes"

    # Reaproveita o cluster de baixo custo existente (Garante Custo Mínimo)
    existing_cluster_id = databricks_cluster.cheap_cluster[0].id

    notebook_task {
      notebook_path = databricks_notebook.carga_dados.path
    }
  }

  # TAREFA 2: Executar o Notebook de Consulta (Dashboard) após a Carga
  task {
    task_key = "Consulta_Dashboard"

    # Garante a execução apenas após a conclusão com sucesso da Tarefa 1
    depends_on {
      task_key = "Carga_Dados_Estudantes"
    }

    # Reaproveita o mesmo cluster Single Node
    existing_cluster_id = databricks_cluster.cheap_cluster[0].id

    notebook_task {
      notebook_path = databricks_notebook.consulta_dados.path
    }
  }

  tags = local.common_tags
}
