---
name: digisteps
description: Digisteps recipe for open-forge. Online educational pathway creator with PDF/Office file support. PHP 8.4+ + Composer + SQLite + GD library. From Ladigitale (documentation in French). AGPL-3.0. Source: https://codeberg.org/ladigitale/digisteps
---

# Digisteps

A simple application for creating online educational learning paths — sequences of steps containing media, documents, and activities. Part of the Ladigitale educational suite. Requires PHP 8.4+ with SQLite extension and GD library for thumbnail generation. Supports S3 storage. Documentation in French. AGPL-3.0 licensed. Source: <https://codeberg.org/ladigitale/digisteps>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux | PHP 8.4+ + SQLite + GD + NGINX/Apache2 + Composer | Production |
| Any Linux + S3 | PHP 8.4+ + SQLite + GD + S3 | For shared/cloud asset storage |
| Docker | Custom | No official Docker image |

> Node.js is a **build-time** dependency only. PHP 8.4+ with SQLite and GD is required.

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain?" | FQDN | e.g. digisteps.example.com |
| "Authorized domains?" | Comma-separated or `*` | AUTHORIZED_DOMAINS |
| "Upload limit per file?" | MB | VITE_UPLOAD_LIMIT — default 2 MB |
| "Storage type?" | fs / s3 | VITE_STORAGE — default `fs` |
| "DOCX viewer URL?" | URL or blank | VITE_DOCX_VIEWER — optional Office doc viewer |

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

- **PHP 8.4+ required**: Strictly enforced.
- **SQLite extension required**: `php8.4-sqlite3` — data stored in SQLite, not a full RDBMS.
- **GD library required**: `php8.4-gd` — used to generate thumbnail images from uploaded files.
- **Composer required**: PHP dependencies managed via Composer.
- **pdf.js included**: PDF viewing handled client-side via bundled pdf.js (no server-side PDF renderer needed).
- **VITE_DOCX_VIEWER**: Optional URL to an external Office doc viewer (e.g. Google Docs viewer); without it, .docx files trigger a download instead of inline view.
- **panzoom + jsPanel4**: Bundled JS libraries for interactive path display.

## Deployment

### 1. Install dependencies

```bash
apt install php8.4 php8.4-fpm php8.4-sqlite3 php8.4-gd php8.4-curl php8.4-mbstring nodejs npm
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
```

### 2. Clone, configure, and build

```bash
git clone https://codeberg.org/ladigitale/digisteps.git /opt/digisteps
cd /opt/digisteps
composer install --no-dev

cat > .env.production << 'EOF'
AUTHORIZED_DOMAINS=digisteps.example.com
VITE_UPLOAD_LIMIT=2
VITE_STORAGE=fs
VITE_S3_PUBLIC_LINK=
VITE_DOCX_VIEWER=
EOF

npm install
npm run build
```

### 3. Deploy

```bash
cp -r dist/ /var/www/digisteps/
cp -r vendor/ /var/www/digisteps/vendor/
chown -R www-data:www-data /var/www/digisteps/
```

### 4. NGINX configuration

```nginx
server {
    listen 443 ssl;
    server_name digisteps.example.com;

    root /var/www/digisteps;
    index index.html;

    client_max_body_size 5M;

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

1. `cd /opt/digisteps && git pull`
2. `composer install --no-dev`
3. `npm install && npm run build`
4. `cp -r dist/ /var/www/digisteps/ && cp -r vendor/ /var/www/digisteps/vendor/`

## Gotchas

- **SQLite required**: `php8.4-sqlite3` must be installed — this is not a standard LAMP stack component.
- **GD library required**: `php8.4-gd` for thumbnail generation — missing it causes thumbnail creation failures.
- **DOCX inline view needs external viewer**: Without VITE_DOCX_VIEWER, Office files download instead of displaying inline.
- **Build-time vars**: VITE_UPLOAD_LIMIT, VITE_STORAGE, VITE_S3_PUBLIC_LINK, VITE_DOCX_VIEWER are all baked in.
- **French-language project**: UI and docs are in French.

## Links

- Source: https://codeberg.org/ladigitale/digisteps
- Website: https://ladigitale.dev/digisteps/
- Demo: https://ladigitale.dev/digisteps/
- Ladigitale suite: https://ladigitale.dev/
