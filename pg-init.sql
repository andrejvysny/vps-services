-- =============================================================================
-- PostgreSQL initialization script for n8n and Postiz
-- =============================================================================
-- This runs once on first boot (when PGDATA is empty)
-- Creates separate databases and users for each application

-- NOTE: Passwords here are placeholders - they get replaced by docker-entrypoint
-- when the actual environment variables are passed through the container.
-- The real passwords come from services/.env

-- Create roles (users)
CREATE ROLE n8n LOGIN PASSWORD 'N8N_DB_PASSWORD_PLACEHOLDER';
CREATE ROLE postiz LOGIN PASSWORD 'POSTIZ_DB_PASSWORD_PLACEHOLDER';

-- Create databases owned by respective users
CREATE DATABASE n8n OWNER n8n;
CREATE DATABASE postiz OWNER postiz;

-- Grant all privileges (redundant with OWNER, but explicit)
GRANT ALL PRIVILEGES ON DATABASE n8n TO n8n;
GRANT ALL PRIVILEGES ON DATABASE postiz TO postiz;
