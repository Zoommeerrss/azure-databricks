#!/bin/bash
set -e

# Captura o ambiente (ex: ./infra-reset.sh dev)
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
echo "💥 INICIANDO DESTRUIÇÃO ANALÍTICA (CONSULTA): AMBIENTE = ${AMBIENTE^^}"
echo "====================================================================="
echo "⚠️  ATENÇÃO: Isso removerá os Notebooks publicados e o JOB_2 deste projeto no Databricks!"
read -p "👉 Tem certeza que deseja continuar? (y/N): " CONFIRMACAO
if [[ ! "$CONFIRMACAO" =~ ^[Yy]$ ]]; then
    echo "❌ Operação cancelada pelo usuário."
    exit 0
fi

# Entra na pasta do terraform se o script for executado da raiz do projeto
if [ -d "terraform" ]; then
    cd terraform
fi

echo "🧹 Limpando planos antigos..."
rm -f destroy_plan.tfplan

echo "📥 Inicializando Provedores Databricks..."
terraform init

# 🚀 MULTIAMBIENTE: Garante a seleção do Workspace do Terraform correspondente para não destruir o ambiente errado
echo "🌐 Alternando para o Workspace do Terraform: ${AMBIENTE}..."
terraform workspace select ${AMBIENTE}

echo "📊 Gerando Plano de Destruição Lógica Analítica..."
# Usa o -var-file correto do ecossistema de consulta
terraform plan -destroy -var-file="$TF_VAR_FILE" -out=destroy_plan.tfplan

echo "💥 Executando o Clean-up Lógico no Databricks..."
terraform apply destroy_plan.tfplan

# Limpeza segura do plano temporário
rm -f destroy_plan.tfplan

echo "====================================================================="
echo "✅ CONCLUÍDO! Componentes analíticos removidos com sucesso!"
echo "👉 O Workspace está limpo para este projeto de consulta."
echo "====================================================================="
