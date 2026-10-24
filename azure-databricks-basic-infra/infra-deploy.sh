#!/bin/bash
set -e

# Captura o ambiente (ex: ./deploy_infra.sh dev)
AMBIENTE=$1

if [ "$AMBIENTE" != "dev" ] && [ "$AMBIENTE" != "main" ]; then
    echo "❌ Erro: Você deve especificar o ambiente de forma válida!"
    echo "Uso correto: $0 [dev|main]"
    exit 1
fi

echo "====================================================================="
echo "🏗️  PROVISIONANDO INFRAESTRUTURA BÁSICA AZURE: AMBIENTE = ${AMBIENTE^^}"
echo "====================================================================="

echo "🧹 Limpando planos antigos..."
rm -f install_plan.tfplan

echo "📥 Inicializando e Validando Provedores Azure..."
terraform init -upgrade
terraform validate

echo "📊 Gerando Plano de Infraestrutura..."
terraform plan -var-file="envs/${AMBIENTE}.tfvars" -var="environment=${AMBIENTE}" -out=install_plan.tfplan

echo "🚀 Aplicando Alterações na Azure..."
terraform apply install_plan.tfplan

rm install_plan.tfplan

echo "====================================================================="
echo "📌 URL DO WORKSPACE GERADO PARA O PRÓXIMO PASSO:"
terraform output -raw databricks_workspace_url
echo -e "\n====================================================================="
echo "✅ CONCLUÍDO! Infraestrutura básica da Azure atualizada com sucesso!"
echo "====================================================================="
