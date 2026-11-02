# ==============================================================================
# PIPELINE DE CONSULTA (Responsabilidade exclusiva do Projeto de Consulta)
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
      
      # 🚀 CORRIGIDO: Entrega ao notebook tanto o catálogo analítico quanto o catálogo de origem de dados
      base_parameters = {
        catalog_name        = local.databricks_catalog_name
        source_catalog_name = local.source_catalog_name # Mapeado de forma previsível no seu locals.tf
      }
    }

    library {
      requirements = "requirements.txt"
    }

    # 🔥 DINÂMICO: Se o cluster interativo existir, usa ele. Se não, deixa nulo e ativa o bloco abaixo.
    # Nota: Caso o recurso databricks_cluster.single_node pertença ao repo global (config), substitua por var.interactive_cluster_id herdado do state anterior
    existing_cluster_id = local.enable_cluster ? var.databricks_workspace_numeric_id : null 

    # 🚀 SOLUÇÃO DE COTA: Só cria o cluster ephemeral se o cluster interativo estiver desativado (count = 0 ou 1)
    dynamic "new_cluster" {
      for_each = local.enable_cluster ? [] : [1]
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
}
