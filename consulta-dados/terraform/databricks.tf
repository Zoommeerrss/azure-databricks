# ==============================================================================
# 📂 0. CRIAÇÃO ESTRUTURADA DA PASTA PAI NO WORKSPACE
# ==============================================================================
# 🚀 GARANTIA: Cria a árvore lítica de pastas para evitar erros de diretório pai inexistente
resource "databricks_directory" "parent_dir" {
  path = local.workspace_base_path
}

# ==============================================================================
# 1. PUBLICAÇÃO DOS ARQUIVOS DE CÓDIGO (Notebook, Módulos e Dependências)
# ==============================================================================
resource "databricks_notebook" "nb_consulta" {
  source     = "${path.module}/../notebooks/nb_consulta_dados.ipynb"
  path       = "${local.workspace_base_path}/nb_consulta_dados"
  language   = "PYTHON"
  format     = "JUPYTER"
  depends_on = [databricks_directory.parent_dir]
}

# Mantido idêntico ao seu padrão
resource "databricks_workspace_file" "index" {
  source     = "${path.module}/../src/__index__.py"
  path       = "${local.workspace_base_path}/src/__index__.py"
  depends_on = [databricks_directory.parent_dir]
}

# 🚀 CORRIGIDO: Nome do recurso e caminhos apontando corretamente para o script de consulta real
resource "databricks_workspace_file" "consulta_dados_py" {
  source     = "${path.module}/../src/consulta_dados.py"
  path       = "${local.workspace_base_path}/src/consulta_dados.py"
  depends_on = [databricks_directory.parent_dir]
}

# Mantido idêntico ao seu padrão
resource "databricks_workspace_file" "requirements" {
  source     = "${path.module}/../requirements.txt"
  path       = "${local.workspace_base_path}/requirements.txt"
  depends_on = [databricks_directory.parent_dir]
}

# ==============================================================================
# 2. DEFINIÇÃO DO ORQUESTRADOR (Job Cluster Ephemeral Low-Cost)
# ==============================================================================
# ==============================================================================
# 2. DEFINIÇÃO DO ORQUESTRADOR (Job Cluster Ephemeral Low-Cost)
# ==============================================================================
resource "databricks_job" "pipeline_consulta" {
  name = "JOB_2_PIPELINE_DE_CONSULTA_${upper(var.environment)}"
  tags = local.global_tags

  new_cluster {
    num_workers   = 0  
    spark_version = "14.3.x-scala2.12"
    node_type_id  = "Standard_F4s_v2"

    spark_conf = {
      "spark.databricks.cluster.profile" = "singleNode"
      "spark.master"                     = "local[*]" # Garante a execução Single-Node legítima
    }
  }

  task {
    task_key = "executar_nb_consulta"

    notebook_task {
      notebook_path = databricks_notebook.nb_consulta.path
      
      # 🚀 ADICIONADO: Injeta o mapa de catálogos vizinhos de forma automatizada na VM!
      base_parameters = {
        catalog_name        = local.databricks_catalog_name # Catálogo próprio analítico
        source_catalog_name = local.source_catalog_name     # Catálogo de ingestão (carga) descoberto
      }
    }
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
  