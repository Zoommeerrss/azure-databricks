# ==============================================================================
# DATABRICKS CATALOG
# ==============================================================================

output "catalog_name" {
  description = "Nome do catálogo Unity Catalog do ambiente"
  value       = local.databricks_catalog_name
}

# ==============================================================================
# CLUSTER COMPARTILHADO (OPCIONAL)
# ==============================================================================

output "interactive_cluster_id" {
  description = "ID do cluster compartilhado do ambiente"
  # Corrigido para acessar o índice [0] do count com segurança caso local.enable_cluster seja true
  value       = try(databricks_cluster.single_node[0].id, null)
}
