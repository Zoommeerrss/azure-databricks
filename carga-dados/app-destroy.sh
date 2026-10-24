#!/bin/bash
set -e

# Captura o ambiente (ex: ./app-destroy.sh dev)
AMBIENTE=$1

if [ "$AMBIENTE" != "dev" ] && [ "$AMBIENTE" != "prod" ]; then
    echo "❌ Erro: Você deve especificar o ambiente de forma válida!"
    echo "Uso correto: $0 [dev|prod]"
    exit 1
fi

# Define o arquivo .tfvars correto baseado no argumento informado
TF_VAR_FILE="terraform/envs/${AMBIENTE}.tfvars"

if [ ! -f "$TF_VAR_FILE" ]; then
    echo "❌ Erro: Arquivo de variáveis não encontrado em: $TF_VAR_FILE"
    exit 1
fi

echo "====================================================================="
echo "💥 DESTRUIÇÃO LÓGICA DA APLICAÇÃO DATABRICKS: AMBIENTE = ${AMBIENTE^^}"
echo "====================================================================="
echo "⚠️  ATENÇÃO: Isso removerá os Jobs, Notebooks e Módulos desta aplicação!"

# Confirmação manual de segurança para execução local
read -p "👉 Tem certeza que deseja continuar? (y/N): " CONFIRMACAO
if [[ ! "$CONFIRMACAO" =~ ^[Yy]$ ]]; then
    echo "❌ Operação cancelada pelo usuário."
    exit 0
fi

# Entra na pasta do terraform se o script for executado da raiz do projeto
if [ -d "terraform" ]; then
    cd terraform
    TF_VAR_FILE="envs/${AMBIENTE}.tfvars"
fi

echo "🧹 Limpando planos antigos..."
rm -f destroy_plan.tfplan

echo "📥 Sincronizando Provedores Databricks via Terraform..."
terraform init

echo "🌐 Selecionando Workspace do Terraform para: ${AMBIENTE}..."
terraform workspace select ${AMBIENTE}

echo "📊 Gerando Plano de Destruição Lógica..."
terraform plan -destroy -var-file="$TF_VAR_FILE" -out=destroy_plan.tfplan

echo "💥 Executando o Clean-up da Aplicação no Databricks..."
terraform apply destroy_plan.tfplan

# Limpeza do plano temporário
rm -f destroy_plan.tfplan

echo "====================================================================="
echo "✅ CONCLUÍDO! Componentes lógicos da aplicação removidos com sucesso!"
echo "====================================================================="
