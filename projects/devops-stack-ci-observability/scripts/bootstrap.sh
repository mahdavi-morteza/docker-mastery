#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [ ! -f .env ]; then
  echo "❌ .env not found."
  echo "   Run: cp .env.example .env"
  exit 1
fi

# load env
set -a
source .env
set +a

echo "==> Preflight checks..."

# Ensure docker works for current user (common on fresh servers)
if ! docker info >/dev/null 2>&1; then
  echo "❌ Docker is not usable by $(whoami)."
  echo "   If you get permission denied, run:"
  echo "   sudo usermod -aG docker \$USER && newgrp docker"
  exit 1
fi

echo "==> 1) Generate registry auth"
./scripts/registry-auth.sh

echo "==> 2) Start stack"
docker compose up -d

echo "==> 3) Show status"
docker compose ps

cat <<EOF

✅ Stack started.

URLs (via nginx proxy / hosts):
- Gitea:      http://gitea.local
- Jenkins:    http://jenkins.local
- SonarQube:  http://sonarqube.local
- Grafana:    http://grafana.local
- Prometheus: http://prometheus.local

Tip: add this on YOUR machine (/etc/hosts):
<HOST_IP> gitea.local jenkins.local sonarqube.local grafana.local prometheus.local

EOF
