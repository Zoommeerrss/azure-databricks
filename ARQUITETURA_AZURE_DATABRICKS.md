# 🏛️ Documentação de Arquitetura: Ecossistema Azure Databricks Decoupled

Este documento descreve a arquitetura técnica, as diretrizes de governança e a estratégia de implantação do ecossistema de dados baseado em **Azure Databricks** e **Unity Catalog**.

O projeto adota o padrão de **Design de Arquitetura em Duas Camadas (Two-Tier IaC)**, separando de forma estrita o ciclo de vida dos recursos físicos da nuvem (IaaS/PaaS) das configurações e regras lógicas de dados (Governança e Orquestração).

---

## 🎨 1. Visão Geral da Arquitetura

O ecossistema foi projetado sob os pilares de **segurança corporativa (Zero Trust), custo otimizado (Low-Cost) e isolamento completo de escopo**. Em vez de um repositório monolítico de infraestrutura, a engenharia foi dividida em repositórios independentes no GitHub, garantindo ciclos de vida isolados e pipelines de CI/CD autônomos.

```text
┌─────────────────────────────────────────────────────────────────────────┐
│ 1. CAMADA DE INFRAESTRUTURA BÁSICA                                      │
│ Repo Git: `azure-databricks-basic-infra`                                │
│ (Criação de Grupo de Recursos, VNet, Subnets Delegadas e Workspace)     │
└────────────────────────────────────┬────────────────────────────────────┘
                                     │ (Expõe outputs via tfstate)
                                     ▼
┌───────────────────────────────────────────────────────────────────────────────────┐
│ 2. CAMADA DE CONFIGURAÇÃO LÓGICA (100% AGNÓSTICA A NEGÓCIO E OFERTAS)             │
│ Repo Git: `azure-databricks-config`                                               │
│ (Governança base, Conexão dinâmica, Cluster Interativo, sem saber de Apps/Ofertas)│
└──────────────────┬──────────────────────────────────┬─────────────────────────────┘
                   │                                  │
                   ▼                                  ▼
┌──────────────────────────────────────┐ ┌──────────────────────────────────────┐ ┌──────────────────────────────────────┐
│ APP PRODUCER (DEMOCRATIZADA)         │ │ APP CONSUMER (ANALÍTICA)             │ │ APP ISOLADA (PRIVADA / INTERNA)      │
│ Repo: `projeto-carga-dados`          │ │ Repo: `projeto-consulta-dados`       │ │ Repo: `projeto-interno-N`            │
│ Dir: `/Shared/Production/<app>_<env>`│ │ Dir: `/Shared/Production/<app>_<env>`│ │ Dir: `/Apps/<app>_<env>` (Restrito)  │
│ Computação: Job Cluster Efêmero      │ │ Computação: Job Cluster Efêmero      │ │ Computação: Job Cluster Efêmero      │
│ Catálogos/Schemas: Criados na App    │ │ Catálogos/Schemas: Consome via Grant │ │ Catálogos/Schemas: Privados na App   │
│ Grants: `grants.tf` (Ofertas N:N)    │ │ Grants: Sem exposição externa        │ │ Grants: `authorized_offer_groups=[]` │
└──────────────────────────────────────┘ └──────────────────────────────────────┘ └──────────────────────────────────────┘
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

### 🧬 Governança Base via Unity Catalog (`databricks.tf`)
* **Catálogo Gerenciado:** Consumido via `data_source` para evitar conflitos de privilégios ou erros de *Metastore storage root*.
* **Agnosticismo Total e Imutabilidade:** Esta camada **nunca** é alterada para atender demandas de aplicações ou grupos de negócio. Ela desconhece catálogos, schemas, jobs, usuários, ofertas de negócio ou regras de acesso das aplicações.

### 💻 Estratégia de Computação e Otimização de Custos (Low-Cost)
O ecossistema de computação adota a VM **`Standard_F4s_v2`** (Computação Otimizada de 4 núcleos) para mitigar de forma definitiva os limites de cotas da Azure comuns em assinaturas de laboratório/estudantes. O ambiente divide os perfis de processamento em duas categorias:

1. **Cluster Interativo (Uso Ad-hoc dos Engenheiros):** Controlado dinamicamente por uma flag centralizada no arquivo local `config/settings.yaml`. Caso a flag `enable_cluster` seja alterada para `false`, o Terraform destrói a VM do cluster interativo para zerar as cobranças por ociosidade, mantendo os dados intactos no Data Lake. Possui desligamento automático configurado para 10 minutos de inatividade.
2. **Computação de Tarefa (Job Cluster Ephemeral):** Os Jobs de produção não utilizam o cluster interativo. Cada tarefa levanta sua própria VM isolada `Standard_F4s_v2` no momento da execução e a destrói imediatamente após o término do processamento, garantindo isolamento total e cobrança restrita aos minutos de execução.

### 🌐 Catálogos Compartilhados entre Várias Apps
A responsabilidade de criar, manter e democratizar catálogos pertence exclusivamente à **App Producer** dona daquele domínio de negócio (ex: `projeto-carga-dados`), e **nunca** ao `azure-databricks-config`. A própria **App Producer** organiza seus schemas no arquivo `databricks.tf` (sem definir `owner = "account users"`, garantindo bloqueio por padrão) e formaliza o contrato de compartilhamento em um arquivo dedicado **`grants.tf`**, concedendo permissões apenas para os grupos de ofertas de negócio autorizados.

---

## 🔐 4. Jornada de Permissionamento e Governança por Ofertas de Negócio (RBAC N:N)

Para evitar qualquer acoplamento entre a gestão de pessoas e as esteiras de infraestrutura, o controle de acesso segue o modelo **Zero Trust (*Deny by Default*)** baseado estritamente em **Grupos por Ofertas de Negócio (`grp-oferta-*`)**, suportando relacionamento **N:N** (um usuário em N ofertas e uma oferta com N usuários).

**Regra de Ouro:** Nenhum usuário comum (exceto o *Administrator Total*) consegue acessar o Workspace, visualizar catálogos ou acompanhar jobs sem estar vinculado a pelo menos um Grupo de Oferta.

### 🔄 Fluxo Operacional de Ponta a Ponta (PO vs. Time de Dados)

```text
[1. Product Owner / IAM]             [2. Time de Dados (App Producer)]        [3. Product Owner / IAM (Dia a Dia)]
Convida Guest (Entra ID) +           Informa `grp-oferta-*` na var e          Adiciona / Remove N usuários
Cria Grupo da Oferta +               roda deploy da App (`grants.tf`)         nos grupos das ofertas (N:N)
Vincula Grupo ao Workspace           (Libera Dados + CAN_VIEW nos Jobs)       (Acesso imediato, zero deploy)
```

#### Etapa 1: Gestão de Identidade e Entrada (Responsabilidade do Product Owner / IAM)
Operada diretamente na interface administrativa (sem código e sem tocar na infraestrutura):
1. **Convite no Microsoft Entra ID:** Para usuários externos ao domínio/tenant, o PO envia o convite B2B como **Guest (Convidado)** no Portal Azure (*Microsoft Entra ID > Usuários > Convidar usuário externo*). O usuário deve aceitar o convite antes do primeiro acesso.
2. **Nascimento da Oferta como Grupo de Acesso:** Na **Databricks Account Console** (`accounts.azuredatabricks.net > User management > Groups`), o PO cria o grupo seguindo o padrão da oferta (ex: `grp-oferta-students`, `grp-oferta-credito`).
3. **Vínculo de Usuários (Relacionamento N:N):** O PO adiciona os usuários dentro dos respectivos grupos de ofertas. Um mesmo usuário pode pertencer a múltiplos grupos simultaneamente.
4. **Liberação da Porta do Workspace:** Na *Account Console > Workspaces > [Workspace] > Permissions* (ou via *Workspace Settings > Identity and access > Groups*), o PO vincula **exclusivamente o Grupo da Oferta** com a role **User** (garantindo *Workspace access* e bloqueando criação de clusters/pools).
   * *Resultado:* O usuário consegue acessar a URL direta do Workspace (`https://<workspace-id>.azuredatabricks.net`), mas vê **zero dados** e **zero jobs** até que uma App Producer conceda permissão ao grupo.
5. **Handoff Pré-Deploy:** O PO informa o nome exato do grupo criado (`grp-oferta-*`) ao time responsável pela **App Producer** antes do deploy da aplicação.

#### Etapa 2: Contrato de Dados e Execuções na App Producer (`grants.tf`)
No repositório da aplicação produtora, o acesso é formalizado de forma declarativa e idempotente:
1. **Validação Dinâmica de Grupos:** O Terraform valida a existência de todos os grupos informados na lista `var.authorized_offer_groups` via `data "databricks_group"`.
2. **Privilégios em Cascata no Unity Catalog:** O recurso `databricks_grants` concede `USE_CATALOG` no catálogo da aplicação e `USE_SCHEMA` + `SELECT` exclusivamente nos schemas democratizados (mantendo o catálogo fechado para usuários sem grupo ao omitir `owner = "account users"`).
3. **Visibilidade de Execuções para N Jobs (`CAN_VIEW`):** Todos os jobs da aplicação são mapeados em `local.app_jobs` (no `locals.tf`) e recebem permissão **`CAN_VIEW`** via `databricks_permissions` com `for_each`. Isso permite que os membros da oferta acompanhem quando os pipelines rodam e consultem logs na aba *Workflows*, mantendo o botão **Run now** bloqueado.

#### Etapa 3: Manutenção Contínua N:N (Autonomia Total do PO)
* **Inclusão/Remoção de Usuários:** Após o deploy da App Producer, o PO adiciona ou remove usuários nos grupos de oferta diretamente na Account Console. O efeito nos dados e na visibilidade dos jobs é **imediato**, sem necessidade de executar esteiras Terraform.

---

## 🛠️ 5. Estrutura Interna das Aplicações e Padrões de Isolamento

### 📦 Tipos de Aplicações Suportadas pelo Mesmo Template IaC

| Atributo | App Producer (Democratizada) | App Consumer (Analítica) | App Isolada (Privada / Interna) |
| :--- | :--- | :--- | :--- |
| **Diretório no Workspace** | `/Shared/Production/<app>_<env>` | `/Shared/Production/<app>_<env>` | `/Apps/<app>_<env>` (acesso restrito) |
| **Catálogo e Schemas** | Criados na App (sem `owner` aberto) | Não cria (consome via grants) | Criados na App (100% privados) |
| **`authorized_offer_groups`** | Lista de grupos autorizados (`["grp-..."]`) | Lista de grupos da App (se houver jobs) | `[]` (Lista vazia — zero exposição externa) |
| **Visibilidade dos Jobs** | `CAN_VIEW` para grupos autorizados | `CAN_VIEW` para grupos autorizados | Invisível para usuários comuns |
| **Integração com Outros Dados** | Publica dados para Consumers | Lê catálogos existentes (`SELECT`) | Pode ler (`SELECT`) ou gravar (`MODIFY`) em catálogos existentes via identidade de execução (`run_as`) |

### ⚙️ Boas Práticas de Engenharia e CI/CD
* **Separação de Responsabilidades IaC:** `databricks.tf` gerencia recursos de dados (`Storage Credential`, `External Location`, `Catalog`, `Schemas`, `Volumes` e propagação RBAC via `time_sleep`), `jobs.tf` gerencia os workflows em *Job Clusters Efêmeros* e `grants.tf` isola os contratos de permissão.
* **Isolamento de Estado (`tfstate`):** Cada repositório possui sua própria `key` exclusiva no backend remoto da Azure (ex: `carga-dados.tfstate`), evitando qualquer colisão entre projetos ou ambientes.
* **Notebooks e Dependências:** Notebooks Jupyter (`.ipynb`) seguem o prefixo `nb_` com dependências isoladas no `requirements.txt` da raiz de cada projeto. Para testes ad-hoc em notebooks compartilhados, os usuários devem clonar o arquivo para sua pasta pessoal (`Workspace > Users > <email>`), evitando sobrescrever outputs na pasta compartilhada.
* **Orquestração Sequencial via CI/CD:** A ordem de execução entre repositórios independentes é controlada pela esteira externa (GitHub Actions / Azure DevOps), disparando consumidores apenas após o término com sucesso (`exit 0`) do produtor.
