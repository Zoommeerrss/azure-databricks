# Databricks notebook source
from pyspark.sql.types import StructType, StructField, StringType

print("Iniciando o Projeto de Carga de Dados no Unity Catalog...")

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
print("Salvando tabela dev_catalog.student.tbl_student_info...")
df_students.write.mode("overwrite").saveAsTable("dev_catalog.student.tbl_student_info")

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
print("Salvando tabela dev_catalog.course.tbl_course_info...")
df_courses.write.mode("overwrite").saveAsTable("dev_catalog.course.tbl_course_info")

print("Carga concluída com sucesso!")
