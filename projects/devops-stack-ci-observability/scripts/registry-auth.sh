#!/usr/bin/env bash
set -euo pipefail

mkdir -p registry/auth

# accept either REGISTRY_PASSWORD or REGISTRY_PASS
REGISTRY_PASSWORD="${REGISTRY_PASSWORD:-${REGISTRY_PASS:-}}"

: "${REGISTRY_USER:?Missing REGISTRY_USER in .env}"
: "${REGISTRY_PASSWORD:?Missing REGISTRY_PASS (or REGISTRY_PASSWORD) in .env}"

# Use a container so the host doesn't need htpasswd installed
docker run --rm --entrypoint htpasswd httpd:2-alpine \
  -Bbn "$REGISTRY_USER" "$REGISTRY_PASSWORD" > registry/auth/htpasswd

chmod 640 registry/auth/htpasswd
echo "Generated registry/auth/htpasswd"
