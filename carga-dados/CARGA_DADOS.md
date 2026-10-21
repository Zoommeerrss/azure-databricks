# 🚀 Projeto de Carga de Dados (ETL) - Databricks Decoupled Data App

Este repositório contém a aplicação isolada de ingestão e carga de dados de estudantes para o ecossistema Databricks. Seguindo a estratégia de **Desacoplamento Total de Recursos**, este projeto é completamente autônomo: ele gerencia seu próprio código (notebooks e módulos Python), provisiona seu respectivo Job orquestrador e gerencia seu pipeline de CI/CD sem nenhuma dependência ou leitura de estado de infraestruturas externas.

---

## 🎨 1. Arquitetura e Fluxo de Publicação

O ciclo de vida deste repositório é gerenciado via **Azure DevOps Pipelines** integrado ao **Terraform (Provedor Databricks)**. O deploy é atômico: o código e a estrutura do pipeline de orquestração nascem e morrem juntos.

```text
┌────────────────────────────────────────────────────────┐
│              PROJETO GIT: carga-dados                  │
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
│ 📂 /Workspace/Production/carga-dados_[dev|prod]         │
│ ⚙️ JOB_1_PIPELINE_DE_CARGA_[DEV|PROD]                  │
└────────────────────────────────────────────────────────┘
```

---

## 📂 2. Desenho Estrutural de Pastas

Abaixo está o mapeamento exato da árvore de diretórios do repositório:

```text
carga-dados/
├── 📂 notebooks/
│   └── 📓 nb_carga_dados.ipynb     # Notebook Jupyter principal com as regras de negócio ETL
├── 📂 src/
│   ├── 🐍 __index__.py             # Arquivo de inicialização do pacote interno
│   └── 🐍 carga_dados.py           # Módulos e funções Python complementares de suporte
├── 📂 terraform/
│   ├── 📂 envs/
│   │   ├── 📄 dev.tfvars           # Parâmetros de DEV (URL do Workspace de desenvolvimento)
│   │   └── 📄 prod.tfvars          # Parâmetros de PROD (URL do Workspace de produção)
│   ├── 📜 databricks.tf            # Recursos lógicos: Upload do código e criação do Job Ephemeral
│   ├── 📜 locals.tf                # Variáveis locais, tags e caminhos dinâmicos baseados no ambiente
│   ├── 📜 outputs.tf               # Exposição de IDs gerados (Job ID, caminhos) para logs de esteira
│   ├── 📜 providers.tf             # Configuração isolada do provedor Databricks via token dinâmico
│   └── 📜 variables.tf             # Declaração e tipagem estrita das variáveis aceitas pelos ambientes
├── 📄 .gitignore                   # Bloqueio de arquivos locais temporários do Terraform (.terraform, state)
├── 💜 azure-pipelines.yml          # Definição e orquestração do pipeline multiambiente do Azure DevOps
├── 📘 CARGA_DADOS.md               # Documentação técnica do projeto (Este arquivo)
└── 📄 requirements.txt             # Dependências de bibliotecas Python instaladas em tempo de execução
```

---

## ⚙️ 3. Componentes da Camada Terraform

* **`providers.tf`**: Configura o provedor do Databricks de forma desacoplada de estados de infraestrutura física. Ele não utiliza `terraform_remote_state`. Ele é alimentado via variáveis injetadas na execução da esteira.
* **`databricks.tf`**: Realiza o upload do notebook e dos arquivos da pasta `src/` para caminhos isolados e cria um **Job Cluster Ephemeral (`Standard_F4s_v2`)**, garantindo controle estrito de custos (Low-Cost) e execução assíncrona isolada.
* **`locals.tf`**: Monta dinamicamente strings complexas, como o nome do catálogo do Unity Catalog (`dbw_dbx_lowcost_${env}_7405611752750506`) e o caminho base de pastas, anexando o sufixo do ambiente atual.

---

## 🔄 4. Estratégia de Branches e Multiambiente

O projeto adota o isolamento completo de ambientes mapeado de forma nativa por Git branches e gerenciado internamente por **Terraform Workspaces**:

| Branch Git | Ambiente Terraform | Arquivo de Parâmetros | Sufixo do Job / Pasta no Workspace |
| :--- | :--- | :--- | :--- |
| `dev` | `DEV` | `terraform/envs/dev.tfvars` | `*_DEV` / `*_dev` |
| `main` | `PROD` | `terraform/envs/prod.tfvars` | `*_PROD` / `*_prod` |

### Fluxo de Execução do Pipeline (`azure-pipelines.yml`):
1. **Trigger**: Ocorre em qualquer *push* ou *merge* direcionado para as branches `dev` ou `main`.
2. **Setup**: Instala o runtime do Terraform no agente e recupera as credenciais de segurança do *Variable Group* corporativo da Azure.
3. **Workspace Isolation**: Executa um `terraform workspace select` correspondente ao ambiente. Caso não exista, cria-o em tempo de execução.
4. **Deploy**: Roda o `terraform apply` passando o arquivo de variáveis do ambiente específico, atualizando o código e as definições orquestradas na nuvem.
5. **Run Now**: Executa uma chamada à API do Databricks para disparar a execução imediata do Job recém-atualizado de maneira assíncrona.
