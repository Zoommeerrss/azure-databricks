#!/bin/bash

set -euo pipefail

##########################################
# Validação dos parâmetros
##########################################

AMBIENTE="${1:-}"

if [[ "$AMBIENTE" != "dev" && "$AMBIENTE" != "prod" ]]; then
    echo "❌ Erro: ambiente inválido."
    echo "Uso: $0 [dev|prod]"
    exit 1
fi

##########################################
# Ajuste de diretório
##########################################

if [[ -d "terraform" ]]; then
    cd terraform
fi

TF_VAR_FILE="envs/${AMBIENTE}.tfvars"

if [[ ! -f "$TF_VAR_FILE" ]]; then
    echo "❌ Arquivo não encontrado:"
    echo "   $TF_VAR_FILE"
    exit 1
fi

echo "====================================================================="
echo "⚙️ DEPLOY DATABRICKS APPLICATION"
echo "🌎 Ambiente: ${AMBIENTE^^}"
echo "====================================================================="

##########################################
# Limpeza segura
##########################################

echo "🧹 Limpando artefatos temporários..."

find . -maxdepth 1 -name "*.tfplan" -type f -delete

rm -f crash.log
rm -f terraform.tfstate.backup

# Limpa apenas cache local
rm -rf .terraform
rm -f .terraform.lock.hcl

echo "✅ Limpeza concluída"

##########################################
# Backend
##########################################

echo "🔍 Lendo configuração do backend..."

RESOURCE_GROUP=$(grep -E '^resource_group_name' "$TF_VAR_FILE" | awk -F '"' '{print $2}')
STORAGE_ACCOUNT=$(grep -E '^storage_account_name' "$TF_VAR_FILE" | awk -F '"' '{print $2}')
CONTAINER=$(grep -E '^container_name' "$TF_VAR_FILE" | awk -F '"' '{print $2}')

if [[ -z "$RESOURCE_GROUP" || -z "$STORAGE_ACCOUNT" || -z "$CONTAINER" ]]; then
    echo "❌ Não foi possível localizar configurações do backend no tfvars."
    exit 1
fi

##########################################
# Terraform Init
##########################################

echo "📥 Inicializando Terraform..."

terraform init \
    -upgrade \
    -reconfigure \
    -input=false \
    -backend-config="resource_group_name=${RESOURCE_GROUP}" \
    -backend-config="storage_account_name=${STORAGE_ACCOUNT}" \
    -backend-config="container_name=${CONTAINER}"

##########################################
# Validate
##########################################

echo "🔍 Validando Terraform..."

terraform validate

##########################################
# Plan
##########################################

echo "📊 Gerando plano..."

terraform plan \
    -input=false \
    -var-file="$TF_VAR_FILE" \
    -out=install_plan.tfplan

##########################################
# Apply
##########################################

echo "🚀 Aplicando alterações..."

terraform apply \
    -input=false \
    install_plan.tfplan

##########################################
# Pós deploy
##########################################

echo "🔍 Validando divergências..."

if terraform plan \
    -detailed-exitcode \
    -input=false \
    -var-file="$TF_VAR_FILE" \
    >/dev/null 2>&1
then
    echo "✅ Ambiente convergiu corretamente."
else
    EXIT_CODE=$?

    if [[ $EXIT_CODE -eq 2 ]]; then
        echo "⚠️ Existe drift ou recurso pendente após o deploy."
        exit 2
    fi

    exit $EXIT_CODE
fi

##########################################
# Limpeza final
##########################################

rm -f install_plan.tfplan

##########################################
# Finalização
##########################################

echo ""
echo "====================================================================="
echo "✅ DEPLOY CONCLUÍDO COM SUCESSO"
echo "🌎 Ambiente: ${AMBIENTE^^}"
echo "====================================================================="