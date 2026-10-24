# ==============================================================================
# 1. PUBLICAÇÃO DOS ARQUIVOS DE CÓDIGO (Notebook, Módulos e Dependências)
# ==============================================================================
resource "databricks_notebook" "nb_consulta" {
  source   = "${path.module}/../notebooks/nb_consulta_dados.ipynb"
  path     = "${local.workspace_base_path}/nb_consulta_dados"
  language = "PYTHON"
  format   = "JUPYTER"
}

# Mantido idêntico ao seu padrão
resource "databricks_workspace_file" "index" {
  source = "${path.module}/../src/__index__.py"
  path   = "${local.workspace_base_path}/src/__index__.py"
}

# 🚀 CORRIGIDO: Nome do recurso e caminhos apontando corretamente para o script de consulta real
resource "databricks_workspace_file" "consulta_dados_py" {
  source = "${path.module}/../src/consulta_dados.py"
  path   = "${local.workspace_base_path}/src/consulta_dados.py"
}

# Mantido idêntico ao seu padrão
resource "databricks_workspace_file" "requirements" {
  source = "${path.module}/../requirements.txt"
  path   = "${local.workspace_base_path}/requirements.txt"
}

# ==============================================================================
# 2. DEFINIÇÃO DO ORQUESTRADOR (Job Cluster Ephemeral Low-Cost)
# ==============================================================================
resource "databricks_job" "pipeline_consulta" {
  # 🚀 CORRIGIDO: Alterado para JOB_2 e padronizado o sufixo analítico em maiúsculo
  name = "JOB_2_PIPELINE_DE_CONSULTA_${upper(var.environment)}"

  # 🚀 FRONTEIRA: Vincula as tags de governança exclusivas da camada analítica
  tags = local.global_tags

  new_cluster {
    num_workers   = 0  
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
  }

  # 🚀 AUTOMÁTICO: Carrega dinamicamente os pacotes gráficos (ex: Plotly, Seaborn) do requirements.txt analítico no cluster
  dynamic "library" {
    for_each = compact(split("\n", file("${path.module}/../requirements.txt")))
    content {
      pypi {
        package = library.value
      }
    }
  }

  # 🚀 SEGURANÇA: O Job só pode ser criado/atualizado DEPOIS que o vínculo do catálogo estiver ativo
  depends_on = [databricks_workspace_binding.catalog_binding]
}

# 🚀 GOVERNANÇA: Força o Unity Catalog a liberar o catálogo para o Workspace atual,
# eliminando definitivamente o erro de INSUFFICIENT_PERMISSIONS (42501)
resource "databricks_workspace_binding" "catalog_binding" {
  securable_type = "catalog"
  securable_name = local.databricks_catalog_name # "dbw_dbx_lowcost_dev"
  workspace_id   = data.databricks_current_metastore.current.workspace_id # O ID do Workspace que você mapeou no dev.tfvars
}
