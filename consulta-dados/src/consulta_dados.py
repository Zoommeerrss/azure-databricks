# Databricks notebook source
from pyspark.sql import functions as F

print("Iniciando o Projeto de Consulta / Dashboard do Unity Catalog...")

df_students = spark.read.table("dev_catalog.student.tbl_student_info")
df_courses = spark.read.table("dev_catalog.course.tbl_course_info")

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

print("Visão do Dashboard:")
display(df_dashboard)
