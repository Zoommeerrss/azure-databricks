# ==============================================================================
# 1. PUBLICAÇÃO DOS ARQUIVOS DE CÓDIGO (Notebook, Módulos e Dependências)
# ==============================================================================

# Publica o Notebook Jupyter principal de Carga no caminho isolado do ambiente
resource "databricks_notebook" "nb_carga" {
  source_path = "${path.module}/../notebooks/nb_carga_dados.ipynb"
  path        = "${local.workspace_base_path}/nb_carga_dados"
  language    = "PYTHON"
  format      = "JUPYTER"
}

# Publica os scripts complementares da pasta src/ como arquivos de Workspace
resource "databricks_workspace_file" "index" {
  source_path = "${path.module}/../src/__index__.py"
  path        = "${local.workspace_base_path}/src/__index__.py"
}

resource "databricks_workspace_file" "carga_dados_py" {
  source_path = "${path.module}/../src/carga_dados.py"
  path        = "${local.workspace_base_path}/src/carga_dados.py"
}

# Publica o arquivo de dependências de bibliotecas do projeto
resource "databricks_workspace_file" "requirements" {
  source_path = "${path.module}/../requirements.txt"
  path        = "${local.workspace_base_path}/requirements.txt"
}

# ==============================================================================
# 2. DEFINIÇÃO DO ORQUESTRADOR (Job Cluster Ephemeral Low-Cost)
# ==============================================================================

resource "databricks_job" "pipeline_carga" {
  # 🚀 DINÂMICO: Gera 'JOB_1_PIPELINE_DE_CARGA_DEV' ou 'JOB_1_PIPELINE_DE_CARGA_PROD'
  name = "JOB_1_PIPELINE_DE_CARGA_${upper(var.environment)}"

  # Computação de Tarefa isolada usando Standard_F4s_v2 para controle estrito de custos e cotas
  new_cluster {
    num_workers   = 0  # Configuração Single Node ideal para otimização financeira
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

    # 🚀 CORRIGIDO: Estrutura oficial para a biblioteca Pydantic
    library {
      pypi {
        package = "pydantic==2.6.1"
      }
    }
  }
}
