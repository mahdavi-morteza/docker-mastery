#!/usr/bin/env bash
set -e

# This script runs automatically on first Postgres initialization.

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
  -- Gitea DB + user
  CREATE USER gitea WITH ENCRYPTED PASSWORD '${GITEA_DB_PASSWORD}';
  CREATE DATABASE gitea OWNER gitea;

  -- SonarQube DB + user
  CREATE USER sonarqube WITH ENCRYPTED PASSWORD '${SONAR_DB_PASSWORD}';
  CREATE DATABASE sonarqube OWNER sonarqube;
EOSQL
