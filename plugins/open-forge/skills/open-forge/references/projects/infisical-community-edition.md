# Infisical Community Edition

Open-source secrets management platform. Infisical is a self-hosted alternative to HashiCorp Vault and Doppler for storing and syncing environment variables and secrets. Features secret versioning, audit logs, role-based access, dynamic secrets, and native integrations with GitHub, GitLab, AWS, Kubernetes, and more.

**Official site:** https://infisical.com  
**Source:** https://github.com/Infisical/infisical  
**Upstream docs:** https://infisical.com/docs/self-hosting/overview  
**License:** MIT

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Docker Compose | Primary self-hosted method |
| Kubernetes | Helm chart | Official chart available |

---

## Inputs to Collect

### Required
| Variable | Description | Example |
|----------|-------------|---------|
| `ENCRYPTION_KEY` | 16-byte hex key for platform encryption | `f13dbc92aaaf86fa7cb0ed8ac3265f47` (generate fresh) |
| `AUTH_SECRET` | Base64 JWT signing secret | `$(openssl rand -base64 32)` |
| `SITE_URL` | Public URL of your Infisical instance | `https://secrets.example.com` |
| `DB_CONNECTION_URI` | PostgreSQL connection string | `postgres://infisical:password@db:5432/infisical` |
| `REDIS_URL` | Redis connection string | `redis://redis:6379` |

### Optional — SMTP (email invites, MFA)
| Variable | Description |
|----------|-------------|
| `SMTP_HOST` | SMTP server hostname |
| `SMTP_PORT` | SMTP port |
| `SMTP_FROM_ADDRESS` | From address for emails |
| `SMTP_USERNAME` / `SMTP_PASSWORD` | SMTP credentials |

---

## Software-Layer Concerns

### Docker Compose
```yaml
version: "3"
services:
  backend:
    image: infisical/infisical:latest
    restart: unless-stopped
    env_file: .env
    ports:
      - 80:8080
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_started
    environment:
      - NODE_ENV=production
    networks:
      - infisical

  redis:
    image: redis
    restart: always
    environment:
      - ALLOW_EMPTY_PASSWORD=yes
    volumes:
      - redis_data:/data
    networks:
      - infisical

  db:
    image: postgres:14-alpine
    restart: always
    env_file: .env
    volumes:
      - pg_data:/var/lib/postgresql/data
    healthcheck:
      test: "pg_isready --username=${POSTGRES_USER} && psql --username=${POSTGRES_USER} --list"
      interval: 5s
      timeout: 10s
      retries: 10
    networks:
      - infisical

volumes:
  pg_data:
  redis_data:

networks:
  infisical:
```

### .env file
```env
ENCRYPTION_KEY=f13dbc92aaaf86fa7cb0ed8ac3265f47   # CHANGE THIS
AUTH_SECRET=your-base64-secret-here               # CHANGE THIS
SITE_URL=https://secrets.example.com

POSTGRES_USER=infisical
POSTGRES_PASSWORD=strongpassword
POSTGRES_DB=infisical
DB_CONNECTION_URI=postgres://infisical:strongpassword@db:5432/infisical

REDIS_URL=redis://redis:6379
```

Generate secrets:
```sh
openssl rand -hex 16       # ENCRYPTION_KEY
openssl rand -base64 32    # AUTH_SECRET
```

### Initial setup
After starting the stack, visit `http://<host>` to create your admin account. DB migrations run automatically on first start.

### Secret sync integrations
Configure integrations (GitHub Actions, AWS SSM, Kubernetes) in the Infisical dashboard. Each integration requires OAuth credentials configured per-project.

---

## Upgrade Procedure

1. Pull latest image: `docker compose pull`
2. Restart: `docker compose up -d`
3. Migrations run automatically on startup
4. Check release notes: https://github.com/Infisical/infisical/releases

---

## Gotchas

- **ENCRYPTION_KEY cannot be changed after deployment** — all secrets are encrypted with this key; losing or rotating it means losing access to all stored secrets. Back it up securely.
- **Default sample keys are public** — the `.env.example` shows sample keys; never use them in production
- **Pin to a specific image tag** — `infisical/infisical:latest` is convenient but can pull breaking changes; pin to a version tag for production (e.g., `infisical/infisical:0.82.0`)
- **PostgreSQL 14+ recommended** — older versions may work but are untested
- **SMTP optional but recommended** — without SMTP, user invitations and MFA email delivery won't work; users can still be added manually via the dashboard

---

## Links
- Upstream README: https://github.com/Infisical/infisical
- Self-hosting docs: https://infisical.com/docs/self-hosting/overview
- Docker Compose guide: https://infisical.com/docs/self-hosting/deployment-options/docker-compose
- Secret sync integrations: https://infisical.com/docs/integrations/overview
