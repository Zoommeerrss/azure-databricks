#!/bin/bash
set -euo pipefail

AMBIENTE="${1:-}"

if [[ "$AMBIENTE" != "dev" && "$AMBIENTE" != "main" ]]; then
    echo "❌ Erro: Você deve especificar o ambiente de forma válida!"
    echo "Uso correto: $0 [dev|main]"
    exit 1
fi

BRANCH="$AMBIENTE"

TFVARS_FILE="envs/${AMBIENTE}.tfvars"

if [[ ! -f "$TFVARS_FILE" ]]; then
    echo "❌ Erro: Arquivo não encontrado: $TFVARS_FILE"
    exit 1
fi

echo "====================================================================="
echo "💥 DESTRUINDO CONFIGURAÇÃO DATABRICKS: ${AMBIENTE^^}"
echo "====================================================================="

if [[ -z "${CI:-}" ]]; then
    read -p "👉 Tem certeza que deseja continuar? (y/N): " CONFIRMACAO

    if [[ ! "$CONFIRMACAO" =~ ^[Yy]$ ]]; then
        echo "❌ Operação cancelada."
        exit 0
    fi
else
    echo "🤖 Execução CI/CD detectada."
fi

echo "🧹 Limpando artefatos temporários..."

find . -maxdepth 1 -name "*.tfplan" -type f -delete
rm -f crash.log
rm -f terraform.tfstate.backup
rm -rf .terraform

echo "📥 Inicializando Terraform..."
terraform init -upgrade -reconfigure

MAX_TENTATIVAS=5

for ((i=1;i<=MAX_TENTATIVAS;i++))
do

    echo ""
    echo "====================================================================="
    echo "🔁 Tentativa $i de $MAX_TENTATIVAS"
    echo "====================================================================="

    terraform plan \
      -destroy \
      -input=false \
      -var-file="$TFVARS_FILE" \
      -var="environment=${AMBIENTE}" \
      -var="git_branch=${BRANCH}" \
      -out=destroy_plan.tfplan

    terraform apply \
      -input=false \
      destroy_plan.tfplan

    rm -f destroy_plan.tfplan

    RESTANTE=$(terraform state list 2>/dev/null || true)

    if [[ -z "$RESTANTE" ]]; then
        echo ""
        echo "✅ State Terraform vazio."
        echo "✅ Todos os recursos foram removidos."
        break
    fi

    echo ""
    echo "⚠️ Recursos ainda presentes:"
    echo "$RESTANTE"

done

RESTANTE=$(terraform state list 2>/dev/null || true)

if [[ -n "$RESTANTE" ]]; then
    echo ""
    echo "❌ Ainda existem recursos no state após $MAX_TENTATIVAS tentativas:"
    echo ""
    echo "$RESTANTE"
    exit 1
fi

echo ""
echo "====================================================================="
echo "✅ DESTROY CONCLUÍDO COM SUCESSO!"
echo "✅ Nenhum recurso restante no Terraform State."
echo "====================================================================="