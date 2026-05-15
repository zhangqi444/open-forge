# Plausible Analytics (Community Edition)

Lightweight, privacy-friendly web analytics. Plausible Community Edition (CE) is the self-hosted version of Plausible Analytics — a simple, open-source alternative to Google Analytics. No cookies, GDPR/CCPA compliant by design, under 1 KB script, no cross-site tracking.

**Official site:** https://plausible.io  
**Source:** https://github.com/plausible/analytics  
**Self-host repo:** https://github.com/plausible/community-edition  
**Upstream docs:** https://plausible.io/docs/self-hosting  
**License:** AGPL-3.0

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Docker Compose | Primary self-hosted method |

---

## Inputs to Collect

### Required
| Variable | Description | Example |
|----------|-------------|---------|
| `BASE_URL` | Public URL of your Plausible instance | `https://plausible.example.com` |
| `SECRET_KEY_BASE` | Phoenix secret key | `$(openssl rand -base64 48)` |

### Optional
| Variable | Description |
|----------|-------------|
| `HTTP_PORT` | Host HTTP port (enables auto-TLS if set to 80) | `80` |
| `HTTPS_PORT` | Host HTTPS port (enables auto-TLS if set to 443) | `443` |
| `DISABLE_REGISTRATION` | Prevent new user signups | `true` |
| `TOTP_VAULT_KEY` | Key for encrypting TOTP secrets | `$(openssl rand -base64 32)` |

---

## Software-Layer Concerns

### Quick start
```sh
git clone -b v3.2.1 --single-branch https://github.com/plausible/community-edition plausible-ce
cd plausible-ce

# Create .env
echo "BASE_URL=https://plausible.example.com" >> .env
echo "SECRET_KEY_BASE=$(openssl rand -base64 48)" >> .env

# Expose on ports 80/443 with auto-TLS
echo "HTTP_PORT=80" >> .env
echo "HTTPS_PORT=443" >> .env
cat > compose.override.yml << 'EOF'
services:
  plausible:
    ports:
      - 80:80
      - 443:443
EOF

docker compose up -d
```

Visit `$BASE_URL` and create the first user account.

### Services
| Service | Image | Role |
|---------|-------|------|
| `plausible` | `ghcr.io/plausible/community-edition:v3.2.1` | Main app server |
| `plausible_db` | `postgres:16-alpine` | User data and site config |
| `plausible_events_db` | `clickhouse/clickhouse-server:24.3.3.102-alpine` | Event data (pageviews, etc.) |

### Hardware requirements
- CPU must support **SSE 4.2** or **NEON** (required by ClickHouse)
- At least **2 GB RAM** recommended (ClickHouse is memory-hungry)

### Tracking snippet
Add to each page you want to track:
```html
<script defer data-domain="yourdomain.com" src="https://plausible.example.com/js/script.js"></script>
```

### Behind a reverse proxy
If using nginx/Traefik in front of Plausible:
1. Do NOT set `HTTP_PORT`/`HTTPS_PORT` in `.env`
2. Proxy to container port `8000`
3. See: https://github.com/plausible/community-edition/wiki/reverse-proxy

---

## Upgrade Procedure

1. Pull the new CE release tag:
   ```sh
   git pull
   git checkout v<new-version>
   ```
2. Update image tag in `.env` or `compose.yml`
3. `docker compose pull && docker compose up -d`
4. Migrations run automatically on startup
5. Check: https://github.com/plausible/analytics/releases

---

## Gotchas

- **ClickHouse requires SSE 4.2 / NEON** — modern CPUs are fine; very old VMs or some ARM boards may fail to start ClickHouse
- **AGPL-3.0 license** — modifications must be open-sourced if offered as a network service
- **Two databases required** — Postgres stores users/config; ClickHouse stores all event data; both must be backed up
- **Pin to a release tag** — always clone a specific version tag (`-b v3.2.1`) rather than `main`; `main` may be unstable
- **DISABLE_REGISTRATION** — set to `true` after creating your account to prevent unauthorized signups on public instances
- **SECRET_KEY_BASE must not change** — changing it invalidates all active sessions and API keys

---

## Links
- Self-host repo (CE): https://github.com/plausible/community-edition
- Main source: https://github.com/plausible/analytics
- Self-hosting docs: https://plausible.io/docs/self-hosting
- Configuration wiki: https://github.com/plausible/community-edition/wiki/configuration
- Reverse proxy guide: https://github.com/plausible/community-edition/wiki/reverse-proxy
