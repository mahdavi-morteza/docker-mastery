#!/usr/bin/env bash
set -euo pipefail
mkdir -p registry/auth
htpasswd -Bbn "${REGISTRY_USER}" "${REGISTRY_PASSWORD}" > registry/auth/htpasswd
echo "Generated registry/auth/htpasswd"
