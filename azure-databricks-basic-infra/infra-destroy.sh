#!/bin/bash
set -euo pipefail

# Captura o ambiente
AMBIENTE="${1:-}"

if [[ "$AMBIENTE" != "dev" && "$AMBIENTE" != "main" ]]; then
    echo "❌ Erro: Você deve especificar um ambiente válido!"
    echo "Uso correto: $0 [dev|main]"
    exit 1
fi

echo "====================================================================="
echo "💥 DESTRUINDO INFRAESTRUTURA AZURE: ${AMBIENTE^^}"
echo "====================================================================="
echo "⚠️  ATENÇÃO:"
echo "   • Workspace Databricks"
echo "   • VNet e Subnets"
echo "   • Recursos Azure gerenciados pelo Terraform"
echo "   • Recursos Databricks gerenciados pelo Terraform"
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

# Limpa cache local sem afetar state remoto
rm -rf .terraform

echo "✅ Limpeza concluída"

echo ""
echo "📥 Inicializando Terraform..."
terraform init -upgrade -reconfigure

echo ""
echo "📊 Gerando plano de destruição..."

terraform plan \
  -destroy \
  -var-file="envs/${AMBIENTE}.tfvars" \
  -var="environment=${AMBIENTE}" \
  -out=destroy_plan.tfplan

echo ""
echo "💥 Executando destruição..."

terraform apply destroy_plan.tfplan

rm -f destroy_plan.tfplan

echo ""
echo "🔍 Validando se ainda existem recursos no state..."

MAX_TENTATIVAS=3
TENTATIVA=1

while [ $TENTATIVA -le $MAX_TENTATIVAS ]; do

    RECURSOS_RESTANTES=$(terraform state list 2>/dev/null || true)

    if [ -z "$RECURSOS_RESTANTES" ]; then
        echo ""
        echo "✅ Terraform State vazio."
        break
    fi

    echo ""
    echo "⚠️ Recursos ainda encontrados após destroy:"
    echo "$RECURSOS_RESTANTES"
    echo ""

    echo "🔄 Nova tentativa de destruição ($TENTATIVA/$MAX_TENTATIVAS)..."

    terraform destroy \
        -auto-approve \
        -var-file="envs/${AMBIENTE}.tfvars" \
        -var="environment=${AMBIENTE}"

    TENTATIVA=$((TENTATIVA + 1))
done

echo ""
echo "🔎 Verificação final..."

RECURSOS_FINAIS=$(terraform state list 2>/dev/null || true)

if [ -n "$RECURSOS_FINAIS" ]; then
    echo ""
    echo "❌ Ainda existem recursos registrados no Terraform State:"
    echo ""
    echo "$RECURSOS_FINAIS"
    echo ""
    echo "⚠️ Verifique dependências pendentes ou recursos protegidos."
    exit 1
fi

echo ""
echo "====================================================================="
echo "✅ DESTRUIÇÃO CONCLUÍDA COM SUCESSO!"
echo "✅ Nenhum recurso restante encontrado no Terraform State."
echo "====================================================================="