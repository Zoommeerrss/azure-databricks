# 📊 Projeto de Consulta e Analytics - Databricks Decoupled Data App

Este repositório contém a aplicação analítica isolada de consulta e geração de indicadores sobre os dados de estudantes e cursos do ecossistema Databricks. Seguindo a estratégia de **Desacoplamento Total de Recursos**, este projeto gerencia de forma 100% autônoma o seu código de análise, seu respectivo Job orquestrador e seu próprio pipeline de CI/CD, consumindo as tabelas governadas via Unity Catalog de forma transparente.

---

## 🎨 1. Arquitetura e Fluxo de Publicação

O ciclo de vida deste repositório analítico é gerenciado via **Azure DevOps Pipelines** integrado ao **Terraform (Provedor Databricks)**. O deploy é completamente isolado do projeto de carga:

```text
┌────────────────────────────────────────────────────────┐
│             PROJETO GIT: consulta-dados                │
└──────────────────────────┬─────────────────────────────┘
                           │ (Gatilho por Branch: dev ou main)
                           ▼
┌────────────────────────────────────────────────────────┐
│         ESTEIRA DE CI/CD: azure-pipelines.yml          │
└──────────────────────────┬─────────────────────────────┘
                           │ (Autentica via Service Principal Oauth)
                           ▼
┌────────────────────────────────────────────────────────┐
│           CAMADA DE COMPILAÇÃO: /terraform             │
│   (Aplica o Workspace isolado e o .tfvars do ambiente) │
└──────────────────────────┬─────────────────────────────┘
                           │
                           ▼ [Publica Artefatos e Cria Job]
┌────────────────────────────────────────────────────────┐
│               WORKSPACE AZURE DATABRICKS               │
│ 📂 /Workspace/Production/consulta-dados_[dev|prod]     │
│ ⚙️ JOB_2_PIPELINE_DE_CONSULTA_[DEV|PROD]               │
└────────────────────────────────────────────────────────┘
```

---

## 📂 2. Desenho Estrutural de Pastas

Abaixo está o mapeamento exato da árvore de diretórios do repositório:

```text
consulta-dados/
├── 📂 notebooks/
│   └── 📓 nb_consulta_dados.ipynb  # Notebook Jupyter analítico (Geração de Dashboards/Consultas)
├── 📂 src/
│   └── 🐍 consulta_dados.py        # Módulos e funções Python complementares de suporte
├── 📂 terraform/
│   ├── 📂 envs/
│   │   ├── 📄 dev.tfvars           # Parâmetros de DEV (URL do Workspace de desenvolvimento)
│   │   └── 📄 prod.tfvars          # Parâmetros de PROD (URL do Workspace de produção)
│   ├── 📜 databricks.tf            # Recursos lógicos: Upload do código analítico e criação do JOB 2
│   ├── 📜 locals.tf                # Variáveis locais, tags e caminhos dinâmicos de consulta
│   ├── 📜 outputs.tf               # Exposição de IDs gerados (Job ID, caminhos) para logs da esteira
│   ├── 📜 providers.tf             # Configuração do provedor Databricks alimentado via pipeline
│   └── 📜 variables.tf             # Declaração e tipagem estrita das variáveis aceitas pelos ambientes
├── 📄 .gitignore                   # Bloqueio de arquivos locais temporários do Terraform (.terraform, state)
├── 💜 azure-pipelines.yml          # Definição e orquestração do pipeline analítico no Azure DevOps
├── 📘 CONSULTA_DADOS.md            # Documentação técnica do projeto (Este arquivo)
└── 📄 requirements.txt             # Gerenciamento dinâmico de dependências via PyPI (ex: Plotly, Seaborn)
```

---

## ⚙️ 3. Componentes e Inteligência de Infraestrutura

* **`providers.tf`**: Totalmente independente de estados físicos. Utiliza apenas a variável `databricks_workspace_url` e recebe o token de autenticação diretamente do sistema operacional (`DATABRICKS_TOKEN`) injetado pelo Azure DevOps.
* **`databricks.tf`**: Realiza o upload da estrutura lógica e provisiona o **`JOB_2_PIPELINE_DE_CONSULTA_[ENV]`**. O Job utiliza um cluster efêmero (**`Standard_F4s_v2`**) de nó único para otimização radical de custos (Low-Cost).
* **Leitura Dinâmica do `requirements.txt`**: O recurso de tarefas utiliza um bloco `dynamic "library"` que converte automaticamente as linhas do seu `requirements.txt` em bibliotecas instaladas no cluster no momento da execução, garantindo que o Terraform não precise ser alterado caso novas bibliotecas gráficas sejam adicionadas ao projeto.

---

## 🔄 4. Estratégia de Branches e Multiambiente

O isolamento lógico de ambientes é mapeado de forma nativa por Git branches e gerenciado internamente por **Terraform Workspaces**:

| Branch Git | Ambiente Terraform | Arquivo de Parâmetros | Sufixo do Job / Pasta no Workspace | Catálogo de Dados Alvo |
| :--- | :--- | :--- | :--- | :--- |
| `dev` | `DEV` | `terraform/envs/dev.tfvars` | `*_DEV` / `*_dev` | `dbw_dbx_lowcost_dev_7405611752750506` |
| `main` | `PROD` | `terraform/envs/prod.tfvars` | `*_PROD` / `*_prod` | `dbw_dbx_lowcost_prod_7405611752750506` |

### Fluxo de Orquestração Sequencial (Governança Externa):
Para garantir a consistência estatística e a integridade do ecossistema, a ordem sequencial de processamento é controlada na esteira de CI/CD:
1. O **`JOB_1` (Carga)** é disparado e processa as tabelas base.
2. Após o encerramento do Job 1 com sucesso completo (`exit 0`), o pipeline dispara de forma assíncrona o **`JOB_2` (Consulta)** contido neste repositório para atualizar as visões executivas e dashboards analíticos.
