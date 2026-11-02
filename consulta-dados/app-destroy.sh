#!/bin/bash
set -euo pipefail

# Captura o ambiente (ex: ./app-destroy.sh dev)
AMBIENTE="${1:-}"

if [[ "$AMBIENTE" != "dev" && "$AMBIENTE" != "main" ]]; then
    echo "❌ Erro: Você deve especificar um ambiente válido!"
    echo "Uso correto: $0 [dev|main]"
    exit 1
fi

echo "====================================================================="
echo "💥 DESTRUINDO INFRAESTRUTURA AZURE: ${AMBIENTE^^} (MODO AUTOMÁTICO)"
echo "====================================================================="

# =====================================================================
# 🚀 CORRIGIDO: Entra no diretório correto antes das ações
# =====================================================================
if [ -d "terraform" ]; then
    cd terraform
fi

echo ""
echo "🧹 Limpando artefatos temporários locais..."
find . -maxdepth 1 -name "*.tfplan" -type f -delete
rm -f crash.log
rm -f terraform.tfstate.backup

# 🚀 ADICIONADO: Extrai os metadados físicos do tfvars para alimentar o backend do init sem intervenção manual
RESOURCE_GROUP=$(grep -E '^resource_group_name' "envs/${AMBIENTE}.tfvars" | awk -F'=' '{print $2}' | tr -d '" ')
STORAGE_ACCOUNT=$(grep -E '^storage_account_name' "envs/${AMBIENTE}.tfvars" | awk -F'=' '{print $2}' | tr -d '" ')
CONTAINER_NAME=$(grep -E '^container_name' "envs/${AMBIENTE}.tfvars" | awk -F'=' '{print $2}' | tr -d '" ')

echo ""
echo "📥 Inicializando Terraform com as credenciais do Backend..."
# 🚀 CORRIGIDO: Alimenta o backend dinamicamente para evitar o erro de falta de chaves da Azure
terraform init \
  -upgrade \
  -reconfigure \
  -backend-config="resource_group_name=${RESOURCE_GROUP}" \
  -backend-config="storage_account_name=${STORAGE_ACCOUNT}" \
  -backend-config="container_name=${CONTAINER_NAME}" \
  -input=false

echo ""
echo "🔄 Selecionando o Workspace do ambiente..."
terraform workspace select -or-create "$AMBIENTE"

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

    # Executa sem pedir confirmação (auto-approve)
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
