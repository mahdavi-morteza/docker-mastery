#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

if [ ! -f .env ]; then
  echo "❌ .env not found. Run: cp .env.example .env"
  exit 1
fi

# load env
set -a
source .env
set +a

echo "==> Generating registry auth..."
./scripts/registry-auth.sh

echo "==> Starting stack..."
docker compose up -d

echo "==> Waiting for core services..."
docker compose ps

cat <<'EOF'

✅ Stack started.

Next steps (first-run UI):
1) Gitea: http://gitea.local (create org/users/repo OR use your own workflow)
2) Jenkins: http://jenkins.local (create pipeline + add credentials)
3) SonarQube: http://sonarqube.local (create token for Jenkins)

Tip: Add to /etc/hosts:
<HOST_IP> gitea.local jenkins.local sonarqube.local grafana.local prometheus.local

EOF
