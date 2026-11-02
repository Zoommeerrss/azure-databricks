#!/bin/bash
set -euo pipefail

# Captura o ambiente (ex: ./deploy_infra.sh dev)
AMBIENTE="${1:-}"

if [[ "$AMBIENTE" != "dev" && "$AMBIENTE" != "main" ]]; then
    echo "❌ Erro: Você deve especificar um ambiente válido!"
    echo "Uso correto: $0 [dev|main]"
    exit 1
fi

echo "====================================================================="
echo "🏗️  PROVISIONANDO INFRAESTRUTURA AZURE: ${AMBIENTE^^}"
echo "====================================================================="

echo "🧹 Limpando artefatos temporários do Terraform..."

# Remove arquivos de plano
find . -maxdepth 1 -name "*.tfplan" -type f -delete

# Remove logs de crash
rm -f crash.log

# Remove backup de state (sem apagar o state principal)
rm -f terraform.tfstate.backup

# Limpa cache de providers e módulos
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
    -var-file="envs/${AMBIENTE}.tfvars" \
    -var="environment=${AMBIENTE}" \
    -out=install_plan.tfplan

echo ""
echo "🚀 Aplicando alterações..."
terraform apply install_plan.tfplan

echo ""
echo "🧹 Removendo plano temporário..."
rm -f install_plan.tfplan

echo ""
echo "====================================================================="
echo "📌 URL DO WORKSPACE:"

# Captura o output em uma variável de forma segura para evitar quebras do Bash
if DATABRICKS_URL=$(terraform output -raw databricks_workspace_url 2>/dev/null); then
    echo "https://${DATABRICKS_URL}"
else
    echo "⚠️  Não foi possível extrair a URL automaticamente. Verifique o estado do Terraform."
fi

echo "====================================================================="
echo "✅ DEPLOY CONCLUÍDO COM SUCESSO!"
echo "====================================================================="