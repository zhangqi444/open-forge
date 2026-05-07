---
name: digipad
description: Digipad recipe for open-forge. Collaborative digital notepad/wall application. Node.js + Redis + GraphicsMagick + Ghostscript + LibreOffice. Heavy dependencies for file conversion. From Ladigitale. AGPL-3.0. Source: https://codeberg.org/ladigitale/digipad
---

# Digipad

An online collaborative notepad ("wall") application where users can post notes, images, videos, PDFs, and documents on a shared canvas. Part of the Ladigitale suite. The most feature-rich and dependency-heavy of the digi* apps — requires Redis, GraphicsMagick, Ghostscript, and LibreOffice for full file conversion support. Documentation in French. AGPL-3.0 licensed. Source: <https://codeberg.org/ladigitale/digipad>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux | Node.js 20+ + Redis 6+ + PM2 + system deps | Production (upstream recommended) |
| Any Linux | Node.js 20+ + Redis 6+ | `npm run prod` without PM2 |
| Docker | Custom | No official Docker image; all system deps must be in image |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain?" | FQDN | e.g. digipad.example.com |
| "Port?" | Number | Default 3000 |
| "Redis host?" | Host | Default localhost |
| "Redis port?" | Number | Default 6379 |
| "Redis password?" | Secret or blank | Set if Redis not on loopback |
| "Session secret key?" | Random string | SESSION_KEY — strong random value |
| "Admin password?" | Secret | ADMIN_PASSWORD — for /admin page |
| "Behind reverse proxy?" | Yes / No | REVERSE_PROXY=1 |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Allow account creation?" | Yes / No | VITE_CREATE_ACCOUNT=1 |
| "Allow pads without account?" | Yes / No | VITE_PAD_WITHOUT_ACCOUNT=1 |
| "Max pads per user?" | Number | VITE_PAD_LIMIT |
| "Upload limit per file?" | MB | VITE_UPLOAD_LIMIT |
| "Etherpad integration?" | URL or blank | VITE_ETHERPAD + VITE_ETHERPAD_API_KEY |
| "Pixabay API key?" | String or blank | VITE_PIXABAY_API_KEY |
| "Email host?" | Host or blank | EMAIL_HOST for account emails |
| "Matomo analytics?" | URL or blank | VITE_MATOMO + VITE_MATOMO_SITE_ID |

## Software-Layer Concerns

- **Node.js 20+ required**: Vue.js 3 + Vike SSR + Express.
- **Redis 6+ required**: Session store and pad state.
- **GraphicsMagick required**: Image processing for uploaded files — `apt install graphicsmagick`.
- **Ghostscript required**: PDF preview generation — `apt install ghostscript`.
- **LibreOffice required**: Office document (ppt, doc, xls, odp, etc.) conversion — `apt install libreoffice`.
- **SESSION_KEY**: Strong random secret for Express Session — must be stable across restarts.
- **ADMIN_PASSWORD**: Protects the `/admin` management page.
- **VITE_`-prefixed vars**: Embedded at build time — changing requires a rebuild.
- **Non-VITE_ vars**: Runtime env vars (Redis, session, email, admin password) — no rebuild needed.
- **Cron task**: Built-in cron (`CRON_TASK_DATE`, default `59 23 * * Saturday`) cleans temporary files.
- **Etherpad optional**: Only needed for collaborative text editing within pads.
- **WebSocket required**: Real-time collaboration requires WebSocket passthrough in reverse proxy.

## Deployment

### 1. Install system dependencies

```bash
apt install -y nodejs redis-server graphicsmagick ghostscript libreoffice
npm install -g pm2
systemctl enable --now redis-server
```

### 2. Clone and build

```bash
git clone https://codeberg.org/ladigitale/digipad.git /opt/digipad
cd /opt/digipad

# Create build-time env file (VITE_* vars baked in at build)
cat > .env.production.build << 'EOF'
VITE_PAD_WITHOUT_ACCOUNT=1
VITE_CREATE_ACCOUNT=1
VITE_PAD_LIMIT=50
VITE_UPLOAD_LIMIT=20
VITE_UPLOAD_FILE_TYPES=.jpg,.jpeg,.png,.gif,.mp4,.m4v,.mp3,.m4a,.ogg,.wav,.pdf,.ppt,.pptx,.odp,.doc,.docx,.odt
EOF
# Rename to .env.production for build
cp .env.production.build .env.production

npm install
npm run build
```

### 3. Configure runtime environment

```bash
cat > /opt/digipad/.env << 'EOF'
DOMAIN=https://digipad.example.com
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
EMAIL_HOST=
EMAIL_ADDRESS=
EMAIL_PASSWORD=
EMAIL_PORT=587
EMAIL_SECURE=false
EOF
```

### 4. Start with PM2

```bash
cd /opt/digipad
pm2 start ecosystem.config.cjs --env production
pm2 save
pm2 startup
```

### 5. NGINX reverse proxy

```nginx
server {
    listen 443 ssl;
    server_name digipad.example.com;

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

1. `cd /opt/digipad && git pull`
2. Update `.env.production` if new VITE vars were added
3. `npm install && npm run build`
4. `pm2 restart all`

## Gotchas

- **Three system daemons required**: GraphicsMagick, Ghostscript, and LibreOffice must be installed on the host — these are not managed by Node.js. Missing any causes file preview failures.
- **LibreOffice startup time**: LibreOffice conversion can be slow; first conversion after startup may time out on low-RAM systems (use at least 2 GB RAM).
- **SESSION_KEY stability**: Changing SESSION_KEY invalidates all active sessions — use a stable fixed value.
- **VITE vars are build-time**: `VITE_PAD_LIMIT`, `VITE_UPLOAD_LIMIT`, etc. are baked into the JS bundle — changing them requires a full rebuild and restart.
- **client_max_body_size**: NGINX default is 1 MB — must increase for file uploads (set to VITE_UPLOAD_LIMIT + margin).
- **WebSocket passthrough**: Required for real-time collaboration.
- **French-language project**: UI and docs are in French.

## Links

- Source: https://codeberg.org/ladigitale/digipad
- Website: https://digipad.app/
- Ladigitale suite: https://ladigitale.dev/
