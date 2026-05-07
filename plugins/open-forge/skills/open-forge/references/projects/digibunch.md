---
name: digibunch
description: Digibunch recipe for open-forge. Simple PHP/Node.js app to create shareable bunches of links for learners and colleagues. Part of the Ladigitale educational suite. AGPL-3.0. Source: https://codeberg.org/ladigitale/digibunch
---

# Digibunch

A simple application to create "bunches" of curated links to share with learners or colleagues. Part of the Ladigitale educational tools suite. Built with PHP (API backend) and Node.js (build tooling). AGPL-3.0 licensed. Documentation in French. Source: <https://codeberg.org/ladigitale/digibunch>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux | PHP 8+ + NGINX/Apache2 | Production — PHP serves the API |
| Any Linux | PHP 8+ + Node.js (build only) | Node.js is used only for `npm run build` |
| Docker | Custom | No official Docker image |

> Node.js is a **build-time** dependency only — the deployed app is static files + PHP API.

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain?" | FQDN | e.g. digibunch.example.com |
| "Authorized POST/API domains?" | Comma-separated or `*` | `AUTHORIZED_DOMAINS` env var |
| "PHP version?" | 8.x | PHP 8.0+ required |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Web server?" | NGINX / Apache2 | Serves static dist/ + PHP API |
| "TLS?" | Yes / No | Handled by web server |

## Software-Layer Concerns

- **PHP 8+ required**: PHP serves the API backend.
- **Node.js is build-only**: npm/Node.js only needed on the build machine — not in production.
- **AUTHORIZED_DOMAINS**: Controls which domains can make POST requests to the API. Set to `*` for open access or a comma-separated domain list to restrict.
- **Build artifact**: `npm run build` produces static assets in `dist/` — serve this directory.
- **No database**: Digibunch stores data in flat files or browser-side — no database required.
- **French documentation**: Most upstream README and UI content is in French.

## Deployment

### 1. Install dependencies

```bash
# PHP 8.x
apt install php8.1 php8.1-fpm

# Node.js (build only)
apt install nodejs npm
```

### 2. Clone and configure

```bash
git clone https://codeberg.org/ladigitale/digibunch.git /opt/digibunch
cd /opt/digibunch

# Create build-time environment file
cat > .env.production << 'EOF'
AUTHORIZED_DOMAINS=digibunch.example.com
EOF
```

### 3. Build

```bash
npm install
npm run build
# Static assets now in dist/
```

### 4. Deploy to web root

```bash
cp -r dist/ /var/www/digibunch/
chown -R www-data:www-data /var/www/digibunch/
```

### 5. NGINX configuration

```nginx
server {
    listen 443 ssl;
    server_name digibunch.example.com;

    root /var/www/digibunch;
    index index.html;

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

```bash
systemctl reload nginx
```

## Upgrade Procedure

1. `cd /opt/digibunch && git pull`
2. `npm install` (pick up dependency changes)
3. `npm run build`
4. `cp -r dist/ /var/www/digibunch/`
5. `systemctl reload nginx` (or php-fpm if PHP files changed)

## Gotchas

- **AUTHORIZED_DOMAINS is build-time**: The `AUTHORIZED_DOMAINS` variable is embedded at build time via Vite (prefixed `VITE_` internally) — changing it requires a rebuild.
- **No official Docker image**: Must build from source.
- **French-language project**: UI and upstream docs are in French.
- **Node.js not needed in production**: Don't install Node.js on the production server — build locally or in CI and deploy only `dist/`.
- **PHP API for data persistence**: Link bunches are stored server-side via PHP; ensure the web server user has write access to the data directory.

## Links

- Source: https://codeberg.org/ladigitale/digibunch
- Website: https://ladigitale.dev/digibunch/
- Demo: https://ladigitale.dev/digibunch/#/b/5f67b12092b60
- Ladigitale suite: https://ladigitale.dev/
