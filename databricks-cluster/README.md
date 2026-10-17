# 🏗️ Infraestrutura como Código: Azure Databricks com Unity Catalog & Monitoring (Low-Cost)

Este repositório contém a infraestrutura modularizada em Terraform para provisionar e gerenciar um ecossistema completo do **Azure Databricks**, integrado nativamente com a governança de dados do **Unity Catalog** e monitoramento centralizado no **Log Analytics Workspace**.

Seguindo os novos requisitos de arquitetura, **este repositório gerencia estritamente a infraestrutura de dados e orquestração**. Os códigos-fonte das aplicações (scripts Python e arquivos `requirements.txt`) foram centralizados e residem em um repositório Git independente, consumido dinamicamente através do Databricks Workflows.

---

## 📁 Estrutura de Arquivos do Projeto

```text
databricks-cluster/
├── config/
│   └── settings.yaml          # Configurações internas de comportamento do cluster via YAML
├── envs/                      # Nova pasta centralizando os parâmetros por ambiente
│   ├── dev.tfvars             # Variáveis específicas para o ambiente de Desenvolvimento
│   └── prod.tfvars            # Variáveis específicas para o ambiente de Produção
├── databricks.tf              # Cria o Workspace Databricks, Metastore, Catálogos/Schemas do Unity Catalog e o Cluster Spark
├── jobs.tf                    # Orquestra os fluxos de trabalho (Workflows/Jobs) integrados com os scripts Python do GitHub
├── locals.tf                  # Centraliza variáveis locais dinâmicas, tags globais e processamento do arquivo YAML
├── main.tf                    # Define o escopo inicial do projeto e cria o Grupo de Recursos (Resource Group) na Azure
├── monitoring.tf              # Configura o Log Analytics e as definições de diagnóstico para telemetria e auditoria do Databricks
├── networking.tf              # Desenha a arquitetura de rede (VNet e sub-redes Pública/Privada) com injeção para o Databricks
├── outputs.tf                 # Especifica os dados que serão exibidos no terminal após o deploy (URL do Workspace e ID do Job)
├── providers.tf               # Declara as versões exigidas dos providers (Azure e Databricks) e define os métodos de autenticação
├── security.tf                # Gerencia os Grupos de Segurança de Rede (NSG) e suas respectivas associações com as sub-redes
├── storage.tf                 # Cria a conta de armazenamento (ADLS Gen2) e o container raiz utilizado pelo Unity Catalog
├── variables.tf               # Mapeia todas as variáveis de entrada do projeto (região, ambiente, branches do Git, etc.)
├── .gitattributes             # Define atributos de caminhos específicos e configurações globais para o repositório Git
├── .gitignore                 # Lista arquivos e pastas locais que devem ser ignorados pelo Git (como arquivos de estado do Terraform)
├── LICENSE                    # Contém os termos de licença de uso e distribuição do código do projeto
└── README.md                  # Documentação principal com instruções de arquitetura, pré-requisitos e como implantar o projeto
```

> 💡 **Nota de Arquitetura:** Este projeto adota uma abordagem estritamente modular. A infraestrutura física de dados reside em `databricks.tf`, enquanto as regras lógicas e a malha de orquestração sequencial ficam isoladas de forma limpa dentro de `jobs.tf`.

---

## 🛠️ Detalhes da Infraestrutura e Componentes

### 1. Computação Otimizada e Controle de Custos (`databricks.tf`)
O cluster de processamento opera sob o perfil **Single Node**, rodando sem nós trabalhadores adicionais para garantir que você pague apenas por uma única VM básica (`Standard_DS3_v2`) em ambiente de laboratório.
* **Segurança:** Definido obrigatoriamente como `data_security_mode = "USER_ISOLATION"` para ativar o isolamento de memória exigido pelas políticas de segurança do Unity Catalog.
* **Mecanismo de Desligamento:** Configurado com `autotermination_minutes = 10` para auto-desligamento por inatividade caso a máquina seja esquecida ligada.
* **Flag de Destruição Condicional:** O parâmetro `enable_cluster` é resolvido de maneira dinâmica através do mapeamento do arquivo local `config/settings.yaml`. Caso a flag seja alterada para `false`, o cluster computacional é removido pelo Terraform para zerar cobranças, mantendo os dados persistidos intactos no Data Lake.

### 2. Governança de Dados (Unity Catalog Dinâmico)
Toda a persistência física é mapeada para uma **Azure Storage Account** configurada como **Data Lake Storage Gen2** (`is_hns_enabled = true`) utilizando replicação local `LRS`. O Terraform estrutura a topologia baseada em três níveis (`catalogo.esquema.tabela`), isolando os contextos dinamicamente por ambiente (`dev_catalog` ou `prod_catalog`) em dois Schemas:
* **`student`**: Destinado estritamente para dados e tabelas cadastrais de estudantes.
* **`course`**: Destinado para armazenar as estruturas e grades curriculares dos cursos.

### 3. Monitoramento e Observabilidade (`monitoring.tf`)
Integra o Workspace do Databricks com o **Azure Log Analytics Workspace**, utilizando o grupo consolidado `allLogs` para capturar e centralizar de maneira moderna os logs de telemetria do Unity Catalog, ciclos de vida dos clusters e orquestrações do Spark.

---

## 🔄 Orquestração Sequencial (Task-Level Git com Branching Dinâmico)

O Terraform configura o componente `databricks_job` em `jobs.tf` de maneira global utilizando um único bloco `git_source`. O Databricks clona o repositório unificado aplicando a branch enviada de forma dinâmica pelas variáveis de ambiente (`var.git_branch`), mapeando a execução sequencial:

```text
┌──────────────────────────────┐          ┌──────────────────────────────┐
│  1_Verificar_Status_Carga    │          │    2_Consulta_Dashboard      │
│  (Script: check_carga.py)    ├─────────►│ (Script: dashboard_consulta.py)
│  Source: GIT (Requirements)  │          │  Source: GIT (Requirements)  │
└──────────────────────────────┘          └──────────────────────────────┘
```

* **Isolamento de Dependências:** Cada tarefa (Task) instala em tempo de execução as dependências declaradas no arquivo `requirements.txt` presente na raiz do repositório clonado.
* **Garantia de Ordem:** A tarefa `2_Consulta_Dashboard` possui dependência mandatória (`depends_on`) da tarefa `Carga_Dados_Estudantes`. Se o check de carga falhar, o fluxo é interrompido imediatamente para evitar a exposição de dados corrompidos.

---

## 🚀 Como Provisionar o Ambiente

### 1. Inicializando a Infraestrutura Básica
Abra o terminal na pasta deste repositório, faça o login na sua conta da Azure através do CLI e execute o fluxo passando o arquivo de variáveis do ambiente desejado (`dev` ou `prod`):

#### 🛠️ Implantando em Desenvolvimento (Dev):
```bash
az login
terraform init
terraform plan -var-file="envs/dev.tfvars"
terraform apply -var-file="envs/dev.tfvars"
```

#### 🚀 Implantando em Produção (Prod):
```bash
az login
terraform init
terraform plan -var-file="envs/prod.tfvars"
terraform apply -var-file="envs/prod.tfvars"
```

O Terraform exibirá a URL direta de acesso ao Workspace e o ID do Workflow gerado no terminal através do arquivo `outputs.tf`.

### 2. Mecanismo de Autenticação e Provedores (`providers.tf`)
O provedor do Databricks está parametrizado com `auth_type = "azure-cli"`. Isso garante que o Terraform herde os tokens de acesso gerados pelo comando `az login` executado localmente ou pelo Service Principal dentro de esteiras de CI/CD (GitHub Actions / Azure DevOps), eliminando a necessidade de gerenciamento manual de tokens PAT (Personal Access Tokens).
