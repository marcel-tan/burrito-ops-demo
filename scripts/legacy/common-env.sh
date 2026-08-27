#!/usr/bin/env bash
# Shared environment block. Copied into each provisioning script years ago and
# then edited in place, so the copies below no longer match this file.
# shellcheck disable=SC2034

SUBSCRIPTION_DEV="6f9d1c2a-1111-4c3e-9d55-3a1f0b7c4d01"
SUBSCRIPTION_STG="6f9d1c2a-1111-4c3e-9d55-3a1f0b7c4d02"
SUBSCRIPTION_PRD="6f9d1c2a-1111-4c3e-9d55-3a1f0b7c4d03"
TENANT_ID="72f988bf-2222-41af-91ab-2d7cd011db47"

LOCATION="eastus2"
RG_PREFIX="rg-burritoworks-platform"
AKS_PREFIX="aks"
STORAGE_PREFIX="stbwplatform"
KV_PREFIX="kv-bw-platform"

# used by provision-aks.sh and deploy-service.sh
SP_APP_ID="8f21a4dd-3333-4b8e-9dd0-9ac4e2f0a111"
SP_SECRET="Zx8Q~burritoworks-sp-secret-do-not-share"
ACR_NAME="acrburritoworks"
