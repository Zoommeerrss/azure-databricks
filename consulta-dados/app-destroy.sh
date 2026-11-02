#!/bin/bash
set -euo pipefail

# Captura o ambiente (ex: ./destroy_infra.sh dev)
AMBIENTE="${1:-}"

if [[ "$AMBIENTE" != "dev" && "$AMBIENTE" != "main" ]]; then
    echo "❌ Erro: Você deve especificar um ambiente válido!"
    echo "Uso correto: $0 [dev|main]"
    exit 1
fi

echo "====================================================================="
echo "💥 DESTRUINDO INFRAESTRUTURA AZURE: ${AMBIENTE^^}"
echo "====================================================================="
echo ""
echo "⚠️  ATENÇÃO:"
echo "   • Workspace Databricks"
echo "   • VNet e Subnets"
echo "   • Storage Accounts"
echo "   • Managed Resource Groups"
echo "   • Recursos gerenciados pelo Terraform"
echo ""

read -p "Tem certeza absoluta que deseja continuar? (y/N): " CONFIRMACAO

if [[ ! "$CONFIRMACAO" =~ ^[Yy]$ ]]; then
    echo "❌ Operação cancelada pelo usuário."
    exit 0
fi

echo ""
echo "🧹 Limpando artefatos temporários..."

find . -maxdepth 1 -name "*.tfplan" -type f -delete
rm -f crash.log
rm -f terraform.tfstate.backup
rm -rf .terraform

echo "✅ Limpeza concluída"

echo ""
echo "📥 Inicializando Terraform..."
terraform init -upgrade -reconfigure

MAX_TENTATIVAS=3
TENTATIVA=1

while [ $TENTATIVA -le $MAX_TENTATIVAS ]; do

    echo ""
    echo "====================================================================="
    echo "💥 TENTATIVA ${TENTATIVA}/${MAX_TENTATIVAS}"
    echo "====================================================================="

    terraform plan \
      -destroy \
      -var-file="envs/${AMBIENTE}.tfvars" \
      -var="environment=${AMBIENTE}" \
      -out=destroy_plan.tfplan

    terraform apply -auto-approve destroy_plan.tfplan

    rm -f destroy_plan.tfplan

    echo ""
    echo "🔍 Verificando recursos restantes no state..."

    RECURSOS_RESTANTES=$(terraform state list 2>/dev/null || true)

    if [ -z "$RECURSOS_RESTANTES" ]; then
        echo "✅ Nenhum recurso restante encontrado."
        break
    fi

    echo ""
    echo "⚠️ Recursos ainda existentes:"
    echo "$RECURSOS_RESTANTES"

    TENTATIVA=$((TENTATIVA + 1))

    sleep 30

done

echo ""
echo "🔎 Validação final..."

RECURSOS_RESTANTES=$(terraform state list 2>/dev/null || true)

if [ -n "$RECURSOS_RESTANTES" ]; then
    echo ""
    echo "❌ Ainda existem recursos no state após ${MAX_TENTATIVAS} tentativas:"
    echo ""
    echo "$RECURSOS_RESTANTES"
    echo ""
    echo "⚠️ Verifique dependências presas no Azure ou Databricks."
    exit 1
fi

echo ""
echo "====================================================================="
echo "✅ DESTRUIÇÃO CONCLUÍDA COM SUCESSO!"
echo "✅ Nenhum recurso restante no Terraform State."
echo "====================================================================="