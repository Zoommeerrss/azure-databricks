#!/bin/bash

# Captura o primeiro argumento passado no terminal (ex: ./infra-reset.sh dev)
AMBIENTE=$1

if [ "$AMBIENTE" != "dev" ] && [ "$AMBIENTE" != "main" ]; then
    echo "❌ Erro: Você deve especificar qual ambiente deseja DESTRUIR!"
    echo "Uso correto: $0 [dev|main]"
    exit 1
fi

if [ "$AMBIENTE" == "main" ]; then
    BRANCH="main"
    ENV_SUFIXO="prod" 
else
    BRANCH="dev"
    ENV_SUFIXO="dev"
fi

echo "====================================================================="
echo "💣 PERIGO: INICIANDO DESTRUIÇÃO DO AMBIENTE = ${AMBIENTE^^}"
echo "====================================================================="

echo "🏗️ Alinhando travas de plugins locais..."
terraform init -backend=false || true

echo "🗑️ 1/3: Executando Terraform Destroy COM ESTADO ATIVO..."
# O estado PRECISA estar vivo aqui para o Terraform se autenticar no Databricks
# e remover as travas de rede e exclusão do cluster antes que o grupo caia.
if terraform destroy -auto-approve -var="environment=${AMBIENTE}" -var="git_branch=${BRANCH}"; then
    echo "✅ Terraform destroy concluído com sucesso."
else
    echo "⚠️ Terraform destroy falhou ou encontrou travas lógicas. Avançando para limpeza via CLI..."
fi

# ==============================================================================
# FORÇA BRUTA - AZURE CLI (Limpeza Inteligente Síncrona)
# ==============================================================================
RG_PRINCIPAL="rg-auditoria-${ENV_SUFIXO}"
RG_DATABRICKS_LAB="rg-databricks-lab"
RG_NETWORK_WATCHER="NetworkWatcherRG"

echo "🔥 2/3: Forçando exclusão dos Grupos de Recursos válidos via Azure CLI..."

# Executa sem o --no-wait. O terminal aguardará a Azure confirmar a remoção completa.
echo "👉 Deletando Grupo Principal (e limpando dependências do Databricks): $RG_PRINCIPAL"
az group delete --name "$RG_PRINCIPAL" --yes

# 🔥 ADICIONADO: Garante que o grupo fixo de computação do laboratório seja removido se ainda existir
echo "👉 Deletando Grupo de Computação Gerenciado: $RG_DATABRICKS_LAB"
az group delete --name "$RG_DATABRICKS_LAB" --yes || true

# Remove o Network Watcher automático da assinatura
echo "👉 Deletando Grupo do Network Watcher: $RG_NETWORK_WATCHER"
az group delete --name "$RG_NETWORK_WATCHER" --yes || true

echo "⏳ Aguardando 20 segundos adicionais para expiração total de tokens na nuvem..."
sleep 20

# ==============================================================================
# LIMPEZA LOCAL DE METADADOS (O ÚLTIMO PASSO)
# ==============================================================================
echo "🧹 3/3: Limpando caches, travas de lock e históricos locais (.tfstate)..."
# Mover esses comandos para cá garante que o estado local só suma DEPOIS que a Azure limpou tudo.
rm -f *.tfplan
rm -rf .terraform/
rm -rf ~/.terraform.d/plugin-cache/
rm -f terraform.tfstate*
rm -f .terraform.lock.hcl

echo "====================================================================="
echo "💥 CONCLUÍDO! O ambiente de ${AMBIENTE^^} foi 100% varrido da nuvem!"
echo "====================================================================="
