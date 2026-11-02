# ==============================================================================
# PIPELINE DE CONSULTA (Responsabilidade exclusiva do Projeto de Consulta)
# ==============================================================================
resource "databricks_job" "pipeline_consulta" {
  name                = "Pipeline-Automatizado-Consulta-${var.environment}"
  max_concurrent_runs = 1

  # 🔒 FASE 1 (WSL Local): Bloco Git comentado para a API aceitar a rota do Workspace
  # git_source {
  #   url      = "https://github.com"
  #   provider = "gitHub"
  #   branch   = var.git_branch
  # }

  task {
    task_key = "Consulta_Dashboard"

    notebook_task {
      notebook_path = databricks_notebook.nb_consulta.path
      source        = "WORKSPACE"
      
      base_parameters = {
        # 🚀 AJUSTADO: Passa apenas o catálogo onde o Spark gravou as tabelas físicas com sucesso!
        catalog_name = local.source_catalog_name
      }
    }

    library {
      requirements = "/Workspace${databricks_workspace_file.requirements.path}"
    }

    # 🚀 CORRIGIDO: Removida a flag fantasma local.enable_cluster. 
    # O Job Cluster Ephemeral agora nasce de forma direta, limpa e de baixo custo!
    new_cluster {
      num_workers   = 0
      spark_version = "15.4.x-scala2.12"
      node_type_id  = "Standard_F4s_v2"

      spark_conf = {
        "spark.master" = "local[*]"
      }

      azure_attributes {
        availability = "ON_DEMAND_AZURE"
      }
    }

  }

  tags = local.global_tags

  depends_on = [
    databricks_notebook.nb_consulta,
    databricks_workspace_file.requirements
  ]
}
