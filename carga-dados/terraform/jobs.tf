# ==============================================================================
# PROJETO CARGA-DADOS: PIPELINE E ORQUESTRACÃO (JOB CLUSTER EPHEMERAL)
# ==============================================================================

resource "databricks_job" "pipeline_carga" {
  name                = "Pipeline-Automatizado-Carga-${var.environment}"
  max_concurrent_runs = 1

  # 🔥 CONDICIONAL: Só injeta o bloco git_source se a URL não for genérica ou se for Fase 2
  dynamic "git_source" {
    for_each = var.git_branch != "dev" && var.git_branch != "main" ? [] : [1] # Ajuste conforme sua conveniência de flag
    content {
      url      = "https://github.com" # Substitua quando liberado
      provider = "gitHub"
      branch   = var.git_branch
    }
  }

  task {
    task_key = "Carga_Dados_Estudantes"

    notebook_task {
      # 🔥 DINÂMICO: Se for Fase 1 (Local), aponta para o caminho que seu orquestrador subiu no WS. Se for Fase 2, lê a raiz do Git.
      notebook_path = var.git_branch == "local_wsl" ? "${local.workspace_base_path}/notebooks/nb_carga_dados" : "nb_carga_dados"
      source        = var.git_branch == "local_wsl" ? "WORKSPACE" : "GIT"

      base_parameters = {
        catalog_name = databricks_catalog.carga.name
      }
    }

    library {
      requirements = "requirements.txt"
    }

    dynamic "new_cluster" {
      for_each = [1]
      content {
        spark_version = "14.3.x-scala2.12"
        node_type_id  = "Standard_F4s_v2"

        spark_conf = {
          "spark.master" = "local[*]"
        }

        azure_attributes {
          availability = "ON_DEMAND_AZURE"
        }
      }
    }
  }

  tags = local.global_tags

  depends_on = [
    databricks_catalog.carga,
    databricks_schema.student,
    databricks_schema.course
  ]
}
