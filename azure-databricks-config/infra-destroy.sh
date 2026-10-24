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

# Mapeia o arquivo de variáveis baseado na pasta envs/
TFVARS_FILE="envs/${AMBIENTE}.tfvars"

if [ ! -f "$TFVARS_FILE" ]; then
    echo "❌ Erro: O arquivo de configuração '$TFVARS_FILE' não foi encontrado!"
    exit 1
fi

echo "====================================================================="
echo "💥 INICIANDO DESTRUIÇÃO LÓGICA DO DATABRICKS: AMBIENTE = ${AMBIENTE^^}"
echo "====================================================================="
echo "⚠️  ATENÇÃO: Isso removerá os Jobs, Clusters e Schemas do Databricks!"

# Se não estiver rodando em uma esteira de CI/CD (onde a var global $CI existe), pede confirmação manual
if [ -z "$CI" ]; then
    read -p "👉 Tem certeza que deseja continuar? (y/N): " CONFIRMACAO
    if [[ ! "$CONFIRMACAO" =~ ^[Yy]$ ]]; then
        echo "❌ Operação cancelada pelo usuário."
        exit 0
    fi
else
    echo "🤖 Executando em modo automação (CI/CD detectado). Pulando prompt..."
fi

echo "🧹 Limpando planos antigos..."
rm -f destroy_plan.tfplan

echo "📥 Inicializando Provedores Databricks..."
terraform init

echo "📊 Gerando Plano de Destruição Lógica..."
# Injeta o arquivo estático da pasta envs e bloqueia prompts interativos (-input=false)
terraform plan -destroy \
  -input=false \
  -var-file="$TFVARS_FILE" \
  -var="environment=${AMBIENTE}" \
  -var="git_branch=${BRANCH}" \
  -out=destroy_plan.tfplan

echo "💥 Executando o Clean-up Lógico no Databricks..."
terraform apply -input=false destroy_plan.tfplan

rm destroy_plan.tfplan

echo "====================================================================="
echo "✅ CONCLUÍDO! Componentes lógicos removidos com sucesso!"
echo "👉 A nuvem está limpa. Liberado para rodar o reset da infraestrutura básica."
echo "====================================================================="
