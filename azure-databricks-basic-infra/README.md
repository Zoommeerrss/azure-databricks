# 🏗️ Infraestrutura como Código: Azure Databricks Basic Infra (Low-Cost)

Este repositório contém a infraestrutura modularizada em Terraform para provisionar e gerenciar a fundação física do ecossistema do **Azure Databricks** na nuvem da Microsoft. 

Seguindo o design de arquitetura desacoplada em duas camadas, **este repositório gerencia estritamente os recursos físicos da Azure (rede, segurança, telemetria e o workspace vazio)**. Toda a governança lógica de dados (Unity Catalog), clusters e orquestração de pipelines foram isolados e residem em um repositório complementar (`azure-databricks-config`), eliminando riscos de sobreposição e exclusão acidental de redes estáveis.

---

## 📁 Estrutura de Arquivos do Projeto

```text
azure-databricks-basic-infra/
├── envs/
│   ├── dev.tfvars        # Variáveis específicas de infraestrutura para Desenvolvimento
│   └── prod.tfvars       # Variáveis específicas de infraestrutura para Produção
├── databricks.tf        # Provisiona exclusivamente o Workspace físico do Databricks na Azure
├── main.tf              # Define o escopo inicial e cria o Grupo de Recursos (Resource Group) base
├── monitoring.tf        # Configura o Log Analytics Workspace e logs de telemetria diagnóstica
├── networking.tf        # Desenha a arquitetura de rede (VNet e sub-redes Pública/Privada)
├── outputs.tf           # Exporta a URL do Workspace gerado para consumo do projeto lógico
├── providers.tf         # Declara as versões e define a autenticação focada no provider azurerm
├── security.tf          # Gerencia os Grupos de Segurança de Rede (NSG) e suas associações
├── storage.tf           # Cria a conta de armazenamento (ADLS Gen2) usada de raiz pelo Data Lake
├── variables.tf         # Mapeia as variáveis de entrada de infraestrutura (região, ambiente, nomes)
├── deploy_infra.sh      # Script automatizado para implantação isolada deste repositório
└── destroy_infra.sh     # Script automatizado para destruição isolada deste repositório
```

> 💡 **Nota de Arquitetura:** Este projeto adota uma abordagem estritamente focada em IaaS/PaaS da Azure. Ele deve ser executado com sucesso e finalizado antes de iniciar qualquer configuração lógica de dados dentro do Databricks.

---

## 🛠️ Detalhes da Infraestrutura e Componentes

### 1. Isolamento de Rede Dedicado (`networking.tf` & `security.tf`)
O Workspace é implantado utilizando a técnica de injeção de VNet (*VNet Injection*), alocando o tráfego em duas sub-redes totalmente restritas e protegidas por Network Security Groups (NSGs):
* **Sub-rede Pública:** Gerencia a comunicação de controle interna necessária para a malha do Databricks.
* **Sub-rede Privada:** Destinada à alocação segura dos nós computacionais, operando com IP público totalmente desativado (`no_public_ip = true`).

### 2. Persistência de Dados Base (`storage.tf`)
Estrutura a conta de armazenamento **Azure Storage Account** configurada nativamente como **Data Lake Storage Gen2** (`is_hns_enabled = true`). Ela adota replicação local (`LRS`) para otimização máxima de custos em ambiente de laboratório e provisiona o container raiz básico utilizado para a estrutura do ecossistema.

### 3. Monitoramento e Observabilidade (`monitoring.tf`)
Integra o Workspace do Databricks com o **Azure Log Analytics Workspace**. Esta camada captura e centraliza de maneira centralizada a telemetria agregada (`allLogs`), garantindo auditorias futuras de ciclos de vida de clusters e auditoria do Spark de forma nativa.

---

## 🚀 Como Provisionar o Ambiente

O ciclo de vida deste repositório é gerenciado por scripts de automação exclusivos. Isso impede que atualizações lógicas em tabelas ou jobs gerem gatilhos indesejados que possam recriar ou interromper os componentes de rede da Azure.

### 1. Implantando a Infraestrutura Básica
Abra o terminal na pasta deste repositório, faça o login na sua conta da Azure através do CLI e execute o script passando o ambiente desejado (`dev` ou `main`):

#### 🛠️ Executando em Desenvolvimento (Dev):
```bash
chmod +x deploy_infra.sh
./deploy_infra.sh dev
```

#### 🚀 Executando em Produção (Prod):
```bash
chmod +x deploy_infra.sh
./deploy_infra.sh main
```

O Terraform exibirá a URL direta de acesso ao Workspace no terminal através do arquivo `outputs.tf`. **Guarde esta URL**, pois ela será solicitada pelo segundo repositório (`azure-databricks-config`) para realizar as conexões de dados.

---

### 💥 Como Destruir a Infraestrutura

Caso precise limpar o ambiente e apagar todos os recursos físicos criados na Azure para zerar os custos, execute o script de destruição dedicado. 

*⚠️ **Importante:** Você deve obrigatoriamente executar a destruição do repositório lógico (`azure-databricks-config`) antes de rodar este comando.*

```bash
chmod +x destroy_infra.sh
./destroy_infra.sh dev
```

---

### 🔐 Mecanismo de Autenticação (`providers.tf`)
A autenticação do Terraform está parametrizada com o escopo nativo da Azure. Isso garante que ele herde os tokens de acesso gerados pelo comando `az login` executado localmente ou pelas credenciais do Service Principal em esteiras de CI/CD (Azure DevOps), eliminando a necessidade de gerenciamento de chaves manuais.


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