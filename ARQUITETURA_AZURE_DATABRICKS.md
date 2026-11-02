# 🏛️ Documentação de Arquitetura: Ecossistema Azure Databricks Decoupled

Este documento descreve a arquitetura técnica, as diretrizes de governança e a estratégia de implantação do ecossistema de dados baseado em **Azure Databricks** e **Unity Catalog**. 

O projeto adota o padrão de **Design de Arquitetura em Duas Camadas (Two-Tier IaC)**, separando de forma estrita o ciclo de vida dos recursos físicos da nuvem (IaaS/PaaS) das configurações e regras lógicas de dados (Governança e Orquestração).

---

## 🎨 1. Visão Geral da Arquitetura

O ecossistema foi projetado sob os pilares de **segurança corporativa, custo otimizado (Low-Cost) e isolamento completo de escopo**. Em vez de um repositório monolítico de infraestrutura, a engenharia foi dividida em quatro repositórios independentes no GitHub, garantindo ciclos de vida isolados e pipelines de CI/CD autônomos.

```text
┌─────────────────────────────────────────────────────────────────────────┐
│                    1. CAMADA DE INFRAESTRUTURA BÁSICA                   │
│               Repo Git: `azure-databricks-basic-infra`                  │
│  (Criação de Grupo de Recursos, VNet, Subnets Delegadas e Workspace)    │
└────────────────────────────────────┬────────────────────────────────────┘
                                     │ (Expõe outputs via tfstate)
                                     ▼
┌───────────────────────────────────────────────────────────────────────────────────┐
│                    2. CAMADA DE CONFIGURAÇÃO LÓGICA                               │
│                  Repo Git: `azure-databricks-config`                              │
│  (Governança, Conexão dinâmica, Clusters, sem saber de Jobs, Schemas e Catalogos) │
└──────────────────┬──────────────────────────────────┬─────────────────────────────┘
                   │
                   │ (Apps podem ser publicadas no Cluster)
                   ▼

┌──────────────────────────────────────┐  ┌──────────────────────────────────────┐  ┌──────────────────────────────────────┐
│       APLICAÇÃO DE ETL/CARGA         │  │        APLICAÇÃO ANALÍTICA           │  │        APLICAÇÃO N                   │
│      Repo: `projeto-carga-dados`     │  │    Repo: `projeto-consulta-dados`    │  │    Repo: `projeto-N`                 │
│    Notebook: `nb_carga_dados.ipynb`  ├─►│  Notebook: `nb_consulta_dashboard`   ├─►│  Notebook: `nb_N`                    │
│    Computação: Job Cluster Isolado   │  │  Computação: Job Cluster Isolado     │  │  Computação: Job Cluster Isolado     │
│    Catalogos: Dentro da app Isolados │  │  Catalogos: Dentro da app Isolados   │  │  Catalogos: Dentro da app Isolados   │
│    Schemas: Dentro da app Isolados   │  │  Schemas: Dentro da app Isolados     │  │  Schemas: Dentro da app Isolados     │
└──────────────────────────────────────┘  └──────────────────────────────────────┘  └──────────────────────────────────────┘
```

---

## 🌐 2. Camada de Infraestrutura Física (Azure)

Gerenciada exclusivamente pelo repositório `azure-databricks-basic-infra`, esta camada implanta a fundação de nuvem ancorada de forma fixa na região **`eastus` (Leste dos EUA)**, aproveitando o estoque massivo de computação e os custos reduzidos da região.

### 🛡️ Rede, Conectividade e Segurança (`networking.tf` & `security.tf`)
* **VNet Injection:** O Workspace do Databricks é injetado dentro de uma Rede Virtual própria (`10.0.0.0/16`), isolando o tráfego de dados da internet pública.
* **Sub-redes Delegadas:** O tráfego é dividido em duas sub-redes com blocos CIDR `/22` (`10.0.4.0/22` pública e `10.0.8.0/22` privada), delegadas nativamente para o serviço `Microsoft.Databricks/workspaces`.
* **Proteção Avançada:** Os nós de processamento operam com IP público totalmente desativado (`no_public_ip = true`). A segurança interna e o roteamento de borda são centralizados no `security.tf` por meio de Grupos de Segurança de Rede (NSG), blindados com regras de ciclo de vida (`lifecycle { create_before_destroy = true }`) para evitar concorrência ou falhas de estado no ambiente local/WSL.

### 📥 Camada de Persistência Base (`storage.tf` & `monitoring.tf`)
* **Data Lake Storage Gen2:** Provisionamento de uma Azure Storage Account com *Hierarchical Namespace* ativado (`is_hns_enabled = true`) e replicação local `LRS` para maximizar a economia.
* **Observabilidade Centralizada:** Vinculação nativa do Workspace a um **Log Analytics Workspace** por meio do grupo agregador `allLogs`, capturando telemetrias críticas de segurança do Unity Catalog e ciclos de vida de clusters.

---

## ⚙️ 3. Camada de Configuração Lógica (Databricks)

Gerenciada pelo repositório `azure-databricks-config`, esta camada não consome recursos diretos da Azure. Ela utiliza o mecanismo **`terraform_remote_state`** para ler a memória do projeto físico de forma automática e transparente, conectando-se ao endpoint gerado sem qualquer intervenção humana ou parâmetros manuais.

### 🧬 Governança via Unity Catalog (`databricks.tf`)
A governança de dados opera de forma nativa e integrada ao ecossistema gerenciado padrão do Workspace, mapeando o catálogo de desenvolvimento real instalado na nuvem:
* **Catálogo Gerenciado:** Consumido via `data_source` para evitar conflitos de privilégios ou erros de *Metastore storage root*.

### 💻 Estratégia de Computação e Otimização de Custos (Low-Cost)
O ecossistema de computação adota a VM **`Standard_F4s_v2`** (Computação Otimizada de 4 núcleos) para mitigar de forma definitiva os limites de cotas da Azure comuns em assinaturas de laboratório/estudantes. O ambiente divide os perfis de processamento em duas categorias:

1. **Cluster Interativo (Uso Ad-hoc dos Engenheiros):** Controlado dinamicamente por uma flag centralizada no arquivo local `config/settings.yaml`. Caso a flag `enable_cluster` seja alterada para `false`, o Terraform destrói a VM do cluster interativo para zerar as cobranças por ociosidade, mantendo os dados intactos no Data Lake. Possui desligamento automático configurado para 10 minutos de inatividade.
2. **Computação de Tarefa (Job Cluster Ephemeral):** Os Jobs de produção não utilizam o cluster interativo. Cada tarefa levanta sua própria VM isolada `Standard_F4s_v2` no momento da execução e a destrói imediatamente após o término do processamento, garantindo isolamento total e cobrança restrita aos minutos de execução.

### Catalogos Compartilhados entre Várias Apps de Forma Global

Suponha que o Cliente consumidor do Cluster seja de área financeira onde as informações sobre Dados Básicos de Clientes, como Nome Social, Endereço, Dados de Contas.

Nesse caso , Catálogos com Dados do Cliente poderão ser incluidos na camada do azure-databricks-config para facilitando para que todas as Apps do Cliente possam já nascer com essa conectividade demotratizada para realizar seus trabalhos e atender regras de negócio baseadas nos Dados Básicos do Cliente.

Se os Catálogos consumidos por uma App forem exclusivos, essa responsabilidade deixa de ser do azure-databricks-config, que não deve conhecer ABSOLUTAMENTE NADA de uma App que possua esse nível de exclusividade.

---

## 🔄 4. Orquestração e Pipelines Independentes

Cada projeto é totalmente responsável pelos seus jobs, catalogos, schemas, permitindo que o usuário os crie como prefetir e caso nao queira mais o projeto, pode simplesmente destruir via deploy sem causar nenhum efeito ao azure-databricks-basic-infra ou ao azure-databricks-config.

* **Schemas Estruturados:** O Terraform cria e gerencia de forma atômica dois Schemas isolados dentro do contêiner corporativo, cada um dentro de sua própria estrutura de pastas.

A malha de automação sequencial corporativa está dividida em **dois recursos independentes de Workflows (`databricks_job`)** dentro do arquivo `jobs.tf`. Essa decisão contorna as limitações de bloco único do Terraform e protege o ecossistema de dados:

```text
┌──────────────────────────────────────┐      ┌──────────────────────────────────────┐      ┌──────────────────────────────────────┐       
│        JOB 1: PIPELINE DE CARGA      │      │      JOB 2: PIPELINE DE CONSULTA     │      │      JOB N: PIPELINE DE FUTURA       │       
│  Repo: `projeto-carga-dados`         │      │  Repo: `projeto-consulta-dados`      │      │  Repo: `projeto-N`                   │       
│  Notebook: `nb_carga_dados.ipynb`    ├─────►│  Notebook: `nb_consulta_dashboard`   │─────►│  Notebook: `nb_N`                    │       
│  Computação: Job Cluster Isolado     │      │  Computação: Job Cluster Isolado     │      │  Computação: Job Cluster Isolado     │       
│  Catalogos: Dentro da app Isolados   │      │  Catalogos: Dentro da app Isolados   │      │  Catalogos: Dentro da app Isolados   │       
│  Schemas: Dentro da app Isolados     │      │  Schemas: Dentro da app Isolados     │      │  Schemas: Dentro da app Isolados     │       
└──────────────────────────────────────┘      └──────────────────────────────────────┘      └──────────────────────────────────────┘
```

* **Versionamento Nativo de Células:** As tarefas apontam para notebooks Jupyter reais (`.ipynb`) salvos no padrão de prefixo `nb_`, garantindo a correta renderização de outputs visuais e históricos de execução.
* **Isolamento de Bibliotecas:** Cada pipeline gerencia suas próprias dependências de negócio por meio do arquivo `requirements.txt` presente na raiz de seu respectivo repositório, instalado em tempo de execução via biblioteca isolada de tarefa.
* **Orquestração Segura via CI/CD:** A ordem sequencial é gerenciada pela esteira de CI/CD externa (Azure DevOps Pipelines). O Job de Consulta só recebe o gatilho de execução caso o Job de Carga e suas validações estatísticas de integridade terminem com sucesso completo (`exit 0`)

**Observação:** Como citado acima referente a possibilidade de um Catálogo Democratizado, somente nesse contexto que uma App pode e deve ter acesso a esse Catálogo e seus Schemas internos. **Não é permitida nenhuma outra exceção**.
