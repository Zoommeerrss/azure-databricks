#!/bin/bash
set -e

# Captura o ambiente (ex: ./destroy_config.sh dev)
AMBIENTE=$1

if [ "$AMBIENTE" != "dev" ] && [ "$AMBIENTE" != "main" ]; then
    echo "❌ Erro: Você deve especificar o ambiente de forma válida!"
    echo "Uso correto: $0 [dev|main]"
    exit 1
fi

# Define a branch de forma automática apenas para validação do Terraform
if [ "$AMBIENTE" == "main" ]; then
    BRANCH="main"
else
    BRANCH="dev"
fi

# Se a variável de ambiente com a URL não existir no terminal, solicita ao usuário
if [ -z "$TF_VAR_databricks_workspace_url" ]; then
    echo "🌐 URL do Databricks Workspace não encontrada na sessão."
    read -p "👉 Cole a URL do Workspace gerada pelo repositório de infraestrutura: " URL_INPUT
    export TF_VAR_databricks_workspace_url=$(echo "$URL_INPUT" | sed 's/\/$//')
fi

echo "====================================================================="
echo "💥 INICIANDO DESTRUIÇÃO LOGICA DO DATABRICKS: AMBIENTE = ${AMBIENTE^^}"
echo "====================================================================="
echo "⚠️  ATENÇÃO: Isso removerá os Jobs, Clusters, Schemas e Catálogos!"
read -p "Tem certeza que deseja continuar? (y/N): " CONFIRMACAO
if [[ ! "$CONFIRMACAO" =~ ^[Yy]$ ]]; then
    echo "❌ Operação cancelada pelo usuário."
    exit 0
fi

echo "🧹 Limpando planos antigos..."
rm -f destroy_plan.tfplan

echo "📥 Inicializando e Validando Provedores..."
terraform init

echo "📊 Gerando Plano de Destruição Lógica..."
terraform plan -destroy -var("environment=${AMBIENTE}") -var("git_branch=${BRANCH}") -out=destroy_plan.tfplan

echo "💥 Executando o Clean-up Lógico no Databricks..."
terraform apply destroy_plan.tfplan

rm destroy_plan.tfplan

echo "====================================================================="
echo "✅ CONCLUÍDO! Componentes lógicos removidos com sucesso!"
echo "👉 Agora você está liberado para rodar a destruição no repositório de infraestrutura básica."
echo "====================================================================="
