---
name: digistorm
description: Digistorm recipe for open-forge. Collaborative surveys, quizzes, brainstorms, and word clouds. Node.js + Redis + PM2. Optional S3 and Digidrive integration. From Ladigitale (documentation in French). AGPL-3.0. Source: https://codeberg.org/ladigitale/digistorm
---

# Digistorm

An online application to create collaborative surveys, quizzes, brainstorming sessions, and word clouds. Part of the Ladigitale educational suite. Node.js + Redis + PM2 architecture (similar to Digibuzzer/Digipad); features optional S3 storage and Digidrive integration. Word cloud rendering via Vue Wordcloud. Documentation in French. AGPL-3.0 licensed. Source: <https://codeberg.org/ladigitale/digistorm>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux | Node.js 20+ + Redis 6+ + PM2 | Production (upstream recommended) |
| Any Linux + S3 | Node.js 20+ + Redis 6+ + S3 | For file uploads to object storage |
| Docker | Custom | No official Docker image |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain?" | FQDN | e.g. digistorm.example.com |
| "Port?" | Number | Default 3000 |
| "Redis host?" | Host | Default 127.0.0.1 |
| "Redis port?" | Number | Default 6379 |
| "Redis password?" | Secret or blank | Leave blank if local |
| "Session secret key?" | Random string | SESSION_KEY — strong random value |
| "Admin password?" | Secret | ADMIN_PASSWORD — for /admin page |
| "Authorized domains?" | Comma-separated or `*` | AUTHORIZED_DOMAINS — API access control |
| "Behind reverse proxy?" | Yes / No | REVERSE_PROXY=1 |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Upload limit per file?" | MB | VITE_UPLOAD_LIMIT — default 5 MB |
| "Storage type?" | fs / s3 | VITE_STORAGE — default `fs` |
| "Email host?" | Host or blank | EMAIL_HOST for notifications |
| "Digidrive encryption key?" | String or blank | ENCRYPTION_KEY — only if using Digidrive |
| "S3 server type?" | aws / minio | S3_SERVER_TYPE — default `aws` |

## Software-Layer Concerns

- **Node.js 20+ + Redis 6+**: Same architecture as Digibuzzer and Digipad.
- **SESSION_KEY**: Strong random secret for Express Session — must be stable across restarts.
- **ADMIN_PASSWORD**: Protects `/admin` management page.
- **AUTHORIZED_DOMAINS**: Runtime env var (not build-time like PHP-based digi* apps) — no rebuild needed.
- **VITE_STORAGE + VITE_UPLOAD_LIMIT**: Build-time vars embedded in JS bundle.
- **S3 credentials**: Runtime env vars — no rebuild needed.
- **S3_SERVER_TYPE**: Differentiates AWS S3 from MinIO-compatible servers (affects SDK configuration).
- **Digidrive ENCRYPTION_KEY**: Only needed if integrating with the Digidrive file storage service.
- **WebSocket required**: Real-time collaborative features need WebSocket passthrough.

## Deployment

### 1. Install dependencies

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs redis-server
systemctl enable --now redis-server
npm install -g pm2
```

### 2. Clone and build

```bash
git clone https://codeberg.org/ladigitale/digistorm.git /opt/digistorm
cd /opt/digistorm

# Create build-time env file
cat > .env.build << 'EOF'
VITE_UPLOAD_LIMIT=5
VITE_STORAGE=fs
VITE_S3_PUBLIC_LINK=
EOF
cp .env.build .env.production

npm install
npm run build
```

### 3. Configure runtime environment

```bash
cat > /opt/digistorm/.env << 'EOF'
DOMAIN=https://digistorm.example.com
PORT=3000
REVERSE_PROXY=1
NODE_CLUSTER=0
DB_HOST=127.0.0.1
DB_PWD=
DB_PORT=6379
SESSION_KEY=change-this-to-a-strong-random-secret
SESSION_DURATION=86400000
ADMIN_PASSWORD=change-this-admin-password
AUTHORIZED_DOMAINS=*
EMAIL_HOST=
EMAIL_ADDRESS=
EMAIL_PASSWORD=
EMAIL_PORT=587
EMAIL_SECURE=false
S3_SERVER_TYPE=aws
S3_ENDPOINT=
S3_ACCESS_KEY=
S3_SECRET_KEY=
S3_REGION=
S3_BUCKET=
ENCRYPTION_KEY=
EOF
```

### 4. Start with PM2

```bash
cd /opt/digistorm
pm2 start ecosystem.config.cjs --env production
pm2 save
pm2 startup
```

### 5. NGINX reverse proxy

```nginx
server {
    listen 443 ssl;
    server_name digistorm.example.com;

    client_max_body_size 10M;

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

1. `cd /opt/digistorm && git pull`
2. `npm install && npm run build`
3. `pm2 restart all`

## Gotchas

- **SESSION_KEY stability**: Changing SESSION_KEY invalidates all active sessions.
- **AUTHORIZED_DOMAINS is runtime here**: Unlike PHP-based digi* apps, AUTHORIZED_DOMAINS is a Node.js runtime env var — no rebuild needed to change it.
- **VITE_STORAGE and VITE_UPLOAD_LIMIT are build-time**: Must rebuild JS bundle to change storage type or upload limit.
- **S3_SERVER_TYPE=minio**: Use `minio` for MinIO or MinIO-compatible S3 endpoints; `aws` for standard AWS S3.
- **WebSocket passthrough required**: Word clouds and brainstorm sessions use real-time updates.
- **French-language project**: UI and docs are in French.

## Links

- Source: https://codeberg.org/ladigitale/digistorm
- Website: https://digistorm.app/
- Demo: https://digistorm.app/
- Vue Wordcloud: https://github.com/SeregPie/VueWordCloud
- Ladigitale suite: https://ladigitale.dev/
