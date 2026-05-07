---
name: files-sharing
description: Files Sharing recipe for open-forge. Self-hosted file sharing with unique temporary links. Upload files, share via expiring link. PHP (Laravel) + Docker. Source: https://github.com/axeloz/filesharing
---

# Files Sharing

Self-hosted file sharing application that generates unique, temporary download links. Upload one or multiple files, get a shareable link — no account needed for recipients. Built on PHP (Laravel 12) + Tailwind CSS. Supports file deduplication, configurable upload size/count limits, download rate limiting, IP restrictions for uploaders, and multiple storage backends (local or S3). Docker via included Dockerfile. GPL-3.0 licensed.

Upstream: <https://github.com/axeloz/filesharing>

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any | Docker (PHP 8.2 + Apache) | Dockerfile included |
| Linux | PHP 8.2 + Apache/nginx (manual) | Laravel app |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| config | APP_URL | Public URL, e.g. https://share.example.com |
| config | APP_KEY | Generate with `php artisan key:generate` |
| config | UPLOAD_LIMIT_IPS | IPs allowed to upload (default: 127.0.0.1 only) |
| config | UPLOAD_MAX_FILESIZE | Max file size (default: 1G) |
| config | UPLOAD_MAX_FILES | Max files per upload (default: 1000) |
| config | LIMIT_DOWNLOAD_RATE | Download rate limit (default: 1M/s) |
| config (optional) | S3 storage | Configure FILESYSTEM_DISK=s3 + S3 env vars |

## Software-layer concerns

### Key env vars (`.env`)

| Var | Description | Default |
|---|---|---|
| APP_NAME | Application display name | File Sharing |
| APP_ENV | production / local | production |
| APP_KEY | Laravel secret key | (generate) |
| APP_URL | Public URL | (set) |
| APP_TIMEZONE | Server timezone | Europe/Paris |
| UPLOAD_MAX_FILESIZE | Max upload size | 1G |
| UPLOAD_MAX_FILES | Max files per upload | 1000 |
| UPLOAD_LIMIT_IPS | Comma-separated IPs allowed to upload | 127.0.0.1 |
| UPLOAD_PREVENT_DUPLICATES | Deduplicate identical files | true |
| HASH_MAX_FILESIZE | Files below this size get dedup hash | 1G |
| LIMIT_DOWNLOAD_RATE | Download rate cap | 1M |
| FILESYSTEM_DISK | Storage backend (local or s3) | local |

### Storage

- Local: files stored in `storage/app/`
- S3: configure AWS_* env vars and set `FILESYSTEM_DISK=s3`

## Install — Docker

```bash
git clone https://github.com/axeloz/filesharing.git
cd filesharing

# Configure environment
cp .env.example .env
# Edit .env: set APP_URL, UPLOAD_LIMIT_IPS (add your IP), APP_TIMEZONE

# Build image
docker build -t filesharing .

# Generate app key
docker run --rm filesharing php artisan key:generate --show
# Copy the output into APP_KEY in .env

# Run
docker run -d \
  --name filesharing \
  --restart unless-stopped \
  -p 8080:80 \
  -v $(pwd)/.env:/var/www/html/.env \
  -v filesharing_storage:/var/www/html/storage \
  filesharing
```

## Install — Manual (PHP/Apache)

```bash
git clone https://github.com/axeloz/filesharing.git /var/www/filesharing
cd /var/www/filesharing
composer install --no-dev
npm install && npm run build
cp .env.example .env
# Edit .env
php artisan key:generate
php artisan storage:link
chown -R www-data:www-data storage bootstrap/cache
```

Configure Apache/nginx to serve `public/` as document root.

## Upgrade procedure

```bash
git pull
composer install --no-dev
npm install && npm run build
php artisan migrate
php artisan cache:clear
# Restart web server
```

## Gotchas

- **UPLOAD_LIMIT_IPS defaults to 127.0.0.1** — this means only localhost can upload by default. Add your IP or your network range to allow uploads from external users. Without this, the upload form will be blocked.
- Set document root to `public/` — pointing at the repo root exposes config files and source code.
- `APP_KEY` must be set — generate with `php artisan key:generate` on first install. Without it, sessions and encrypted values will break.
- No built-in user authentication — the app is open by default; use `UPLOAD_LIMIT_IPS` and a reverse proxy with auth to control access.

## Links

- Source: https://github.com/axeloz/filesharing
