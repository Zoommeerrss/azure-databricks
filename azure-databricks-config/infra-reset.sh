#!/bin/bash
set -e

# Captura o ambiente (ex: ./infra-reset.sh dev)
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

echo "====================================================================="
echo "💥 INICIANDO DESTRUIÇÃO LÓGICA DO DATABRICKS: AMBIENTE = ${AMBIENTE^^}"
echo "====================================================================="
echo "⚠️  ATENÇÃO: Isso removerá os Jobs, Clusters e Schemas do Databricks!"
read -p "👉 Tem certeza que deseja continuar? (y/N): " CONFIRMACAO
if [[ ! "$CONFIRMACAO" =~ ^[Yy]$ ]]; then
    echo "❌ Operação cancelada pelo usuário."
    exit 0
fi

echo "🧹 Limpando planos antigos..."
rm -f destroy_plan.tfplan

echo "📥 Inicializando Provedores Databricks..."
terraform init

echo "📊 Gerando Plano de Destruição Lógica..."
# 🚀 CORRIGIDO: O Terraform busca o host sozinho via remote_state. 
# Ajustada também a sintaxe correta das flags de variáveis (-var="...")
terraform plan -destroy \
  -var="environment=${AMBIENTE}" \
  -var="git_branch=${BRANCH}" \
  -out=destroy_plan.tfplan

echo "💥 Executando o Clean-up Lógico no Databricks..."
terraform apply destroy_plan.tfplan

rm destroy_plan.tfplan

echo "====================================================================="
echo "✅ CONCLUÍDO! Componentes lógicos removidos com sucesso!"
echo "👉 A nuvem está limpa. Liberado para rodar o reset da infraestrutura básica."
echo "====================================================================="
