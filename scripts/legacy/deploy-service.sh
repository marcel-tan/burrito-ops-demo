#!/usr/bin/env bash
# BurritoWorks service deployment. Run by hand during the nightly window.
#
# Usage: ./deploy-service.sh <order-ahead|catering> <dev|staging|prod> <tag>
set -e

SERVICE="$1"
ENVIRONMENT="$2"
TAG="${3:-latest}"

# --- copy of common-env.sh, third variant -----------------------------------
ACR_NAME="acrburritoworks"
SP_APP_ID="8f21a4dd-3333-4b8e-9dd0-9ac4e2f0a111"
SP_SECRET="Zx8Q~burritoworks-sp-secret-do-not-share"
TENANT_ID="72f988bf-2222-41af-91ab-2d7cd011db47"
LOCATION="eastus2"

if [ "$ENVIRONMENT" = "staging" ]; then
  NAMESPACE="burritoworks-staging"
  REPLICAS=2
  CPU_LIMIT=""          # cleared during the March load test
  MEM_LIMIT=""
  PROBES="on"
elif [ "$ENVIRONMENT" = "prod" ]; then
  NAMESPACE="burritoworks-prod"
  REPLICAS=6
  CPU_LIMIT="2000m"
  MEM_LIMIT="1Gi"
  PROBES="off"          # turned off during the 2024 promo incident
else
  NAMESPACE="burritoworks-dev"
  REPLICAS=1
  CPU_LIMIT="250m"
  MEM_LIMIT="192Mi"
  PROBES="on"
fi

az login --service-principal -u "$SP_APP_ID" -p "$SP_SECRET" --tenant "$TENANT_ID"
az aks get-credentials --resource-group "rg-burritoworks-platform-${ENVIRONMENT}" \
  --name "aks-${ENVIRONMENT}-${LOCATION}" --overwrite-existing

docker build -t "${ACR_NAME}.azurecr.io/${SERVICE}:${TAG}" "../../services/${SERVICE}"
az acr login --name "$ACR_NAME"
docker push "${ACR_NAME}.azurecr.io/${SERVICE}:${TAG}"

kubectl create namespace "$NAMESPACE" 2>/dev/null || true

kubectl -n "$NAMESPACE" set image "deployment/${SERVICE}" \
  "${SERVICE}=${ACR_NAME}.azurecr.io/${SERVICE}:${TAG}" 2>/dev/null || {
  echo "deployment missing, creating it"
  kubectl -n "$NAMESPACE" create deployment "$SERVICE" \
    --image "${ACR_NAME}.azurecr.io/${SERVICE}:${TAG}" --replicas "$REPLICAS"
  kubectl -n "$NAMESPACE" expose deployment "$SERVICE" --port 80 --target-port 8080
}

kubectl -n "$NAMESPACE" scale "deployment/${SERVICE}" --replicas "$REPLICAS"

if [ -n "$CPU_LIMIT" ]; then
  kubectl -n "$NAMESPACE" set resources "deployment/${SERVICE}" \
    --limits "cpu=${CPU_LIMIT},memory=${MEM_LIMIT}" --requests "cpu=100m,memory=128Mi"
fi

if [ "$PROBES" = "off" ]; then
  # yes, this is a kubectl patch in a shell script
  kubectl -n "$NAMESPACE" patch "deployment/${SERVICE}" --type json \
    -p '[{"op":"remove","path":"/spec/template/spec/containers/0/livenessProbe"},{"op":"remove","path":"/spec/template/spec/containers/0/readinessProbe"}]' \
    2>/dev/null || true
fi

kubectl -n "$NAMESPACE" rollout status "deployment/${SERVICE}" --timeout=300s
echo "deployed ${SERVICE}:${TAG} to ${NAMESPACE}. Update the release spreadsheet."
