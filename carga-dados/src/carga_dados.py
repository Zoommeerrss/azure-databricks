# Databricks notebook source
from pyspark.sql.types import StructType, StructField, StringType

print("Iniciando o Projeto de Carga de Dados no Unity Catalog...")

# 🚀 CAPTURA DINÂMICA: Resgata o nome do catálogo injetado pelo Job do Terraform
dbutils.widgets.text("catalog_name", "dbw_dbx_lowcost_dev")
catalog = dbutils.widgets.get("catalog_name")
print(f"🎯 Conectando ao catálogo de governança: {catalog}")

# ==============================================================================
# 1. PROCESSAMENTO E CARGA DE ESTUDANTES
# ==============================================================================
student_data = [
    ("1", "Ana Silva", "C01"),
    ("2", "Bruno Costa", "C02"),
    ("3", "Carlos Souza", "C01"),
    ("4", "Daniela Lima", "C03")
]

student_schema = StructType([
    StructField("student_id", StringType(), True),
    StructField("name", StringType(), True),
    StructField("course_id", StringType(), True)
])

df_students = spark.createDataFrame(student_data, schema=student_schema)

# 🚀 DINÂMICO: Caminho de gravação adaptável ao ambiente
target_student_table = f"{catalog}.student.tbl_student_info"
print(f"Salvando tabela {target_student_table}...")
df_students.write.mode("overwrite").saveAsTable(target_student_table)

# ==============================================================================
# 2. PROCESSAMENTO E CARGA DE CURSOS
# ==============================================================================
course_data = [
    ("C01", "Engenharia de Dados"),
    ("C02", "Ciência de Dados"),
    ("C03", "Arquitetura de Nuvem")
]

course_schema = StructType([
    StructField("course_id", StringType(), True),
    StructField("course_name", StringType(), True)
])

df_courses = spark.createDataFrame(course_data, schema=course_schema)

# 🚀 DINÂMICO: Caminho de gravação adaptável ao ambiente
target_course_table = f"{catalog}.course.tbl_course_info"
print(f"Salvando tabela {target_course_table}...")
df_courses.write.mode("overwrite").saveAsTable(target_course_table)

print("Carga concluída com sucesso!")
