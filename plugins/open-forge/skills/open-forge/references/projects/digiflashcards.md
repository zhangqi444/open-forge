---
name: digiflashcards
description: Digiflashcards recipe for open-forge. Online flashcard creator with PHP API backend and optional S3 storage. From Ladigitale (documentation in French). AGPL-3.0. Source: https://codeberg.org/ladigitale/digiflashcards
---

# Digiflashcards

A simple online application to create flashcards for study and review. Part of the Ladigitale educational suite. Built with a Vite/Node.js frontend and PHP API backend; supports local filesystem or S3-compatible object storage for media uploads. Documentation in French. AGPL-3.0 licensed. Source: <https://codeberg.org/ladigitale/digiflashcards>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux | PHP 8.4+ + NGINX/Apache2 + Composer | Production — PHP serves the API |
| Any Linux | PHP 8.4+ + Node.js (build) + Composer | Node.js is build-time only |
| Any Linux + S3 | PHP 8.4+ + S3-compatible storage | For media files at scale |
| Docker | Custom | No official Docker image |

> Node.js is a **build-time** dependency only. PHP 8.4+ is required for the API.

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain?" | FQDN | e.g. digiflashcards.example.com |
| "Authorized domains?" | Comma-separated or `*` | AUTHORIZED_DOMAINS — controls POST/API access |
| "PHP version?" | 8.4+ | PHP 8.4 minimum |
| "Storage type?" | fs / s3 | VITE_STORAGE — default `fs` |
| "Upload limit per file?" | MB | VITE_UPLOAD_LIMIT — default 1 MB |

### Phase 2 — Deploy (S3 only)

| Prompt | Format | Notes |
|---|---|---|
| "S3 endpoint?" | URL | S3_ENDPOINT |
| "S3 access key?" | String | S3_ACCESS_KEY |
| "S3 secret key?" | Secret | S3_SECRET_KEY |
| "S3 region?" | String | S3_REGION |
| "S3 bucket?" | String | S3_BUCKET |
| "S3 public link?" | URL | VITE_S3_PUBLIC_LINK — public URL for serving S3 content |

## Software-Layer Concerns

- **PHP 8.4+ required**: Stricter than other digi* apps — PHP 8.3 may not work.
- **Composer required**: PHP dependencies managed via Composer (`composer install`).
- **AUTHORIZED_DOMAINS**: Build-time variable controlling which domains can POST to the API.
- **Storage modes**: `fs` stores uploads on local filesystem; `s3` uses S3-compatible object storage.
- **VITE_`-prefixed vars are build-time**: `VITE_STORAGE`, `VITE_UPLOAD_LIMIT`, `VITE_S3_PUBLIC_LINK` are embedded in the JS bundle — changing them requires a rebuild.
- **S3 credentials are server-side**: `S3_ENDPOINT`, `S3_ACCESS_KEY`, `S3_SECRET_KEY`, `S3_REGION`, `S3_BUCKET` are runtime PHP env vars — not baked into the bundle.
- **No database**: Data stored in flat files or S3 — no database required.

## Deployment

### 1. Install dependencies

```bash
# PHP 8.4
apt install php8.4 php8.4-fpm php8.4-curl php8.4-mbstring
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Node.js (build only)
apt install nodejs npm
```

### 2. Clone, configure, and build

```bash
git clone https://codeberg.org/ladigitale/digiflashcards.git /opt/digiflashcards
cd /opt/digiflashcards

# Install PHP dependencies
composer install --no-dev

# Create build-time env file
cat > .env.production << 'EOF'
AUTHORIZED_DOMAINS=digiflashcards.example.com
VITE_UPLOAD_LIMIT=5
VITE_STORAGE=fs
EOF

# Install JS dependencies and build
npm install
npm run build
# Static assets in dist/
```

### 3. Deploy

```bash
cp -r dist/ /var/www/digiflashcards/
# Copy PHP vendor and API files
cp -r vendor/ /var/www/digiflashcards/vendor/
chown -R www-data:www-data /var/www/digiflashcards/
```

### 4. NGINX configuration

```nginx
server {
    listen 443 ssl;
    server_name digiflashcards.example.com;

    root /var/www/digiflashcards;
    index index.html;

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

```bash
nginx -t && systemctl reload nginx
```

## Upgrade Procedure

1. `cd /opt/digiflashcards && git pull`
2. `composer install --no-dev`
3. `npm install && npm run build`
4. `cp -r dist/ /var/www/digiflashcards/ && cp -r vendor/ /var/www/digiflashcards/vendor/`

## Gotchas

- **PHP 8.4 strictly required**: Do not use PHP 8.3 or earlier — upstream sets `^8.4` in composer.json.
- **Build-time vs runtime env vars**: `VITE_*` vars are baked in at build time; S3 credentials are PHP runtime env vars. Mixing these up causes hard-to-debug failures.
- **AUTHORIZED_DOMAINS rebuild**: Changing allowed domains requires a full JS rebuild.
- **S3 public link required for S3 mode**: Without `VITE_S3_PUBLIC_LINK`, uploaded media won't be servable to clients.
- **French-language project**: UI and docs are in French.
- **No official Docker image**: Build from source.

## Links

- Source: https://codeberg.org/ladigitale/digiflashcards
- Website: https://ladigitale.dev/digiflashcards/
- Demo: https://ladigitale.dev/digiflashcards/
- Ladigitale suite: https://ladigitale.dev/
