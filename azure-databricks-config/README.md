# ⚙️ Governança e Orquestração como Código: Azure Databricks Config (Low-Cost)

Este repositório contém a camada lógica e de governança em Terraform para configurar o ecossistema interno do **Azure Databricks**. Ele atua de forma totalmente isolada da infraestrutura física da nuvem [1.5].

Seguindo o design de arquitetura desacoplada em duas camadas, **este repositório gerencia estritamente as regras de dados (Unity Catalog), clusters interativos e fluxos de trabalho (Workflows/Jobs)** [1.5]. Ele herda dinamicamente a URL de um Workspace Databricks pré-existente (criado pelo repositório base `azure-databricks-basic-infra`) e consome os notebooks reais de produção (`.ipynb`) diretamente de seus respectivos repositórios independentes no GitHub [1.5].

---

## 📁 Estrutura de Arquivos do Projeto

```text
azure-databricks-config/
├── config/
│   └── settings.yaml          # Flag YAML centralizada para Ligar/Desligar o cluster interativo
├── databricks.tf              # Configura as estruturas do Unity Catalog (Catálogo, Schemas) e Cluster Spark
├── jobs.tf                    # Orquestra os recursos de Pipelines clonando múltiplos repositórios do Git
├── locals.tf                  # Processa a leitura do YAML de custos e isola as tags locais do ecossistema
├── outputs.tf                 # Exibe os IDs dos Jobs de Carga e Consulta gerados após o deploy
├── providers.tf               # Declara a autenticação focada exclusivamente no provider do Databricks
├── variables.tf               # Mapeia as variáveis lógicas de entrada (URL do Workspace, Ambiente, Branches)
├── deploy_config.sh           # Script automatizado para implantação lógica isolada
└── destroy_config.sh          # Script automatizado para destruição lógica isolada
```

> 💡 **Nota de Arquitetura:** Este projeto adota uma abordagem estritamente focada em dados e orquestração. Ele nunca cria ou altera recursos de rede ou servidores na Azure, mitigando riscos de retrabalho ou indisponibilidade da fundação da nuvem.

---

## 🛠️ Detalhes da Governança e Componentes

### 1. Computação Otimizada e Controle de Custos (`databricks.tf` & `config/settings.yaml`)
* **Cluster Interativo Ad-hoc:** Opera sob o perfil **Single Node** utilizando uma VM estável de computação otimizada (`Standard_D4s_v5`), ideal para desenvolvimento manual de engenheiros. Ele desliga automaticamente após 10 minutos de inatividade (`autotermination_minutes = 10`).
* **Flag de Custo Zero:** Se a flag `enable_cluster` for alterada para `false` no arquivo local `config/settings.yaml`, o Terraform remove o cluster interativo imediatamente para zerar as cobranças da Azure, mantendo as definições lógicas e os Jobs intactos.
* **Segurança:** Configurado obrigatoriamente como `USER_ISOLATION` para garantir o isolamento de memória exigido pela governança.

### 2. Governança de Dados (Unity Catalog Dinâmico)
O Terraform estrutura a topologia baseada em três níveis (`catalogo.esquema.tabela`), isolando os contextos dinamicamente por ambiente (`dev_catalog` ou `main_catalog`) através do modo de isolamento nativo de contas (`isolation_mode = "ISOLATED"`), estruturando dois Schemas específicos:
* **`student`**: Destinado estritamente para dados e tabelas cadastrais de estudantes.
* **`course`**: Destinado para armazenar as estruturas e grades curriculares dos cursos.

---

## 🔄 Orquestração de Pipelines Independentes (Multi-Repositório)

Para respeitar o ciclo de vida isolado de cada aplicação e garantir que uma falha não corrompa as camadas analíticas, a malha de orquestração no `jobs.tf` está dividida em **dois recursos de workflows separados**, cada um apontando para seu respectivo repositório no GitHub e utilizando notebooks nativos Jupyter (`.ipynb`):

### 📥 Pipeline 1: Processamento de Carga (`nb_carga_dados.ipynb`)
* **Origem:** Clona estritamente o repositório `projeto-carga-dados`.
* **Função:** Ingestão e escrita pesada de dados nos schemas do Unity Catalog.
* **Dependências:** Instala pacotes isolados declarados em seu próprio arquivo `requirements.txt` via biblioteca nativa.

### 📊 Pipeline 2: Processamento de Consulta (`nb_consulta_dashboard.ipynb`)
* **Origem:** Clona estritamente o repositório `projeto-consulta-dados`.
* **Função:** Leitura, cruzamento de dados, agregações e geração do Dashboard de KPIs para o negócio.

---

## 🚀 Como Provisionar o Ambiente

O ciclo de vida deste repositório é totalmente independente. Você pode atualizar lógicas de Jobs e Schemas quantas vezes quiser sem risco de impactar a rede do Workspace da Azure.

### 1. Configurando os Componentes Lógicos
Abra o terminal na pasta deste repositório e execute o script de implantação dedicada passando o ambiente desejado (`dev` ou `main`):

#### 🛠️ Executando em Desenvolvimento (Dev):
```bash
chmod +x deploy_config.sh
./deploy_config.sh dev
```

#### 🚀 Executando em Produção (Prod):
```bash
chmod +x deploy_config.sh
./deploy_config.sh main
```

*Nota: Se a URL do Databricks Workspace não for encontrada na sessão do terminal, o script solicitará interativamente que você cole a URL gerada pelo repositório de infraestrutura básica.*

---

### 💥 Como Destruir as Configurações

Caso precise remover a camada lógica do Databricks (remover Jobs, tabelas, schemas e catálogos), execute o script de destruição dedicado:

```bash
chmod +x destroy_config.sh
./destroy_config.sh dev
```

*⚠️ **Regra de Ouro:** Este comando deve obrigatoriamente finalizar a remoção completa antes de você disparar qualquer destruição física no repositório `azure-databricks-basic-infra`.*

---

### 🔐 Mecanismo de Autenticação (`providers.tf`)
O provedor do Databricks está parametrizado com `auth_type = "azure-cli"`. Isso garante que o Terraform herde os tokens de acesso de curta duração gerados pelo comando `az login` local ou pelo Service Principal (App Registration) autenticado na esteira de CI/CD (Azure DevOps), eliminando por completo a necessidade de gerenciamento de tokens PAT manuais ou expiráveis.


# Troubleshooting

## The plugin encountered an error, and failed to respond to the plugin6.(*GRPCProvider).ValidateProviderConfig call

Esse erro ocorre quando o plugin do TerraForm parou abrutmamente sem conseguir avançar no processamento.

```bash
Plan: 12 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + workspace_url = (known after apply)
╷
│ Error: Plugin did not respond
│ 
│ The plugin encountered an error, and failed to respond to the plugin6.(*GRPCProvider).ValidateProviderConfig call. The plugin logs may contain more details.
╵```

Para tentar executar novamente, execute o comando abaixo para remover o arquivo gerado pelo TerraForm:

```bash
# Remova os plugins baixados localmente e o arquivo de trava
rm -rf .terraform .terraform.lock.hcl

# Force o Terraform a baixar e inicializar tudo do zero
terraform init
```

## Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take exactly these actions if you run "terraform apply" now.

Essa mensagem não é um erro, mas sim um aviso de segurança e boas práticas do Terraform. Ela aparece sempre que você executa um terraform plan de forma isolada, sem salvar o resultado em um arquivo.

O Terraform está apenas alertando que, se você rodar o terraform apply agora, ele precisará recalcular todo o plano do zero. Se alguém tiver alterado algo na sua infraestrutura na nuvem nesse meio tempo, as ações reais do apply podem ser diferentes das que você acabou de ver na tela.


1. Gere e salve o plano em um arquivo:

```bash
terraform plan -out=install_plan.tfplan
```

2. Aplique exatamente esse plano salvo

```bash
terraform apply "install_plan.tfplan"
```