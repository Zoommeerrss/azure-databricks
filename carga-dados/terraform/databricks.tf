# ==============================================================================
# 1. PUBLICAÇÃO DOS ARQUIVOS DE CÓDIGO (Notebook, Módulos e Dependências)
# ==============================================================================

# 🚀 CORRIGIDO: Alterado de source_path para source
resource "databricks_notebook" "nb_carga" {
  source   = "${path.module}/../notebooks/nb_carga_dados.ipynb"
  path     = "${local.workspace_base_path}/nb_carga_dados"
  language = "PYTHON"
  format   = "JUPYTER"
}

# 🚀 CORRIGIDO: Alterado de source_path para source em todos os arquivos de workspace
resource "databricks_workspace_file" "index" {
  source = "${path.module}/../src/__index__.py"
  path   = "${local.workspace_base_path}/src/__index__.py"
}

resource "databricks_workspace_file" "carga_dados_py" {
  source = "${path.module}/../src/carga_dados.py"
  path   = "${local.workspace_base_path}/src/carga_dados.py"
}

resource "databricks_workspace_file" "requirements" {
  source = "${path.module}/../requirements.txt"
  path   = "${local.workspace_base_path}/requirements.txt"
}

# ==============================================================================
# 2. DEFINIÇÃO DO ORQUESTRADOR (Job Cluster Ephemeral Low-Cost)
# ==============================================================================

resource "databricks_job" "pipeline_carga" {
  name = "JOB_1_PIPELINE_DE_CARGA_${upper(var.environment)}"

  new_cluster {
    num_workers   = 0  
    spark_version = "14.3.x-scala2.12"
    node_type_id  = "Standard_F4s_v2"

    spark_conf = {
      "spark.databricks.cluster.profile" = "singleNode"
    }
  }

  task {
    task_key = "executar_nb_carga"

    notebook_task {
      notebook_path = databricks_notebook.nb_carga.path
    }

    # Mantendo a leitura automatizada e dinâmica do requirements.txt que você definiu
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
