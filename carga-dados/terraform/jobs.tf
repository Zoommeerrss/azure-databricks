# ==============================================================================
# PROJETO CARGA-DADOS: PIPELINE E ORQUESTRACÃO (JOB CLUSTER EPHEMERAL)
# ==============================================================================

resource "databricks_job" "pipeline_carga" {
  name                = "Pipeline-Automatizado-Carga-${var.environment}"
  max_concurrent_runs = 1

  # 🔒 FASE 1 (WSL Local): Bloco Git comentado para impedir que o Databricks tente buscar uma URL inválida
  # dynamic "git_source" {
  #   for_each = var.git_branch != "dev" && var.git_branch != "main" ? [] : [1]
  #   content {
  #     url      = "https://github.com"
  #     provider = "gitHub"
  #     branch   = var.git_branch
  #   }
  # }

  task {
    task_key = "Carga_Dados_Estudantes"

    notebook_task {
      # 🚀 TRAVADO NO WORKSPACE: Lê direto o notebook que o Terraform acabou de subir com sucesso
      notebook_path = databricks_notebook.nb_carga.path
      source        = "WORKSPACE"

      base_parameters = {
        catalog_name = databricks_catalog.carga.name
      }
    }

    library {
      requirements = "/Workspace${databricks_workspace_file.requirements.path}"
    }

    dynamic "new_cluster" {
      for_each = [1]
      content {
        # 🔥 GARANTE O SINGLE-NODE: Força zero workers, o que desliga a necessidade da flag conflitante
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

  }

  tags = local.global_tags

  # 🔥 CORRIGIDO: Inclui a dependência do notebook e do requirements para blindar o nascimento do Job contra caminhos fantasmas
  depends_on = [
    databricks_catalog.carga,
    databricks_schema.student,
    databricks_schema.course,
    databricks_notebook.nb_carga,
    databricks_workspace_file.requirements
  ]
}
