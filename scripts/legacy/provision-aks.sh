#!/usr/bin/env bash
# BurritoWorks platform provisioning -- the way it has always been done.
#
# Run from a jump box with `az login` already done as the platform admin.
# Takes ~40 minutes and has to be babysat: if it fails halfway the resources it
# already created stay behind and the next run errors on "already exists".
#
# Usage: ./provision-aks.sh <dev|staging|prod>
set -e

ENVIRONMENT="$1"

# --- copy of common-env.sh, edited for the 2023 region move ------------------
TENANT_ID="72f988bf-2222-41af-91ab-2d7cd011db47"
LOCATION="eastus2"
RG_PREFIX="rg-burritoworks-platform"

if [ "$ENVIRONMENT" = "dev" ]; then
  SUBSCRIPTION="6f9d1c2a-1111-4c3e-9d55-3a1f0b7c4d01"
  VNET_CIDR="10.40.0.0/16"
  AKS_SUBNET="10.40.1.0/24"
  DATA_SUBNET="10.40.2.0/24"
  K8S_VERSION="1.27.9"
  SYSTEM_COUNT=1
  SYSTEM_SIZE="Standard_D2s_v3"
  APPS_COUNT=2
  APPS_SIZE="Standard_D2s_v3"
  SKU_TIER="free"
elif [ "$ENVIRONMENT" = "staging" ]; then
  SUBSCRIPTION="6f9d1c2a-1111-4c3e-9d55-3a1f0b7c4d02"
  VNET_CIDR="10.50.0.0/16"
  AKS_SUBNET="10.50.1.0/24"
  DATA_SUBNET="10.50.2.0/24"
  K8S_VERSION="1.28.5"
  SYSTEM_COUNT=2
  SYSTEM_SIZE="Standard_D2s_v3"
  APPS_COUNT=3
  APPS_SIZE="Standard_D4s_v3"
  SKU_TIER="standard"
elif [ "$ENVIRONMENT" = "prod" ]; then
  SUBSCRIPTION="6f9d1c2a-1111-4c3e-9d55-3a1f0b7c4d03"
  VNET_CIDR="10.60.0.0/16"
  AKS_SUBNET="10.60.1.0/24"
  DATA_SUBNET="10.60.2.0/24"
  K8S_VERSION="1.26.10"
  SYSTEM_COUNT=3
  SYSTEM_SIZE="Standard_D4s_v3"
  APPS_COUNT=6
  APPS_SIZE="Standard_D8s_v3"
  SKU_TIER="standard"
else
  echo "usage: $0 <dev|staging|prod>"
  exit 1
fi

RG="${RG_PREFIX}-${ENVIRONMENT}"
SUFFIX="${ENVIRONMENT}-${LOCATION}"

az account set --subscription "$SUBSCRIPTION"

echo "creating resource group"
az group create --name "$RG" --location "$LOCATION" \
  --tags environment="$ENVIRONMENT" owner=platform-engineering

echo "creating network"
az network vnet create --resource-group "$RG" --name "vnet-${SUFFIX}" \
  --address-prefix "$VNET_CIDR" --subnet-name snet-aks --subnet-prefix "$AKS_SUBNET"
az network vnet subnet create --resource-group "$RG" --vnet-name "vnet-${SUFFIX}" \
  --name snet-data --address-prefix "$DATA_SUBNET"
az network nsg create --resource-group "$RG" --name "nsg-aks-${SUFFIX}"
az network nsg rule create --resource-group "$RG" --nsg-name "nsg-aks-${SUFFIX}" \
  --name allow-https-ingress --priority 200 --direction Inbound --access Allow \
  --protocol Tcp --destination-port-ranges 443 --source-address-prefixes 10.0.0.0/8 198.51.100.0/24
if [ "$ENVIRONMENT" = "prod" ]; then
  # added during the 2024 promo incident for the vendor load generator
  az network nsg rule create --resource-group "$RG" --nsg-name "nsg-aks-${SUFFIX}" \
    --name allow-promo-loadtest --priority 150 --direction Inbound --access Allow \
    --protocol Tcp --destination-port-ranges 443 --source-address-prefixes 0.0.0.0/0
fi
az network vnet subnet update --resource-group "$RG" --vnet-name "vnet-${SUFFIX}" \
  --name snet-aks --network-security-group "nsg-aks-${SUFFIX}"

SUBNET_ID=$(az network vnet subnet show --resource-group "$RG" \
  --vnet-name "vnet-${SUFFIX}" --name snet-aks --query id -o tsv)

echo "creating aks"
az aks create --resource-group "$RG" --name "aks-${SUFFIX}" \
  --kubernetes-version "$K8S_VERSION" --tier "$SKU_TIER" \
  --node-count "$SYSTEM_COUNT" --node-vm-size "$SYSTEM_SIZE" --nodepool-name system \
  --max-pods 60 --vnet-subnet-id "$SUBNET_ID" --enable-managed-identity \
  --dns-name-prefix "bw-${SUFFIX}" --generate-ssh-keys \
  --tags environment="$ENVIRONMENT" owner=platform-engineering
az aks nodepool add --resource-group "$RG" --cluster-name "aks-${SUFFIX}" \
  --name apps --node-count "$APPS_COUNT" --node-vm-size "$APPS_SIZE" \
  --vnet-subnet-id "$SUBNET_ID"

echo "creating storage"
STORAGE="stbwplatform${ENVIRONMENT}"
if [ "$ENVIRONMENT" = "staging" ]; then STORAGE="stbwplatformstg"; fi
az storage account create --resource-group "$RG" --name "$STORAGE" \
  --location "$LOCATION" --sku Standard_LRS --min-tls-version TLS1_2
az storage container create --account-name "$STORAGE" --name receipts --public-access off
az storage container create --account-name "$STORAGE" --name menu-assets --public-access blob

echo "creating key vault"
KV="kv-bw-platform-${ENVIRONMENT}"
if [ "$ENVIRONMENT" = "staging" ]; then KV="kv-bw-platform-stg"; fi
az keyvault create --resource-group "$RG" --name "$KV" --location "$LOCATION" \
  --sku standard
az keyvault secret set --vault-name "$KV" --name sql-admin-password --value "Guac4Ever!Prod2024"
az keyvault secret set --vault-name "$KV" --name payments-api-key --value "pk_live_51NqXbW9prod000000000000000"

echo "done. remember to update the wiki page with the new resource ids."
