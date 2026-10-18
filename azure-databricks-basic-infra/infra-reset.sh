#!/bin/bash
set -e

# Captura o ambiente (ex: ./destroy_infra.sh dev)
AMBIENTE=$1

if [ "$AMBIENTE" != "dev" ] && [ "$AMBIENTE" != "main" ]; then
    echo "❌ Erro: Você deve especificar o ambiente de forma válida!"
    echo "Uso correto: $0 [dev|main]"
    exit 1
fi

echo "====================================================================="
echo "💥 INICIANDO DESTRUIÇÃO DA INFRAESTRUTURA AZURE: AMBIENTE = ${AMBIENTE^^}"
echo "====================================================================="
echo "⚠️  PERIGO: Isso vai apagar fisicamente a VNet, as Subnets e o Workspace Databricks!"
read -p "Tem certeza absoluta que deseja destruir a fundação da nuvem? (y/N): " CONFIRMACAO
if [[ ! "$CONFIRMACAO" =~ ^[Yy]$ ]]; then
    echo "❌ Operação cancelada pelo usuário."
    exit 0
fi

echo "🧹 Limpando planos antigos..."
rm -f destroy_plan.tfplan

echo "📥 Inicializando e Validando Provedores Azure..."
terraform init

echo "📊 Gerando Plano de Destruição da Infraestrutura..."
terraform plan -destroy -var-file="envs/${AMBIENTE}.tfvars" -var="environment=${AMBIENTE}" -out=destroy_plan.tfplan

echo "💥 Executando a Destruição Física na Azure (Isso pode levar alguns minutos)..."
terraform apply destroy_plan.tfplan

rm destroy_plan.tfplan

echo "====================================================================="
echo "✅ CONCLUÍDO! Toda a infraestrutura básica da Azure foi limpa e removida!"
echo "====================================================================="
