# 📊 Projeto: Consulta Analítica e Dashboard de Dados

Este repositório armazena o script analítico e gerencial do ecossistema **Azure Databricks**. Seguindo os novos requisitos de arquitetura definidos pelo cliente, este projeto foi totalmente apartado da receita de infraestrutura (Terraform) e do projeto de carga. Ele possui governança própria, seu arquivo independente de dependências (`requirements.txt`) e sua própria esteira de CI/CD.

## 🎯 Objetivo do Projeto
A função principal do script contido neste repositório é atuar na **camada de consumo (Gold/Analytics)**. Ele realiza o cruzamento de dados (como `JOINs` entre tabelas de Estudantes e Cursos) e agrega as métricas volumétricas para servir como a base lógica de um Dashboard Analítico Interativo, consolidando as visões de negócios exigidas pelo cliente.

---

## 📁 Estrutura do Repositório

```text
projeto-consulta-dados/
├── .github/
│   └── (Opcional: Regras de governança e aprovação do repositório)
├── azure-pipelines.yml      # Pipeline de CI/CD isolada no Azure DevOps
├── dashboard_consulta.py    # Script analítico em Python/Spark (Executado no Databricks)
├── requirements.txt         # Bibliotecas de visualização e análise exclusivas deste projeto
└── README.md                # Documentação técnica do projeto
```

---

## 🛠️ Stack Técnica e Dependências

Este projeto gerencia suas dependências de forma isolada no nível da tarefa (*Task-level*) no Databricks. Isso garante que bibliotecas gráficas ou de manipulação analítica mais recentes não causem conflito com as ferramentas de validação do projeto de carga.

O arquivo `requirements.txt` contém os pacotes específicos para engenharia analítica e geração de relatórios (Exemplo):
```text
numpy>=1.24.0
plotly>=5.14.0
matplotlib>=3.7.0
```

---

## 🚀 Script de Visualização (`dashboard_consulta.py`)

O script é executado sob o cluster **Single Node** econômico, utilizando o modo de segurança `USER_ISOLATION` exigido para ler as tabelas protegidas pela governança trilinear do **Unity Catalog** (`catalogo.esquema.tabela`).

### Fluxo de Execução:
1. **Consumo Seguro:** Lê as tabelas estruturadas `dev_catalog.student.tbl_student_info` e `dev_catalog.course.tbl_course_info`.
2. **Processamento Spark:** Realiza o relacionamento cruzado dos dados de alunos matriculados por categoria de curso.
3. **Agregação:** Gera o DataFrame consolidado que alimenta os relatórios gerenciais da empresa.

---

## 🔄 Pipeline de CI/CD (`azure-pipelines.yml`)

A automação deste repositório é gerenciada de forma isolada por uma pipeline do **Azure DevOps**, integrada nativamente ao **GitHub** via *Service Connection* segura.

```text
[ Commits na Main ] ➡️ [ Disparo Azure DevOps ] ➡️ [ Token OAuth Dinâmico ] ➡️ [ API Databricks (Task 2) ]
```

### Mecanismo de Funcionamento:
1. **Gatilho de Alteração:** Toda atualização consolidada na branch `main` dispara a esteira de deploy no Azure DevOps.
2. **Segurança Corporativa:** A pipeline autentica na Azure via **Service Principal (App Registration)** para obter credenciais temporárias por API, sem o uso de chaves fixas.
3. **Deploy e Execução Independente:** O Azure DevOps aciona diretamente a tarefa `2_Consulta_e_Verificacao` no Job do Databricks. O Databricks clona a versão mais recente deste repositório no GitHub, instala o `requirements.txt` analítico e executa o script de dashboard.

---

## ⚠️ Dependência de Orquestração (Garantia de Ordem)
Embora esta pipeline possa ser disparada manualmente ou via esteira para testes rápidos do time de Analytics, na esteira produtiva **ela possui uma dependência obrigatória da Tarefa de Carga**. 

Conforme o desenho de arquitetura aprovado, este script **só será executado se o projeto anterior (`projeto-carga-dados`) finalizar com sucesso**. Caso o check de carga falhe, esta consulta analítica é automaticamente abortada pelo Databricks para evitar a exibição de relatórios com dados desatualizados ou corrompidos.
