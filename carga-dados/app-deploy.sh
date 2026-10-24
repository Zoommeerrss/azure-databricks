#!/bin/bash
set -e

# Captura o ambiente (ex: ./app-deploy.sh dev)
AMBIENTE=$1

if [ "$AMBIENTE" != "dev" ] && [ "$AMBIENTE" != "prod" ]; then
    echo "❌ Erro: Você deve especificar o ambiente de forma válida!"
    echo "Uso correto: $0 [dev|prod]"
    exit 1
fi

# Define o arquivo .tfvars correto baseado no argumento informado
TF_VAR_FILE="terraform/envs/${AMBIENTE}.tfvars"

if [ ! -f "$TF_VAR_FILE" ]; then
    echo "❌ Erro: Arquivo de variáveis não encontrado em: $TF_VAR_FILE"
    exit 1
fi

echo "====================================================================="
echo "⚙️  DEPLOY DA APLICAÇÃO DATABRICKS: AMBIENTE = ${AMBIENTE^^}"
echo "====================================================================="

# Entra na pasta do terraform se o script for executado da raiz do projeto
if [ -d "terraform" ]; then
    cd terraform
    TF_VAR_FILE="envs/${AMBIENTE}.tfvars"
fi

echo "🧹 Limpando planos antigos..."
rm -f install_plan.tfplan

echo "📥 Inicializando e Validando Provedores Databricks via Terraform..."
# 🚀 RESOLVIDO: O script extrai as linhas do dev.tfvars e injeta dinamicamente nas chaves do init.
# Dessa forma, o Terraform só lê o que é de backend no init, e lê o resto no plan.
RESOURCE_GROUP=$(grep -E '^resource_group_name' "$TF_VAR_FILE" | awk -F '"' '{print $2}')
STORAGE_ACCOUNT=$(grep -E '^storage_account_name' "$TF_VAR_FILE" | awk -F '"' '{print $2}')
CONTAINER=$(grep -E '^container_name' "$TF_VAR_FILE" | awk -F '"' '{print $2}')

# Inicializa o backend passando apenas os valores físicos que o init precisa
terraform init -upgrade -input=false \
  -backend-config="resource_group_name=${RESOURCE_GROUP}" \
  -backend-config="storage_account_name=${STORAGE_ACCOUNT}" \
  -backend-config="container_name=${CONTAINER}"

terraform validate

# Cria o Workspace do Terraform correspondente (dev ou prod)
echo "📊 Gerando Plano de Configuração do Terraform..."
terraform plan -input=false -var-file="$TF_VAR_FILE" -out=install_plan.tfplan

echo "🚀 Aplicando Governança e Orquestração do Job..."
# 🚀 CORRIGIDO: Adicionado -input=false no apply do arquivo de plano para destravar o canal gRPC no WSL
terraform apply -input=false install_plan.tfplan

rm -f install_plan.tfplan

echo "====================================================================="
echo "✅ CONCLUÍDO! Deploy da aplicação realizado com sucesso via Terraform!"
echo "====================================================================="
