#!/bin/bash
set -e

# Captura o primeiro argumento passado no terminal (ex: ./install_infra.sh dev)
AMBIENTE=$1

# Valida se o usuário informou o ambiente corretamente
if [ "$AMBIENTE" != "dev" ] && [ "$AMBIENTE" != "main" ]; then
    echo "❌ Erro: Você deve especificar o ambiente de forma válida!"
    echo "Uso correto: $0 [dev|main]"
    exit 1
fi

# Define a branch do Git baseada no ambiente escolhido
if [ "$AMBIENTE" == "main" ]; then
    BRANCH="main"
else
    BRANCH="dev"
fi

echo "====================================================================="
echo "🚀 INICIANDO SETUP E PROVISIONAMENTO: AMBIENTE = ${AMBIENTE^^}"
echo "====================================================================="

echo "🧹 Limpando planos temporários antigos..."
rm -f install_plan.tfplan
rm -f .terraform.lock.hcl
rm -rf .terraform/ .terraform.lock.hcl
rm -rf ~/.terraform.d/plugin-cache/
rm -rf .terraform/
rm -rf terraform.tfstate

echo "🏗️ Inicializando o Terraform..."
terraform init -upgrade
terraform init

echo "🔍 Validando os arquivos de configuração..."
terraform validate

echo "📊 Gerando o plano de execução (Modo Automático)..."
# Injeta as variáveis dinamicamente sem travar a tela pedindo inputs
terraform plan -var="environment=${AMBIENTE}" -var="git_branch=${BRANCH}" -out=install_plan.tfplan

echo "🚀 Aplicando as alterações na Azure..."
terraform apply -auto-approve install_plan.tfplan

rm install_plan.tfplan
echo "====================================================================="
echo "✅ CONCLUÍDO! Infraestrutura de ${AMBIENTE^^} atualizada com sucesso!"
echo "====================================================================="
