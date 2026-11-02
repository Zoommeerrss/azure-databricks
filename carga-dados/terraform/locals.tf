locals {
  env = var.environment

  # ============================================================================
  # DADOS DA APLICAÇÃO
  # ============================================================================

  catalog_name = "catalog_carga_${local.env}"

  student_schema_name = "student"

  course_schema_name = "course"

  raw_volume_name = "arquivos_brutos"

  # ============================================================================
  # WORKSPACE
  # ============================================================================

  workspace_base_path = "/Shared/Production/carga-dados_${local.env}"

  # ============================================================================
  # TAGS
  # ============================================================================

  global_tags = {
    Environment = local.env
    Project     = "Carga-Dados"
    ManagedBy   = "Terraform"
    CostCenter  = "Auditoria-DataQuality-${local.env}"
    Layer       = "Data-App-Carga"
  }
}