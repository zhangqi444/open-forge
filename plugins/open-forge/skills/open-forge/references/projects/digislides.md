---
name: digislides
description: Digislides recipe for open-forge. Simple multimedia presentation creator. PHP 8.4+ + Composer + optional S3. From Ladigitale (documentation in French). AGPL-3.0. Source: https://codeberg.org/ladigitale/Digislides
---

# Digislides

A simple application to create multimedia presentations with text, images, and media. Part of the Ladigitale educational suite. PHP 8.4+ API with Composer; supports local filesystem or S3-compatible storage for uploaded assets; optional Pixabay image search. Documentation in French. AGPL-3.0 licensed. Source: <https://codeberg.org/ladigitale/Digislides>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux | PHP 8.4+ + NGINX/Apache2 + Composer | Production |
| Any Linux + S3 | PHP 8.4+ + S3-compatible storage | For shared/cloud asset storage |
| Docker | Custom | No official Docker image |

> Node.js is a **build-time** dependency only. PHP 8.4+ and Composer are required.

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain?" | FQDN | e.g. digislides.example.com |
| "App folder?" | Path | VITE_FOLDER e.g. `/` or `/digislides/` |
| "Authorized domains?" | Comma-separated or `*` | AUTHORIZED_DOMAINS |
| "Upload limit per file?" | MB | VITE_UPLOAD_LIMIT — default 1 MB |
| "Pixabay API key?" | String or blank | VITE_PIXABAY_API_KEY |
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

- **PHP 8.4+ required**: Strictly enforced.
- **Composer required**: PHP dependencies managed via Composer.
- **VITE_DOMAIN + VITE_FOLDER**: Required for correct URL generation — especially critical for subdirectory installs.
- **VITE_`-prefixed vars are build-time**: Embedded in JS bundle — changing requires rebuild.
- **S3 credentials are runtime PHP vars**: No rebuild needed for S3 config changes.
- **Multiple font licenses**: Includes fonts under Apache 2.0, SIL OFL 1.1, and Ubuntu Font Licence.

## Deployment

### 1. Install dependencies

```bash
apt install php8.4 php8.4-fpm php8.4-curl php8.4-mbstring nodejs npm
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
```

### 2. Clone, configure, and build

```bash
# Note: repo name uses capital D — Digislides
git clone https://codeberg.org/ladigitale/Digislides.git /opt/digislides
cd /opt/digislides
composer install --no-dev

cat > .env.production << 'EOF'
AUTHORIZED_DOMAINS=digislides.example.com
VITE_DOMAIN=https://digislides.example.com
VITE_FOLDER=/
VITE_PIXABAY_API_KEY=
VITE_UPLOAD_LIMIT=1
VITE_STORAGE=fs
EOF

npm install
npm run build
```

### 3. Deploy

```bash
cp -r dist/ /var/www/digislides/
cp -r vendor/ /var/www/digislides/vendor/
chown -R www-data:www-data /var/www/digislides/
```

### 4. NGINX configuration

```nginx
server {
    listen 443 ssl;
    server_name digislides.example.com;

    root /var/www/digislides;
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

### Apache .htaccess alternative

```apache
RewriteEngine on
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^(.*)$ index.html
```

## Upgrade Procedure

1. `cd /opt/digislides && git pull`
2. `composer install --no-dev`
3. `npm install && npm run build`
4. `cp -r dist/ /var/www/digislides/ && cp -r vendor/ /var/www/digislides/vendor/`

## Gotchas

- **Repo name is capitalized**: `Digislides` (capital D) on Codeberg — case-sensitive clone.
- **VITE_FOLDER critical for subdirectory installs**: Set correctly or all asset URLs break.
- **Default upload limit is 1 MB**: Very small — increase VITE_UPLOAD_LIMIT and NGINX client_max_body_size for real use.
- **Build-time vars**: AUTHORIZED_DOMAINS, VITE_DOMAIN, VITE_FOLDER, VITE_PIXABAY_API_KEY, VITE_UPLOAD_LIMIT, VITE_STORAGE, VITE_S3_PUBLIC_LINK are baked in.
- **French-language project**: UI and docs are in French.

## Links

- Source: https://codeberg.org/ladigitale/Digislides
- Website: https://ladigitale.dev/digislides/
- Demo: https://ladigitale.dev/digislides/
- Ladigitale suite: https://ladigitale.dev/
