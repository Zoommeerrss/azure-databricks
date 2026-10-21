# ==============================================================================
# 1. PUBLICAÇÃO DOS ARQUIVOS DE CÓDIGO (Notebook e Módulos Analíticos)
# ==============================================================================

# 🚀 CORRIGIDO: Alterado de source_path para source
resource "databricks_notebook" "nb_consulta" {
  source   = "${path.module}/../notebooks/nb_consulta_dados.ipynb"
  path     = "${local.workspace_base_path}/nb_consulta_dados"
  language = "PYTHON"
  format   = "JUPYTER"
}

# 🚀 CORRIGIDO: Alterado de source_path para source
resource "databricks_workspace_file" "consulta_dados_py" {
  source = "${path.module}/../src/consulta_dados.py"
  path   = "${local.workspace_base_path}/src/consulta_dados.py"
}

resource "databricks_workspace_file" "requirements" {
  source = "${path.module}/../requirements.txt"
  path   = "${local.workspace_base_path}/requirements.txt"
}

# ==============================================================================
# 2. DEFINIÇÃO DO ORQUESTRADOR (Job Cluster Ephemeral Low-Cost - JOB 2)
# ==============================================================================

resource "databricks_job" "pipeline_consulta" {
  name = "JOB_2_PIPELINE_DE_CONSULTA_${upper(var.environment)}"

  new_cluster {
    num_workers   = 0  
    spark_version = "14.3.x-scala2.12"
    node_type_id  = "Standard_F4s_v2"
    spark_conf    = { "spark.databricks.cluster.profile" = "singleNode" }
  }

  task {
    task_key = "executar_nb_consulta"

    notebook_task {
      notebook_path = databricks_notebook.nb_consulta.path
    }

    dynamic "library" {
      for_each = compact(split("\n", file("${path.module}/../requirements.txt")))
      content {
        pypi {
          package = library.value
        }
      }
    }
  }
}
