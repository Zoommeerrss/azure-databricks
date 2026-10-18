#!/bin/bash
set -e

# Captura o ambiente (ex: ./infra-install.sh dev)
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

echo "====================================================================="
echo "⚙️  CONFIGURANDO COMPONENTES LÓGICOS DATABRICKS: AMBIENTE = ${AMBIENTE^^}"
echo "====================================================================="

echo "🧹 Limpando planos antigos..."
rm -f install_plan.tfplan

echo "📥 Inicializando e Validando Provedores Databricks..."
terraform init -upgrade
terraform validate

echo "📊 Gerando Plano de Configuração Automatizado..."
# O Terraform busca a URL do Workspace e o Catálogo internamente por conta própria
terraform plan -var="environment=${AMBIENTE}" -var="git_branch=${BRANCH}" -out=install_plan.tfplan

echo "🚀 Aplicando Governança e Orquestração..."
terraform apply install_plan.tfplan

rm install_plan.tfplan

echo "====================================================================="
echo "✅ CONCLUÍDO! Ecossistema configurado de forma 100% automatizada!"
echo "====================================================================="
