# VPS Services Stack

Docker Swarm stack for VPS services: Traefik, PostgreSQL, n8n, Postiz, and Redis.

## 🚀 Services

| Service | Description | URL |
|---------|-------------|-----|
| **Traefik** | Reverse proxy & SSL/TLS terminator | - |
| **PostgreSQL 17** | Shared database for n8n & Postiz | - |
| **n8n** | Workflow automation platform | https://n8n.vps.andrejvysny.sk |
| **Postiz** | Social media scheduling platform | https://postiz.vps.andrejvysny.sk |
| **Redis** | Caching & queue for Postiz | - |

## 📋 Prerequisites

1. **Docker Swarm** initialized
2. **Overlay network** `vps-public` created:
   ```bash
   docker network create --driver overlay --attachable vps-public
   ```

3. **Data directories** created:
   ```bash
   sudo mkdir -p /mnt/data/{traefik-certificates,traefik-dynamic,postgres/pg}
   sudo mkdir -p /mnt/data/n8n/files
   sudo mkdir -p /mnt/data/postiz/{redis,uploads,config}
   sudo chown -R $USER:$USER /mnt/data/
   ```

## 🔧 Setup

1. **Copy environment template**:
   ```bash
   cp .env.example .env
   ```

2. **Edit secrets**:
   ```bash
   nano .env
   ```
   Required variables:
   - `ACME_EMAIL` - Your email for Let's Encrypt
   - `POSTGRES_SUPERUSER_PASSWORD`
   - `N8N_DB_PASSWORD`
   - `N8N_ENCRYPTION_KEY`
   - `POSTIZ_DB_PASSWORD`
   - `POSTIZ_JWT_SECRET`

3. **Deploy the stack**:
   ```bash
   export $(grep -v '^#' .env | xargs)
   docker stack deploy -c services-stack.merged.yml services-stack
   ```

## 📊 Architecture

```
Internet → Traefik (vps-public)
                 ├─→ n8n:5678 → PostgreSQL (db-internal)
                 └─→ Postiz:5000 → PostgreSQL (db-internal)
                                   └─→ Redis (postiz-internal)
```

### Networks
- **vps-public**: External overlay (Traefik ↔ apps)
- **db-internal**: Overlay (PostgreSQL ↔ n8n, Postiz)
- **postiz-internal**: Overlay (Postiz ↔ Redis)

### Volumes (Bind Mounts)
- `/mnt/data/traefik-certificates` - TLS certificates
- `/mnt/data/postgres/pg` - Shared PostgreSQL data
- `/mnt/data/n8n/files` - n8n workflows & data
- `/mnt/data/postiz/redis` - Redis persistence
- `/mnt/data/postiz/uploads` - Postiz file uploads
- `/mnt/data/postiz/config` - Postiz configuration

## 🛠️ Management

### Check service status
```bash
docker service ls
docker service ps services-stack_n8n
docker service ps services-stack_postiz
```

### View logs
```bash
docker service logs -f services-stack_n8n
docker service logs -f services-stack_postiz
docker service logs -f services-stack_postgres
docker service logs -f services-stack_traefik
```

### Redeploy after changes
```bash
export $(grep -v '^#' .env | xargs)
docker stack deploy -c services-stack.merged.yml services-stack
```

### Remove stack
```bash
docker stack rm services-stack
```

## 🗃️ Database Management

### Connect to PostgreSQL
```bash
docker exec -it $(docker ps -q -f name=services-stack_postgres) \
  psql -U postgres
```

### List databases
```bash
docker exec $(docker ps -q -f name=services-stack_postgres) \
  psql -U postgres -c '\l'
```

### Backup database
```bash
docker exec $(docker ps -q -f name=services-stack_postgres) \
  pg_dump -U n8n n8n > n8n-backup.sql
```

### Restore database
```bash
docker exec -i $(docker ps -q -f name=services-stack_postgres) \
  psql -U n8n n8n < n8n-backup.sql
```

## 🔐 Security

- **Secrets**: Stored in `.env` (never commit this file)
- **TLS/SSL**: Automatic via Let's Encrypt (Traefik)
- **Networks**: Isolated internal networks for database traffic
- **Passwords**: Randomly generated (see `.env.example`)

## 📝 First-Time Setup

### n8n
1. Visit https://n8n.vps.andrejvysny.sk
2. Create owner account
3. Configure workflows and integrations

### Postiz
1. Visit https://postiz.vps.andrejvysny.sk
2. Sign up with email + password
3. Connect social media accounts
4. Create and schedule posts

## 📚 Documentation

- [Deployment Plan](DEPLOYMENT-PLAN.md) - Detailed deployment guide
- [Deployment Result](DEPLOYMENT-RESULT.md) - Latest deployment status

## 🐛 Troubleshooting

### Traefik won't start
- Check ports 80/443 are available: `netstat -tlnp | grep -E ':(80|443)'`
- Verify `vps-public` network exists: `docker network ls | grep vps-public`

### Apps can't connect to PostgreSQL
- Check PostgreSQL is healthy: `docker service ps services-stack_postgres`
- Verify database exists: `docker exec $(docker ps -q -f name=services-stack_postgres) psql -U postgres -c '\l'`

### Certificates not provisioning
- Verify ACME email is set in `.env`
- Check DNS points to your server
- Review Traefik logs: `docker service logs services-stack_traefik`

## 📄 License

This configuration is provided as-is for personal use.

## 👤 Author

Andrej Vyšný
