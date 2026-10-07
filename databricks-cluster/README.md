# 🏗️ Infraestrutura como Código: Azure Databricks com Unity Catalog & Monitoring (Low-Cost)

Este repositório contém a infraestrutura modularizada em Terraform para provisionar e gerenciar um ecossistema completo do **Azure Databricks**, integrado nativamente com a governança de dados do **Unity Catalog** e monitoramento centralizado no **Log Analytics Workspace**.

Seguindo os novos requisitos de arquitetura do cliente, **este repositório gerencia estritamente a infraestrutura imutável**. Os códigos-fonte das aplicações (scripts Python e arquivos `requirements.txt`) foram completamente apartados deste repositório e residem em projetos independentes no GitHub.

---

## 📁 Estrutura de Arquivos do Projeto

```text
meu-projeto-databricks/
├── config/
│   └── settings.yaml      # Configurações de ambiente (Flag liga/desliga computação)
├── providers.tf           # Declaração dos provedores oficiais AzureRM e Databricks
├── variables.tf           # Variáveis do Terraform (Parâmetros de Autoterminação)
├── locals.tf              # Tags globais para faturamento e mapeamento do YAML
├── main.tf                # Escopo estrutural básico (Resource Group pai)
├── networking.tf          # Configuração de rede isolada (VNet Injection e Subnets)
├── security.tf            # Firewall básico via Network Security Groups (NSG)
├── storage.tf             # Azure Storage (Data Lake Gen2) base para o Metastore do catálogo
├── databricks.tf          # Workspace (Standard), Metastore, Schemas e Job Orquestrado
├── monitoring.tf          # Log Analytics Workspace e regras de telemetria diagnóstica
└── outputs.tf             # Saída com IDs e URLs automatizadas de acesso
```

> 💡 **Nota de Arquitetura:** O antigo arquivo `jobs.tf` foi completamente descontinuado. Toda a governança e a receita do Job de auditoria agora residem de forma centralizada dentro de `databricks.tf` para otimizar as chamadas a repositórios externos.

---

## 🛠️ Detalhes da Infraestrutura e Componentes

### 1. Computação Otimizada e "Custo Zero" (`databricks.tf`)
O cluster de processamento opera sob o perfil **Single Node**, rodando sem nós trabalhadores adicionais para garantir que você pague apenas por uma única VM básica (`Standard_DS3_v2`) em ambiente de laboratório.
* **Segurança:** Definido obrigatoriamente como `data_security_mode = "USER_ISOLATION"` para ativar o isolamento de memória exigido pelas políticas de segurança do Unity Catalog.
* **Mecanismo de Desligamento:** Configurado com `autotermination_minutes = 10` para auto-desligamento por inatividade caso a máquina seja esquecida ligada.
* **Flag de Destruição Condicional:** Alterando a linha `enable_cluster: true` para `false` no arquivo `config/settings.yaml` e aplicando o Terraform, o cluster computacional é **destruído de forma definitiva**, zerando na hora as cobranças da Azure. Seus dados e estruturas lógicas continuarão salvos com segurança no Data Lake Gen2.

### 2. Governança de Dados (Unity Catalog & Schemas)
Toda a persistência física é mapeada para uma **Azure Storage Account** configurada como **Data Lake Storage Gen2** (`is_hns_enabled = true`) utilizando replicação local `LRS` (menor custo do catálogo Azure). O Terraform estrutura a topologia hierárquica baseada em três níveis (`catalogo.esquema.tabela`), isolando os contextos em dois Schemas:
* **`student`**: Destinado estritamente para dados e tabelas cadastrais de estudantes.
* **`course`**: Destinado para armazenar as estruturas e grades curriculares dos cursos.

### 3. Monitoramento e Observabilidade (`monitoring.tf`)
Integra o Workspace do Databricks com o **Azure Log Analytics Workspace** sob o modelo Pay-as-you-go, capturando em tempo real logs de auditoria do Unity Catalog, ciclos de vida do cluster e eventos do Apache Spark.

---

## 🔄 Orquestração Sequencial (Task-Level Git)

O Terraform configura o componente `databricks_job` para clonar os códigos diretamente do GitHub do cliente em tempo de execução, garantindo que o cluster execute sempre a versão mais recente da branch `main` de cada projeto de forma sequencial:

```text
┌──────────────────────────────┐          ┌──────────────────────────────┐
│  1_Verificar_Status_Carga    │          │   2_Consulta_e_Verificacao   │
│  (Repo: projeto-carga-dados) ├─────────►│ (Repo: projeto-consulta-dados)│
│  Requirements isolado        │          │   Requirements isolado       │
└──────────────────────────────┘          └──────────────────────────────┘
```

* **Isolamento de Dependências:** Cada tarefa (Task) instala de forma isolada no cluster as bibliotecas descritas no seu próprio arquivo `requirements.txt`, eliminando conflitos de versão entre os projetos de carga e consulta.
* **Garantia de Ordem:** A tarefa de *Consulta e Verificação* possui dependência mandatória (`depends_on`) da tarefa de *Carga*. Se o check de carga falhar, o fluxo é interrompido imediatamente para evitar a exposição de dados corrompidos.

---

## 🚀 Como Provisionar o Ambiente

### 1. Inicializando a Infraestrutura Básica
Abra o terminal na pasta deste repositório, faça o login na sua conta da Azure através do CLI e execute o fluxo padrão do Terraform:
```bash
az login
terraform init
terraform plan
terraform apply -auto-approve
```

O Terraform exibirá o ID do Job criado (`job_id`) e as URLs diretas de acesso ao Workspace no terminal através do arquivo `outputs.tf`.

### 2. Integração com as Pipelines Distintas (CI/CD)
As esteiras de automação do **Azure DevOps** foram configuradas de forma independente dentro de cada um dos repositórios de aplicação (`projeto-carga-dados` e `projeto-consulta-dados`).

* **Autenticação:** As pipelines utilizam um **Service Principal (App Registration)** e um grupo de variáveis centralizado (`databricks-secrets`) para obter tokens OAuth dinâmicos da Azure.
* **Disparo por Task:** Como os projetos Python são independentes e não compartilham a mesma esteira, cada arquivo `azure-pipelines.yml` chama a API do Databricks de forma isolada, passando o `job_id` gerado por esta infraestrutura e especificando o `TASK_KEY` exato (`1_Verificar_Status_Carga` ou `2_Consulta_e_Verificacao`) que deve ser disparado após os merges na `main`.
