#!/bin/bash
set -e

# Captura o ambiente (ex: ./infra-install.sh dev)
AMBIENTE=$1

if [ "$AMBIENTE" != "dev" ] && [ "$AMBIENTE" != "prod" ]; then
    echo "❌ Erro: Você deve especificar o ambiente de forma válida!"
    echo "Uso correto: $0 [dev|prod]"
    exit 1
fi

# 🚀 VALIDAÇÃO: Garante que o desenvolvedor configurou o Token de acesso localmente antes de rodar
if [ -z "$DATABRICKS_TOKEN" ]; then
    echo "❌ Erro: A variável de ambiente DATABRICKS_TOKEN não está definida no seu terminal!"
    echo "Execute primeiro: export DATABRICKS_TOKEN='seu_token_aqui'"
    exit 1
fi

# Define o arquivo .tfvars correto baseado no argumento informado
TF_VAR_FILE="envs/${AMBIENTE}.tfvars"

if [ ! -f "$TF_VAR_FILE" ]; then
    echo "❌ Erro: Arquivo de variáveis não encontrado em: $TF_VAR_FILE"
    exit 1
fi

echo "====================================================================="
echo "⚙️  CONFIGURANDO COMPONENTES LÓGICOS DATABRICKS: AMBIENTE = ${AMBIENTE^^}"
echo "====================================================================="

# Entra na pasta do terraform se o script for executado da raiz do projeto
if [ -d "terraform" ]; then
    cd terraform
fi

echo "🧹 Limpando planos antigos..."
rm -f install_plan.tfplan

echo "📥 Inicializando e Validando Provedores Databricks..."
terraform init -upgrade
terraform validate

# 🚀 MULTIAMBIENTE: Seleciona ou cria o Workspace do Terraform correspondente localmente
echo "🌐 Configurando Workspace do Terraform para: ${AMBIENTE}..."
terraform workspace select ${AMBIENTE} || terraform workspace new ${AMBIENTE}

echo "📊 Gerando Plano de Configuração Automatizado..."
# 🚀 CORRIGIDO: Agora aponta corretamente para o arquivo .tfvars do ambiente mapeado
terraform plan -var-file="$TF_VAR_FILE" -out=install_plan.tfplan

echo "🚀 Aplicando Governança e Orquestração..."
terraform apply install_plan.tfplan

# Limpeza segura do arquivo de plano temporário
rm -f install_plan.tfplan

echo "====================================================================="
echo "✅ CONCLUÍDO! Ecossistema configurado de forma 100% automatizada!"
echo "====================================================================="
