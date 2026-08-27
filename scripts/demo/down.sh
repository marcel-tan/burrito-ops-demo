#!/usr/bin/env bash
# Tear down every local demo target.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

docker compose -f "${REPO_ROOT}/infra/targets/docker-compose.yml" down -v || true
kind delete cluster --name burrito-ops || true
echo "sandbox torn down"
