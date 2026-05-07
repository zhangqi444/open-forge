---
name: digimindmap
description: Digimindmap recipe for open-forge. Simple online mind mapping app with PHP API backend. From Ladigitale (documentation in French). AGPL-3.0. Source: https://codeberg.org/ladigitale/digimindmap
---

# Digimindmap

A simple online mind mapping application based on a customized lightweight fork of the My Mind JS library. Part of the Ladigitale educational suite. Built with a Vite/Node.js frontend and PHP API backend for saving maps. Documentation in French. AGPL-3.0 licensed. Source: <https://codeberg.org/ladigitale/digimindmap>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux | PHP 8+ + NGINX/Apache2 | Production — PHP serves the API |
| Any Linux | PHP 8+ + Node.js (build) | Node.js is build-time only |
| Docker | Custom | No official Docker image |

> Node.js is a **build-time** dependency only. PHP 8+ is required for the API backend.

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain?" | FQDN | e.g. digimindmap.example.com |
| "Authorized domains?" | Comma-separated or `*` | AUTHORIZED_DOMAINS — controls POST/API access |
| "PHP version?" | 8.x | PHP 8.0+ required |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Web server?" | NGINX / Apache2 | Serves static dist/ + PHP API |
| "TLS?" | Yes / No | Handled by web server |

## Software-Layer Concerns

- **PHP 8+ required**: Serves the API for saving and sharing mind maps.
- **Node.js is build-only**: Not needed in production.
- **AUTHORIZED_DOMAINS**: Build-time variable (embedded via Vite) — changing requires a rebuild.
- **No database**: Data stored in flat files via PHP API.
- **Based on My Mind library**: Uses a customized fork of https://github.com/ondras/my-mind (MIT).
- **French documentation**: UI and docs are in French; Italian and Spanish translations contributed by community.

## Deployment

### 1. Install dependencies

```bash
apt install php8.1 php8.1-fpm nodejs npm
```

### 2. Clone, configure, and build

```bash
git clone https://codeberg.org/ladigitale/digimindmap.git /opt/digimindmap
cd /opt/digimindmap

cat > .env.production << 'EOF'
AUTHORIZED_DOMAINS=digimindmap.example.com
EOF

npm install
npm run build
# Static assets in dist/
```

### 3. Deploy

```bash
cp -r dist/ /var/www/digimindmap/
chown -R www-data:www-data /var/www/digimindmap/
```

### 4. NGINX configuration

```nginx
server {
    listen 443 ssl;
    server_name digimindmap.example.com;

    root /var/www/digimindmap;
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
nginx -t && systemctl reload nginx
```

## Upgrade Procedure

1. `cd /opt/digimindmap && git pull`
2. `npm install && npm run build`
3. `cp -r dist/ /var/www/digimindmap/`

## Gotchas

- **AUTHORIZED_DOMAINS is build-time**: Changing allowed domains requires a full JS rebuild.
- **Node.js not needed in production**: Build locally or in CI; deploy only `dist/` and PHP files.
- **French-language project**: UI defaults to French.
- **No official Docker image**: Build from source.

## Links

- Source: https://codeberg.org/ladigitale/digimindmap
- Website: https://ladigitale.dev/digimindmap/
- Demo: https://ladigitale.dev/digimindmap/#/
- My Mind library: https://github.com/ondras/my-mind
- Ladigitale suite: https://ladigitale.dev/
