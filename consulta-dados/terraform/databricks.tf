# ==============================================================================
# 1. PUBLICAÇÃO DOS ARQUIVOS DE CÓDIGO (Notebook e Módulos Analíticos)
# ==============================================================================

# Publica o Notebook Jupyter de Consulta/Dashboard
resource "databricks_notebook" "nb_consulta" {
  source_path = "${path.module}/../notebooks/nb_consulta_dados.ipynb"
  path        = "${local.workspace_base_path}/nb_consulta_dados"
  language    = "PYTHON"
  format      = "JUPYTER"
}

# Publica o script python complementar de suporte à consulta
resource "databricks_workspace_file" "consulta_dados_py" {
  source_path = "${path.module}/../src/consulta_dados.py"
  path        = "${local.workspace_base_path}/src/consulta_dados.py"
}

# Publica o arquivo de dependências de bibliotecas do projeto analítico
resource "databricks_workspace_file" "requirements" {
  source_path = "${path.module}/../requirements.txt"
  path        = "${local.workspace_base_path}/requirements.txt"
}

# ==============================================================================
# 2. DEFINIÇÃO DO ORQUESTRADOR (Job Cluster Ephemeral Low-Cost - JOB 2)
# ==============================================================================

resource "databricks_job" "pipeline_consulta" {
  # 🚀 DINÂMICO: Gera 'JOB_2_PIPELINE_DE_CONSULTA_DEV' ou 'JOB_2_PIPELINE_DE_CONSULTA_PROD'
  name = "JOB_2_PIPELINE_DE_CONSULTA_${upper(var.environment)}"

  new_cluster {
    num_workers   = 0  # Configuração Single Node para economia em laboratórios
    spark_version = "14.3.x-scala2.12"
    node_type_id  = "Standard_F4s_v2"

    spark_conf = {
      "spark.databricks.cluster.profile" = "singleNode"
    }
  }

  task {
    task_key = "executar_nb_consulta"

    notebook_task {
      notebook_path = databricks_notebook.nb_consulta.path
    }

    # 🚀 CORRIGIDO: Estrutura oficial utilizando o bloco pypi e o atributo package
    library {
      pypi {
        package = "plotly==5.18.0"
      }
    }
  }
}
