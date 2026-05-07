---
name: digiwall
description: Digiwall recipe for open-forge. Collaborative multimedia wall for in-person or remote work. Node.js 20+ + Redis + GraphicsMagick + Ghostscript + LibreOffice + optional PostgreSQL. Heavy system dependencies. From Ladigitale (documentation in French). AGPL-3.0. Source: https://codeberg.org/ladigitale/digiwall
---

# Digiwall

An online collaborative multimedia wall application for in-person or remote collaboration. Part of the Ladigitale educational suite and a close sibling to Digipad. Features file uploads (images, video, audio, PDFs, Office docs), real-time collaboration, and optional PostgreSQL offloading for Redis. Requires Node.js 20+, Redis, GraphicsMagick, Ghostscript, and LibreOffice. AGPL-3.0 licensed. Source: <https://codeberg.org/ladigitale/digiwall>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux | Node.js 20+ + Redis 6+ + PM2 + system deps | Production (upstream recommended) |
| Any Linux + PostgreSQL | Node.js 20+ + Redis + PostgreSQL | Optional: offload Redis data to PostgreSQL |
| Docker | Custom | No official Docker image; all system deps required in image |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain?" | FQDN | e.g. digiwall.example.com |
| "Port?" | Number | Default 3000 |
| "Redis host?" | Host | Default localhost |
| "Redis port?" | Number | Default 6379 |
| "Redis password?" | Secret or blank | Set if Redis not on loopback |
| "Session secret key?" | Random string | SESSION_KEY — strong random value |
| "Admin password?" | Secret | ADMIN_PASSWORD — for /admin page |
| "Behind reverse proxy?" | Yes / No | REVERSE_PROXY=1 |
| "Use PostgreSQL?" | Yes / No | PG_DB=1 — optional Redis offload |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Allow account creation?" | Yes / No | VITE_CREATE_ACCOUNT=1 |
| "Allow walls without account?" | Yes / No | VITE_WALL_WITHOUT_ACCOUNT=1 |
| "Max walls per user?" | Number | VITE_WALL_LIMIT |
| "Upload limit per file?" | MB | VITE_UPLOAD_LIMIT |
| "Etherpad integration?" | URL or blank | VITE_ETHERPAD + VITE_ETHERPAD_API_KEY |
| "Pixabay API key?" | String or blank | VITE_PIXABAY_API_KEY |
| "Email host?" | Host or blank | EMAIL_HOST for account emails |

## Software-Layer Concerns

- **Node.js 20+ + Redis 6+**: Real-time collaborative wall state.
- **GraphicsMagick required**: Image processing for uploads — `apt install graphicsmagick`.
- **Ghostscript required**: PDF preview generation — `apt install ghostscript`.
- **LibreOffice required**: Office document (ppt, doc, xls, odp etc.) conversion — `apt install libreoffice`.
- **PostgreSQL optional**: Set `PG_DB=1` to offload Redis data to PostgreSQL for persistence/scale.
- **SESSION_KEY**: Strong random secret for Express Session — stable across restarts.
- **ADMIN_PASSWORD**: Protects `/admin` page.
- **VITE_`-prefixed vars are build-time**: Embedded at build — changing requires rebuild.
- **Cron task**: `CRON_TASK_DATE` (default `59 23 * * Saturday`) cleans temp files and saves wall JSON to disk.
- **Digipad sibling**: Nearly identical architecture — if running both, share system dependencies.

## Deployment

### 1. Install system dependencies

```bash
apt install -y nodejs redis-server graphicsmagick ghostscript libreoffice
npm install -g pm2
systemctl enable --now redis-server
# Optional PostgreSQL:
# apt install postgresql
```

### 2. Clone and build

```bash
git clone https://codeberg.org/ladigitale/digiwall.git /opt/digiwall
cd /opt/digiwall

cat > .env.production << 'EOF'
VITE_WALL_WITHOUT_ACCOUNT=1
VITE_CREATE_ACCOUNT=1
VITE_WALL_LIMIT=50
VITE_UPLOAD_LIMIT=20
VITE_UPLOAD_FILE_TYPES=.jpg,.jpeg,.png,.gif,.mp4,.m4v,.mp3,.m4a,.ogg,.wav,.pdf,.ppt,.pptx,.odp,.doc,.docx,.odt
EOF

npm install
npm run build
```

### 3. Configure runtime environment

```bash
cat > /opt/digiwall/.env << 'EOF'
DOMAIN=https://digiwall.example.com
PORT=3000
REVERSE_PROXY=1
NODE_CLUSTER=0
DB_HOST=127.0.0.1
DB_PWD=
DB_PORT=6379
SESSION_KEY=change-this-to-a-strong-random-secret
SESSION_DURATION=86400000
ADMIN_PASSWORD=change-this-admin-password
CRON_TASK_DATE=59 23 * * Saturday
PG_DB=0
EMAIL_HOST=
EMAIL_ADDRESS=
EMAIL_PASSWORD=
EMAIL_PORT=587
EMAIL_SECURE=false
EOF
```

### 4. Start with PM2

```bash
cd /opt/digiwall
pm2 start ecosystem.config.cjs --env production
pm2 save && pm2 startup
```

### 5. NGINX reverse proxy

```nginx
server {
    listen 443 ssl;
    server_name digiwall.example.com;

    client_max_body_size 50M;

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

1. `cd /opt/digiwall && git pull`
2. Update `.env.production` if new VITE vars added
3. `npm install && npm run build`
4. `pm2 restart all`

## Gotchas

- **Three system daemons required**: GraphicsMagick, Ghostscript, and LibreOffice must be installed — missing any causes file conversion failures.
- **LibreOffice resource usage**: Office doc conversion is CPU/RAM intensive — allocate at least 2 GB RAM.
- **SESSION_KEY stability**: Changing invalidates all active sessions.
- **PostgreSQL offload optional but recommended at scale**: Redis holds all wall data in memory by default; PG_DB=1 offloads to PostgreSQL for persistence across Redis restarts.
- **client_max_body_size**: Match NGINX limit to VITE_UPLOAD_LIMIT + overhead.
- **Digipad vs Digiwall**: Nearly identical deployment; Digipad uses "pad" terminology, Digiwall uses "wall". Can coexist on same server sharing Redis/system deps.
- **French-language project**: UI and docs are in French.

## Links

- Source: https://codeberg.org/ladigitale/digiwall
- Website: https://digiwall.app/
- Ladigitale suite: https://ladigitale.dev/
