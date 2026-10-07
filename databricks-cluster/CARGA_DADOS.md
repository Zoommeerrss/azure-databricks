# 📥 Projeto: Verificação e Validação de Carga de Dados

Este repositório contém o script de auditoria e qualidade de dados focado em validar o status da carga do ecossistema **Azure Databricks**. De acordo com as diretrizes de arquitetura do cliente, este projeto foi totalmente apartado da receita de infraestrutura (Terraform) e opera de forma independente, possuindo seu próprio ciclo de vida, dependências e pipeline de CI/CD.

## 🎯 Objetivo do Projeto
O script contido neste repositório não realiza o processamento pesado de ETL. Sua função exclusiva é atuar como um **Data Quality Gate (Sanity Check)**, validando se os dados de Alunos (`student`) e Cursos (`course`) foram descarregados corretamente no Data Lake (ADLS Gen2) antes de liberar o acesso para as camadas analíticas e dashboards.

---

## 📁 Estrutura do Repositório

```text
projeto-carga-dados/
├── .github/
│   └── (Opcional: Fluxos de governança do repositório)
├── azure-pipelines.yml   # Pipeline de CI/CD isolada para o Azure DevOps
├── check_carga.py        # Script principal em Python/Spark SQL (Executado no Databricks)
├── requirements.txt      # Dependências Python exclusivas deste contexto de negócio
└── README.md             # Documentação técnica do projeto
```

---

## 🛠️ Stack Técnica e Dependências

As dependências deste projeto são isoladas em nível de tarefa (*Task-level*) no Databricks, garantindo que versões específicas de bibliotecas de validação não gerem conflitos com outros projetos da organização.

O arquivo `requirements.txt` gerencia pacotes necessários para validações estatísticas e de integridade (Exemplo):
```text
pandas>=2.0.0
pytest>=7.0.0
great-expectations>=0.18.0
```

---

## 🚀 Script de Auditoria (`check_carga.py`)

O script roda sob o perfil **Single Node** no Databricks utilizando o modo de segurança `USER_ISOLATION` para garantir conformidade com o **Unity Catalog**. Ele realiza as seguintes validações:

1. **Checagem de Volumetria:** Garante que a tabela `dev_catalog.student.tbl_student_info` não está vazia (`COUNT > 0`).
2. **Validação de Schema:** Verifica se não houve alteração estrutural ou novos campos não homologados.
3. **Check de Timestamps:** Garante que os dados presentes na camada física refletem a carga do dia corrente.

---

## 🔄 Pipeline de CI/CD (`azure-pipelines.yml`)

O deploy e a execução do projeto são gerenciados de forma 100% automatizada pelo **Azure DevOps Pipelines** integrado de forma segura ao **GitHub**. 

```text
[ Alteração no GitHub ] ➡️ [ Disparo Azure DevOps ] ➡️ [ Token OAuth Dinâmico ] ➡️ [ API Databricks (Task 1) ]
```

### Mecanismo de Funcionamento:
1. **Trigger Automático:** Qualquer alteração consolidada na branch `main` dispara a esteira no Azure DevOps.
2. **Autenticação Segura:** A pipeline utiliza um **Service Principal (App Registration)** da Azure para gerar tokens OAuth de curta duração, eliminando o uso de senhas ou PATs expiráveis.
3. **Execução Direta por API:** O Azure DevOps aciona unicamente a tarefa `1_Verificar_Status_Carga` dentro do Job Orquestrado do Databricks. O Databricks faz o clone em tempo de execução deste repositório, instala as dependências do `requirements.txt` e executa o `check_carga.py`.

### Variáveis de Ambiente Necessárias (Azure DevOps Library):
Para o correto funcionamento da pipeline, garanta que o grupo de variáveis `databricks-secrets` contenha os seguintes parâmetros do Service Principal da Azure:
* `AZURE_TENANT_ID`
* `AZURE_CLIENT_ID`
* `AZURE_CLIENT_SECRET`

---

## ⚠️ Regras de Orquestração (Garantia de Ordem)
Este projeto é o **Gatilho Inicial** da esteira de dados. Caso o script `check_carga.py` encontre alguma anomalia crítica (dados nulos, tabelas zeradas ou falha de conectividade), o script retornará um código de erro (`exit 1`). 

Por conta da dependência sequencial configurada no cluster, **o Databricks abortará o fluxo imediatamente**, impedindo que o projeto subsequente de *Consulta e Dashboard* consuma dados corrompidos.
