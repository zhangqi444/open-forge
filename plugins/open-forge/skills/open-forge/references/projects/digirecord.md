---
name: digirecord
description: Digirecord recipe for open-forge. Record and share audio files in the browser, with PHP API and optional S3 storage. PHP 8.4+ + Composer required. From Ladigitale (documentation in French). AGPL-3.0. Source: https://codeberg.org/ladigitale/digirecord
---

# Digirecord

A simple application to record audio in the browser and share the recordings as files. Part of the Ladigitale educational suite. PHP 8.4+ API backend with Composer dependencies; supports local filesystem or S3-compatible object storage. Documentation in French. AGPL-3.0 licensed. Source: <https://codeberg.org/ladigitale/digirecord>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux | PHP 8.4+ + NGINX/Apache2 + Composer | Production |
| Any Linux + S3 | PHP 8.4+ + S3-compatible storage | For shared/cloud audio storage |
| Docker | Custom | No official Docker image |

> Node.js is a **build-time** dependency only. PHP 8.4+ is required.

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain?" | FQDN | e.g. digirecord.example.com |
| "Authorized domains?" | Comma-separated or `*` | AUTHORIZED_DOMAINS |
| "Upload limit per file?" | MB | VITE_UPLOAD_LIMIT — default 4 MB |
| "MP3 bitrate?" | kbps | VITE_MP3_BITRATE — default 192 |
| "Storage type?" | fs / s3 | VITE_STORAGE — default `fs` |

### Phase 2 — Deploy (S3 only)

| Prompt | Format | Notes |
|---|---|---|
| "S3 endpoint?" | URL | S3_ENDPOINT |
| "S3 access key?" | String | S3_ACCESS_KEY |
| "S3 secret key?" | Secret | S3_SECRET_KEY |
| "S3 region?" | String | S3_REGION |
| "S3 bucket?" | String | S3_BUCKET |
| "S3 public link?" | URL | VITE_S3_PUBLIC_LINK |

## Software-Layer Concerns

- **PHP 8.4+ strictly required**: Same requirement as digiflashcards — use PHP 8.4.
- **Composer required**: PHP dependencies managed via Composer.
- **Node.js build-only**: Not needed in production.
- **VITE_`-prefixed vars are build-time**: Embedded in JS bundle — changing requires rebuild.
- **S3 credentials are runtime PHP vars**: Not baked into bundle.
- **Browser microphone access**: Recording requires HTTPS — HTTP deployments will not have microphone access.
- **Audio format**: Records in browser-native format, converts to MP3 at `VITE_MP3_BITRATE` kbps.

## Deployment

### 1. Install dependencies

```bash
apt install php8.4 php8.4-fpm php8.4-curl php8.4-mbstring nodejs npm
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
```

### 2. Clone, configure, and build

```bash
git clone https://codeberg.org/ladigitale/digirecord.git /opt/digirecord
cd /opt/digirecord
composer install --no-dev

cat > .env.production << 'EOF'
AUTHORIZED_DOMAINS=digirecord.example.com
VITE_UPLOAD_LIMIT=4
VITE_MP3_BITRATE=192
VITE_STORAGE=fs
EOF

npm install
npm run build
```

### 3. Deploy

```bash
cp -r dist/ /var/www/digirecord/
cp -r vendor/ /var/www/digirecord/vendor/
chown -R www-data:www-data /var/www/digirecord/
```

### 4. NGINX configuration

```nginx
server {
    listen 443 ssl;
    server_name digirecord.example.com;

    root /var/www/digirecord;
    index index.html;

    client_max_body_size 10M;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/run/php/php8.4-fpm.sock;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
}
```

## Upgrade Procedure

1. `cd /opt/digirecord && git pull`
2. `composer install --no-dev`
3. `npm install && npm run build`
4. `cp -r dist/ /var/www/digirecord/ && cp -r vendor/ /var/www/digirecord/vendor/`

## Gotchas

- **HTTPS required for microphone**: Browser microphone access (MediaRecorder API) only works in secure contexts (HTTPS).
- **PHP 8.4 strictly required**: Do not use PHP 8.3 or earlier.
- **client_max_body_size**: Set to VITE_UPLOAD_LIMIT + margin (e.g. 10M for 4 MB limit).
- **Build-time vars**: VITE_UPLOAD_LIMIT, VITE_MP3_BITRATE, VITE_STORAGE, VITE_S3_PUBLIC_LINK are baked in — rebuild to change.
- **S3 credentials runtime**: S3_ENDPOINT, S3_ACCESS_KEY, etc. are PHP env vars — no rebuild needed.
- **French-language project**: UI and docs are in French.

## Links

- Source: https://codeberg.org/ladigitale/digirecord
- Website: https://ladigitale.dev/digirecord/
- Ladigitale suite: https://ladigitale.dev/
