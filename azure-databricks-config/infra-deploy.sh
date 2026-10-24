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

# Mapeia o arquivo de variáveis baseado na pasta envs/
TFVARS_FILE="envs/${AMBIENTE}.tfvars"

if [ ! -f "$TFVARS_FILE" ]; then
    echo "❌ Erro: O arquivo de configuração '$TFVARS_FILE' não foi encontrado!"
    exit 1
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
# Injeta o arquivo estático da pasta envs e bloqueia prompts interativos (-input=false)
terraform plan \
    -input=false \
    -var-file="$TFVARS_FILE" \
    -var="environment=${AMBIENTE}" \
    -var="git_branch=${BRANCH}" \
    -out=install_plan.tfplan

echo "🚀 Aplicando Governança e Orquestração..."
terraform apply -input=false install_plan.tfplan

rm install_plan.tfplan

echo "====================================================================="
echo "✅ CONCLUÍDO! Ecossistema configurado de forma 100% automatizada!"
echo "====================================================================="
