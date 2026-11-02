# terraform/workspace.tf

# ==============================================================================
# 📂 CRIAÇÃO ESTRUTURADA DA PASTA NO WORKSPACE (AUTOMÁTICO)
# ==============================================================================
resource "databricks_directory" "parent_dir" {
  path = local.workspace_base_path
}

# ==============================================================================
# PUBLICAÇÃO DO NOTEBOOK DE INGESTÃO (Faz o arquivo aparecer no portal)
# ==============================================================================
resource "databricks_notebook" "nb_consulta" {
  source     = "${path.module}/../notebooks/nb_consulta_dados.ipynb"
  path       = "${local.workspace_base_path}/nb_consulta_dados"
  language   = "PYTHON"
  format     = "JUPYTER"
  depends_on = [databricks_directory.parent_dir]
}

# ==============================================================================
# PUBLICAÇÃO DAS DEPENDÊNCIAS DO PROJETO
# ==============================================================================
resource "databricks_workspace_file" "requirements" {
  source     = "${path.module}/../requirements.txt"
  path       = "${local.workspace_base_path}/requirements.txt"
  depends_on = [databricks_directory.parent_dir]
}
