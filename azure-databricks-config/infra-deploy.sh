#!/bin/bash
set -euo pipefail

# Captura o ambiente (ex: ./infra-install.sh dev)
AMBIENTE="${1:-}"

if [[ "$AMBIENTE" != "dev" && "$AMBIENTE" != "main" ]]; then
    echo "❌ Erro: Você deve especificar um ambiente válido!"
    echo "Uso correto: $0 [dev|main]"
    exit 1
fi

# Define a branch automaticamente
if [[ "$AMBIENTE" == "main" ]]; then
    BRANCH="main"
else
    BRANCH="dev"
fi

TFVARS_FILE="envs/${AMBIENTE}.tfvars"

if [[ ! -f "$TFVARS_FILE" ]]; then
    echo "❌ Arquivo não encontrado: $TFVARS_FILE"
    exit 1
fi

echo "====================================================================="
echo "⚙️ CONFIGURANDO COMPONENTES DATABRICKS: ${AMBIENTE^^}"
echo "====================================================================="

echo "🧹 Limpando artefatos temporários..."

find . -maxdepth 1 -name "*.tfplan" -type f -delete
rm -f crash.log

# Limpa cache dos providers e módulos
rm -rf .terraform
rm -f .terraform.lock.hcl

echo "✅ Limpeza concluída"

echo ""
echo "📥 Inicializando Terraform..."
terraform init -upgrade -reconfigure

echo ""
echo "🔍 Validando configuração..."
terraform validate

echo ""
echo "📊 Gerando plano..."

terraform plan \
  -input=false \
  -var-file="$TFVARS_FILE" \
  -var="environment=${AMBIENTE}" \
  -var="git_branch=${BRANCH}" \
  -out=install_plan.tfplan

echo ""
echo "🚀 Aplicando alterações..."

terraform apply \
  -input=false \
  install_plan.tfplan

echo ""
echo "🔍 Validando estado..."

terraform state list >/dev/null

echo ""
echo "🧹 Removendo plano temporário..."
rm -f install_plan.tfplan

echo ""
echo "====================================================================="
echo "📋 RESUMO"
echo "====================================================================="

echo "Ambiente : $AMBIENTE"
echo "Branch    : $BRANCH"
echo "Tfvars    : $TFVARS_FILE"

echo ""
echo "✅ Deploy concluído!"
echo "====================================================================="
