# Databricks notebook source
from pyspark.sql import functions as F

print("Iniciando o Projeto de Consulta / Dashboard do Unity Catalog...")

# 🚀 CAPTURA DINÂMICA: Resgata o nome do catálogo injetado pelo Job do Terraform
dbutils.widgets.text("catalog_name", "dbw_dbx_lowcost_dev")
catalog = dbutils.widgets.get("catalog_name")
print(f"🎯 Conectando ao catálogo de governança: {catalog}")

# ==============================================================================
# 1. LEITURA DINÂMICA DAS TABELAS (FRONTEIRA DE GOVERNANÇA ATIVA)
# ==============================================================================
# Substituído o 'dev_catalog' fixo para ler do catálogo correto do ambiente atual
df_students = spark.read.table(f"{catalog}.student.tbl_student_info")
df_courses = spark.read.table(f"{catalog}.course.tbl_course_info")

# ==============================================================================
# 2. CRUZAMENTO E AGREGAÇÃO DOS INDICADORES (MÁGICA DO SPARK)
# ==============================================================================
df_dashboard = df_students.join(
    df_courses, 
    df_students.course_id == df_courses.course_id, 
    "inner"
).groupBy(
    df_courses.course_name
).agg(
    F.count(df_students.student_id).alias("total_alunos")
).orderBy(
    F.desc("total_alunos")
)

# ==============================================================================
# 3. RENDERIZAÇÃO E HISTÓRICO DE EXCUÇÃO
# ==============================================================================
print("Visão do Dashboard:")
display(df_dashboard)
