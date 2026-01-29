#!/bin/bash
# =============================================================================
# PostgreSQL initialization script for n8n and Postiz
# =============================================================================
# This runs once on first boot (when PGDATA is empty)
# Creates separate databases and users with passwords from environment

set -e

# Read passwords from environment (passed by Docker)
N8N_PASS="${N8N_DB_PASSWORD:?N8N_DB_PASSWORD must be set}"
POSTIZ_PASS="${POSTIZ_DB_PASSWORD:?POSTIZ_DB_PASSWORD must be set}"
TEMPORAL_PASS="${TEMPORAL_DB_PASSWORD:-${POSTIZ_DB_PASSWORD}}"

echo "Creating n8n database and user..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE ROLE n8n LOGIN PASSWORD '$N8N_PASS';
    CREATE DATABASE n8n OWNER n8n;
    GRANT ALL PRIVILEGES ON DATABASE n8n TO n8n;
EOSQL

echo "Creating postiz database and user..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE ROLE postiz LOGIN PASSWORD '$POSTIZ_PASS';
    CREATE DATABASE postiz OWNER postiz;
    GRANT ALL PRIVILEGES ON DATABASE postiz TO postiz;
EOSQL

echo "Creating temporal database and user..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE ROLE temporal LOGIN PASSWORD '$TEMPORAL_PASS';
    CREATE DATABASE temporal OWNER temporal;
    GRANT ALL PRIVILEGES ON DATABASE temporal TO temporal;
EOSQL

echo "PostgreSQL initialization complete."
