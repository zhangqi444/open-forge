---
name: digiboard
description: Digiboard recipe for open-forge. Collaborative online whiteboard application from Ladigitale (documentation in French). AGPL-3.0. Source: https://codeberg.org/ladigitale/digiboard
---

# Digiboard

A collaborative online whiteboard application from the Ladigitale suite, designed for educational use. Features real-time multi-user whiteboard drawing and collaboration. Documentation is primarily in French. AGPL-3.0 licensed. Source: <https://codeberg.org/ladigitale/digiboard>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux | Node.js 20+ + Redis 6+ + PM2 | Production deployment (upstream recommended) |
| Any Linux | Node.js 20+ + Redis 6+ (dev) | `npm run dev` — localhost only |
| Docker | Custom | No official Docker image; community Dockerfiles may exist |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain?" | FQDN | e.g. digiboard.example.com |
| "Port?" | Number | Default 3000 |
| "Redis host?" | Host | Default 127.0.0.1 |
| "Redis password?" | Secret or blank | Leave blank if Redis is local and protected by firewall |
| "Behind reverse proxy?" | Yes / No | Sets REVERSE_PROXY=1 |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Node cluster mode?" | Yes / No | NODE_CLUSTER=1 for multi-core |
| "TLS?" | Yes / No | Handled by NGINX/Caddy in front |

## Software-Layer Concerns

- **Node.js 20+ required**: Node.js 18 may work but is not supported upstream.
- **Redis required**: Redis 6+ is mandatory — used for real-time session and board state.
- **PM2 for production**: Upstream recommends PM2 for process management.
- **Environment file**: Create `.env` at project root before starting production server.
- **DOMAIN variable**: Must include protocol (`https://digiboard.example.com`) — used in production only.
- **REVERSE_PROXY=1**: Must be set when behind NGINX/Caddy to pass correct client IPs.
- **French documentation**: Most upstream documentation, comments, and UI are in French.

## Deployment

### 1. Install dependencies

```bash
# Node.js 20+ (via NodeSource)
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

# Redis
apt install -y redis-server
systemctl enable --now redis-server

# PM2
npm install -g pm2
```

### 2. Clone and build

```bash
git clone https://codeberg.org/ladigitale/digiboard.git /opt/digiboard
cd /opt/digiboard
npm install
npm run build
```

### 3. Configure environment

```bash
cat > /opt/digiboard/.env << 'EOF'
DOMAIN=https://digiboard.example.com
PORT=3000
REVERSE_PROXY=1
NODE_CLUSTER=0
DB_HOST=127.0.0.1
DB_PWD=
EOF
```

### 4. Start with PM2

```bash
cd /opt/digiboard
pm2 start ecosystem.config.cjs --env production
pm2 save
pm2 startup
```

### 5. NGINX reverse proxy

```nginx
server {
    listen 443 ssl;
    server_name digiboard.example.com;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## Upgrade Procedure

1. `cd /opt/digiboard && git pull`
2. `npm install` (to pick up any new dependencies)
3. `npm run build`
4. `pm2 restart all`

## Gotchas

- **WebSocket support required**: NGINX must forward WebSocket connections (`Upgrade` + `Connection` headers) — real-time collaboration breaks without this.
- **Redis password optional but recommended**: If Redis is exposed beyond localhost, set a strong `DB_PWD`.
- **DOMAIN must include protocol**: `DOMAIN=https://...` not just the hostname — otherwise production server misconfigures URLs.
- **French-language project**: UI is in French; check upstream for i18n/translation status before deploying for English-speaking users.
- **No official Docker image**: Must build from source; community Docker images may exist but are unofficial.
- **Educational focus**: Designed for classroom use; may lack enterprise authentication features.

## Links

- Source: https://codeberg.org/ladigitale/digiboard
- Website: https://digiboard.app/
- Ladigitale suite: https://ladigitale.dev/
