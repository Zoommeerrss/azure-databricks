#!/bin/bash
set -e

# Captura o ambiente (ex: ./deploy_config.sh dev)
AMBIENTE=$1

if [ "$AMBIENTE" != "dev" ] && [ "$AMBIENTE" != "main" ]; then
    echo "❌ Erro: Você deve especificar o ambiente de forma válida!"
    echo "Uso correto: $0 [dev|main]"
    exit 1
fi

# Define a branch de forma automática
if [ "$AMBIENTE" == "main" ]; then
    BRANCH="main"
else
    BRANCH="dev"
fi

# Se a variável de ambiente com a URL não existir no terminal, solicita ao usuário
if [ -z "$TF_VAR_databricks_workspace_url" ]; then
    echo "🌐 URL do Databricks Workspace não encontrada na sessão."
    read -p "👉 Cole a URL do Workspace gerada pelo repositório de infraestrutura: " URL_INPUT
    # Remove eventuais barras extras no final da URL inserida
    export TF_VAR_databricks_workspace_url=$(echo "$URL_INPUT" | sed 's/\/$//')
fi

echo "====================================================================="
echo "⚙️  CONFIGURANDO COMPONENTES LÓGICOS DATABRICKS: AMBIENTE = ${AMBIENTE^^}"
echo "====================================================================="

echo "🧹 Limpando planos antigos..."
rm -f install_plan.tfplan

echo "📥 Inicializando e Validando Provedores Databricks..."
terraform init -upgrade
terraform validate

echo "📊 Gerando Plano de Configuração (Unity Catalog, Cluster e Jobs)..."
# O Terraform lerá automaticamente a URL a partir do TF_VAR exportado acima
terraform plan -var="environment=${AMBIENTE}" -var="git_branch=${BRANCH}" -out=install_plan.tfplan

echo "🚀 Aplicando Governança e Orquestração..."
terraform apply install_plan.tfplan

rm install_plan.tfplan

echo "====================================================================="
echo "✅ CONCLUÍDO! Componentes lógicos atualizados sem afetar a Infra Azure!"
echo "====================================================================="
