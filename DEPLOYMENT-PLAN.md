# 🚀 Services Stack Deployment Plan

## ✅ Step 1 Complete: Secrets Generated

### Generated Files
- ✅ `services/.env` - Contains all secrets (DO NOT COMMIT)
- ✅ `services/.env.example` - Template for documentation
- ✅ `services/.gitignore` - Prevents accidental commit of .env
- ✅ `services/pg-init.sh` - Fixed PostgreSQL init script
- ✅ `services/services-stack.merged.yml` - Updated with ${VAR} references

### Generated Secrets (in services/.env)
```
✅ POSTGRES_SUPERUSER_PASSWORD (32 chars)
✅ N8N_DB_PASSWORD (32 chars)
✅ N8N_ENCRYPTION_KEY (base64, 32 bytes)
✅ POSTIZ_DB_PASSWORD (32 chars)
✅ POSTIZ_JWT_SECRET (64 chars)
```

### ⚠️ TODO: Set Your Email
Edit `services/.env` and replace:
```bash
ACME_EMAIL=your-email@example.com
```
with your real email for Let's Encrypt notifications.

---

## 📋 Step 2: Review & Pre-Deployment Checklist

### Before deploying, you must:

#### 1. **Create all bind mount directories**
```bash
sudo mkdir -p /mnt/data/traefik-certificates
sudo mkdir -p /mnt/data/traefik-dynamic
sudo mkdir -p /mnt/data/postgres/pg
sudo mkdir -p /mnt/data/n8n/files
sudo mkdir -p /mnt/data/postiz/redis
sudo mkdir -p /mnt/data/postiz/uploads
sudo mkdir -p /mnt/data/postiz/config

# Set ownership (optional, depending on your setup)
sudo chown -R $(id -u):$(id -g) /mnt/data/
```

#### 2. **Verify `vps-public` network exists**
```bash
docker network ls | grep vps-public
```

If not found:
```bash
docker network create --driver overlay --attachable vps-public
```

#### 3. **Verify Traefik dynamic config directory**
Check if `/mnt/data/traefik-dynamic/` has any config files. If empty, Traefik will start but may not route correctly. You can create a minimal placeholder:

```bash
cat > /mnt/data/traefik-dynamic/empty.yml << 'EOF'
# Placeholder - add dynamic configs here if needed
http:
  routers: {}
EOF
```

#### 4. **Review Postiz `BACKEND_INTERNAL_URL`**
Currently set to `http://localhost:3000`. Verify this is correct by checking Postiz documentation. If Postiz runs frontend+backend in separate processes within the same container, this might be fine. Otherwise, change to:
```yaml
BACKEND_INTERNAL_URL: "http://services-stack_postiz:5000"
```

---

## 🗑️ Step 3: Destructive Teardown (When Ready)

**⚠️ WARNING: This will DELETE all existing data!**

Run these commands when ready to proceed:

```bash
# 1. Remove old stacks (if they exist)
docker stack rm n8n-stack || true
docker stack rm postiz-stack || true
docker stack rm services-stack || true

# Wait for stacks to fully shut down
sleep 30

# 2. Delete old bind-mount data
sudo rm -rf /mnt/data/n8n/*
sudo rm -rf /mnt/data/postiz/*

# Recreate directories
sudo mkdir -p /mnt/data/n8n/files
sudo mkdir -p /mnt/data/postiz/{redis,uploads,config}

# 3. Clean up unused volumes and images (optional)
docker volume prune -f
docker image prune -af
```

---

## 🚀 Step 4: Deploy the Stack

```bash
cd ~/path/to/your/services/  # Where services-stack.merged.yml is

# Load environment variables and deploy
docker stack deploy -c services-stack.merged.yml --env-file .env services-stack
```

### Monitor Deployment
```bash
# Watch services come up
watch -n2 'docker service ls | grep services-stack'

# Check logs for each service
docker service logs -f services-stack_postgres
docker service logs -f services-stack_n8n
docker service logs -f services-stack_postiz
docker service logs -f services-stack_traefik
```

### Verify Health
```bash
# Check all services are running (1/1 replicas)
docker service ls

# Check PostgreSQL databases were created
docker exec -it $(docker ps -q -f name=services-stack_postgres) psql -U postgres -c '\l'
# Should show: n8n and postiz databases

# Check Traefik routes
curl -k https://n8n.vps.andrejvysny.sk
curl -k https://postiz.vps.andrejvysny.sk
```

---

## 🔧 Post-Deployment

### Access Services
- **n8n**: https://n8n.vps.andrejvysny.sk
- **Postiz**: https://postiz.vps.andrejvysny.sk

### First-Time Setup
1. **n8n**: Create your owner account on first visit
2. **Postiz**: Follow initial setup wizard

### Troubleshooting
```bash
# If services fail to start, check logs
docker service logs services-stack_postgres --tail 100
docker service logs services-stack_n8n --tail 100
docker service logs services-stack_postiz --tail 100

# If Traefik can't reach services
docker network inspect vps-public
docker network inspect services-stack_db-internal
```

---

## 📝 Architecture Summary

```
┌─────────────────────────────────────────┐
│          Traefik (vps-public)           │
│  ┌─────────────┐      ┌──────────────┐  │
│  │ n8n:5678    │      │ postiz:5000  │  │
│  └──────┬──────┘      └──────┬───────┘  │
└─────────┼───────────────────┼───────────┘
          │                   │
          │                   │
     ┌────▼────┐         ┌────▼────┐
     │   n8n   │         │ Postiz  │
     │ service │         │ service │
     └────┬────┘         └────┬────┘
          │                   │
          │    db-internal    │
          │   ┌───────────┐   │
          └───►  Postgres ◄───┘
              │  (17-alp) │
              └───────────┘
                  │
                  ├─ DB: n8n (user: n8n)
                  └─ DB: postiz (user: postiz)

              ┌──────────┐
              │  Redis   │ (postiz-internal)
              └──────────┘
```

### Networks
- **vps-public** (external): Traefik ↔ n8n, Postiz
- **db-internal** (overlay): Postgres ↔ n8n, Postiz
- **postiz-internal** (overlay): Postiz ↔ Redis

### Volumes (bind mounts)
- `/mnt/data/traefik-certificates` → TLS certs
- `/mnt/data/postgres/pg` → Shared PGDATA
- `/mnt/data/n8n/files` → n8n workflows
- `/mnt/data/postiz/{redis,uploads,config}` → Postiz data

---

## 🎯 What Changed from Original Plan

### Fixed Issues
1. ✅ **PostgreSQL init script** - Changed from `.sql` to `.sh` to properly handle environment variable passwords
2. ✅ **Password consistency** - All passwords now flow from `.env` → YAML → init script
3. ✅ **Removed hardcoded secrets** - All sensitive values use `${VAR:?error}` syntax
4. ✅ **Added .gitignore** - Prevents committing `.env`

### Architecture Notes
- Kept `BACKEND_INTERNAL_URL: "http://localhost:3000"` - verify if correct for Postiz
- Service naming is correct (`services-stack_postgres`, etc.)
- Traefik labels look good (both n8n and Postiz)
- Health checks are properly configured

---

## 🤔 Ready to Proceed?

Reply with:
- **REVIEW ONLY** - I'll stop here, you review the files
- **PROCEED** - I'll execute Steps 3 & 4 (destructive teardown + deploy)
- **WAIT** - You have questions/changes first
