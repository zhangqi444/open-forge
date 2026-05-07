---
name: digiquiz
description: Digiquiz recipe for open-forge. H5P content viewer — publish interactive H5P quizzes and activities online. PHP API + Vite frontend. From Ladigitale (documentation in French). AGPL-3.0. Source: https://codeberg.org/ladigitale/digiquiz
---

# Digiquiz

A simple interface for publishing and viewing H5P interactive content (quizzes, activities, presentations) online using H5P Standalone. Bundles all H5P libraries for easy deployment. Part of the Ladigitale educational suite. Requires PHP 8+ API + Vite-built frontend. Documentation in French. AGPL-3.0 licensed. Source: <https://codeberg.org/ladigitale/digiquiz>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux | PHP 8+ + NGINX/Apache2 | Production — PHP serves the API |
| Any Linux | PHP 8+ + Apache2 (with .htaccess) | Apache RewriteEngine required for SPA routing |
| Any Linux | PHP 8+ + Node.js (build) | Node.js is build-time only |
| Docker | Custom | No official Docker image |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain?" | FQDN | e.g. digiquiz.example.com |
| "App folder?" | Path | VITE_FOLDER e.g. `/digiquiz/` — for subdirectory installs |
| "Authorized domains?" | Comma-separated or `*` | AUTHORIZED_DOMAINS |
| "Upload limit per file?" | MB | VITE_UPLOAD_LIMIT — default 20 MB |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Results webhook URL?" | URL or blank | VITE_RESULTS_LINK — optional external results handler |
| "Web server?" | NGINX / Apache2 | Apache needs .htaccess; NGINX needs try_files |
| "TLS?" | Yes / No | Handled by web server |

## Software-Layer Concerns

- **PHP 8+ required**: Serves the API for H5P content upload and management.
- **Node.js is build-only**: Not needed in production.
- **VITE_DOMAIN**: Full protocol + host (e.g. `https://ladigitale.dev`) — used to construct URLs.
- **VITE_FOLDER**: Subdirectory path including trailing slash (e.g. `/digiquiz/`) — critical for subdirectory installs.
- **H5P libraries bundled**: The repo includes all H5P libraries — no separate H5P installation needed.
- **Apache .htaccess**: SPA routing requires `RewriteEngine on` with fallback to `index.html`.
- **NGINX try_files**: Equivalent SPA routing config for NGINX.
- **AUTHORIZED_DOMAINS**: Build-time; changing requires rebuild.

## Deployment

### 1. Install dependencies

```bash
apt install php8.1 php8.1-fpm nodejs npm
```

### 2. Clone, configure, and build

```bash
git clone https://codeberg.org/ladigitale/digiquiz.git /opt/digiquiz
cd /opt/digiquiz

cat > .env.production << 'EOF'
AUTHORIZED_DOMAINS=digiquiz.example.com
VITE_DOMAIN=https://digiquiz.example.com
VITE_FOLDER=/
VITE_UPLOAD_LIMIT=20
EOF

npm install
npm run build
# Static assets in dist/
```

### 3. Deploy

```bash
cp -r dist/ /var/www/digiquiz/
chown -R www-data:www-data /var/www/digiquiz/
```

### 4. NGINX configuration

```nginx
server {
    listen 443 ssl;
    server_name digiquiz.example.com;

    root /var/www/digiquiz;
    index index.html;

    client_max_body_size 25M;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
}
```

### Apache .htaccess alternative (for Apache deployments)

```apache
RewriteEngine on
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^(.*)$ index.html
```

## Upgrade Procedure

1. `cd /opt/digiquiz && git pull` (also pulls updated H5P libraries)
2. `npm install && npm run build`
3. `cp -r dist/ /var/www/digiquiz/`

## Gotchas

- **VITE_FOLDER matters for subdirectory installs**: If serving from a path like `/digiquiz/`, set `VITE_FOLDER=/digiquiz/` — wrong value breaks all asset paths.
- **VITE_DOMAIN must include protocol**: `https://...` not just the hostname.
- **H5P libraries are in-repo**: No separate H5P installation required — all libraries are bundled. Updates arrive via `git pull`.
- **client_max_body_size**: Increase NGINX limit to match VITE_UPLOAD_LIMIT (default 20 MB → set to 25M).
- **Build-time vars**: `AUTHORIZED_DOMAINS`, `VITE_DOMAIN`, `VITE_FOLDER`, `VITE_UPLOAD_LIMIT` are all baked in — changing requires rebuild.
- **French-language project**: UI and docs are in French.

## Links

- Source: https://codeberg.org/ladigitale/digiquiz
- Website: https://ladigitale.dev/digiquiz/
- Demo: https://ladigitale.dev/digiquiz/
- H5P Standalone: https://github.com/tunapanda/h5p-standalone
- H5P content: https://h5p.org/
- Ladigitale suite: https://ladigitale.dev/
