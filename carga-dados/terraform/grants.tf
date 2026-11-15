# ==============================================================================
# CONTRATO DE GOVERNANÇA E COMPARTILHAMENTO DE DADOS (UNITY CATALOG GRANTS)
# Responsabilidade: Definir explicitamente quais consumidores podem ler os dados
# publicados por esta aplicação (Producer -> Consumers).
# ==============================================================================

# grants.tf (No repositório Producer)
# 1. Valida dinamicamente que todos os N grupos existem na Databricks Account
data "databricks_group" "offer_groups" {
  for_each     = toset(var.authorized_offer_groups)
  display_name = each.value
}

# 2. Concede acesso ao Catálogo para todos os N grupos autorizados
resource "databricks_grants" "catalog_access" {
  catalog = databricks_catalog.carga.name

  dynamic "grant" {
    for_each = data.databricks_group.offer_groups
    content {
      principal  = grant.value.display_name
      privileges = ["USE_CATALOG"]
    }
  }
}

# 3. Concede leitura (SELECT) nos schemas democratizados (student e course)
resource "databricks_grants" "student_schema_access" {
  schema = "${databricks_catalog.carga.name}.${databricks_schema.student.name}"

  dynamic "grant" {
    for_each = data.databricks_group.offer_groups
    content {
      principal  = grant.value.display_name
      privileges = ["USE_SCHEMA", "SELECT"]
    }
  }
}

resource "databricks_grants" "course_schema_access" {
  schema = "${databricks_catalog.carga.name}.${databricks_schema.course.name}"

  dynamic "grant" {
    for_each = data.databricks_group.offer_groups
    content {
      principal  = grant.value.display_name
      privileges = ["USE_SCHEMA", "SELECT"]
    }
  }
}

resource "databricks_permissions" "jobs_access" {
  for_each = local.app_jobs
  job_id   = each.value

  dynamic "access_control" {
    for_each = data.databricks_group.offer_groups
    content {
      group_name       = access_control.value.display_name
      permission_level = "CAN_VIEW"
    }
  }
}