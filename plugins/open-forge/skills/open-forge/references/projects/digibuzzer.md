---
name: digibuzzer
description: Digibuzzer recipe for open-forge. Virtual game room buzzer application from Ladigitale (documentation in French). Node.js + Redis + PM2. AGPL-3.0. Source: https://codeberg.org/ladigitale/digibuzzer
---

# Digibuzzer

A simple online application to create virtual game rooms around a connected buzzer. Part of the Ladigitale educational suite. Built with Vue.js 3 + Vike (SSR) + Express + Redis. Documentation in French. AGPL-3.0 licensed. Source: <https://codeberg.org/ladigitale/digibuzzer>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux | Node.js 20+ + Redis 6+ + PM2 | Production (upstream recommended) |
| Any Linux | Node.js 20+ + Redis 6+ | `npm run prod` without PM2 |
| Docker | Custom | No official Docker image |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain?" | FQDN | e.g. digibuzzer.example.com |
| "Port?" | Number | Default 3000 |
| "Redis host?" | Host | Default 127.0.0.1 |
| "Redis port?" | Number | Default 6379 |
| "Redis password?" | Secret or blank | Leave blank if local |
| "Behind reverse proxy?" | Yes / No | REVERSE_PROXY=1 |
| "Session secret key?" | Random string | SESSION_KEY — set a strong random value |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Session duration?" | Milliseconds | SESSION_DURATION — e.g. 86400000 (24h) |
| "Node cluster mode?" | Yes / No | NODE_CLUSTER=1 for multi-core |
| "Umami analytics?" | Yes / No | Optional UMAMI_SCRIPT_URL + UMAMI_WEBSITE_ID |

## Software-Layer Concerns

- **Node.js 20+ required**: Vue.js 3 + Vike SSR framework.
- **Redis required**: Session store and game state — Redis 6+ mandatory.
- **SESSION_KEY**: Must be a strong random secret; used by Express Session. If omitted or changed, all active sessions are invalidated.
- **DOMAIN must include protocol**: `https://digibuzzer.example.com` — used in production SSR URL generation.
- **REVERSE_PROXY=1**: Required when behind NGINX/Caddy — passes correct client IPs.
- **WebSocket support**: Real-time buzzer events require WebSocket passthrough in the reverse proxy.

## Deployment

### 1. Install dependencies

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs
apt install -y redis-server
systemctl enable --now redis-server
npm install -g pm2
```

### 2. Clone and build

```bash
git clone https://codeberg.org/ladigitale/digibuzzer.git /opt/digibuzzer
cd /opt/digibuzzer
npm install
npm run build
```

### 3. Configure environment

```bash
cat > /opt/digibuzzer/.env << 'EOF'
DOMAIN=https://digibuzzer.example.com
PORT=3000
REVERSE_PROXY=1
NODE_CLUSTER=0
DB_HOST=127.0.0.1
DB_PWD=
DB_PORT=6379
SESSION_KEY=change-this-to-a-strong-random-secret
SESSION_DURATION=86400000
EOF
```

### 4. Start with PM2

```bash
cd /opt/digibuzzer
pm2 start ecosystem.config.cjs --env production
pm2 save
pm2 startup
```

### 5. NGINX reverse proxy

```nginx
server {
    listen 443 ssl;
    server_name digibuzzer.example.com;

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

1. `cd /opt/digibuzzer && git pull`
2. `npm install`
3. `npm run build`
4. `pm2 restart all`

## Gotchas

- **SESSION_KEY must be set**: Without it, Express Session uses an insecure default. Set a strong random value and keep it consistent across restarts.
- **WebSocket passthrough**: NGINX must forward Upgrade/Connection headers for real-time buzzer functionality.
- **Redis password**: If Redis listens on a non-loopback address, always set `DB_PWD`.
- **French-language project**: UI and docs are in French; check upstream for i18n status.
- **No official Docker image**: Build from source only.

## Links

- Source: https://codeberg.org/ladigitale/digibuzzer
- Website: https://digibuzzer.app/
- Ladigitale suite: https://ladigitale.dev/
