---
name: digiwords
description: Digiwords recipe for open-forge. Simple online word cloud creator. PHP 8+ API + Vite frontend. No database required. From Ladigitale (documentation in French). AGPL-3.0. Source: https://codeberg.org/ladigitale/digiwords
---

# Digiwords

A simple online application for creating word clouds. Part of the Ladigitale educational suite. Lightweight: PHP 8+ API backend with a Vite-built frontend — no database, no Redis, no Composer. Supports many font styles. Documentation in French. AGPL-3.0 licensed. Source: <https://codeberg.org/ladigitale/digiwords>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux | PHP 8+ + NGINX/Apache2 | Production |
| Docker | PHP-FPM + NGINX | Serve dist/ with PHP-FPM |

> Node.js is a **build-time** dependency only. No database or Composer needed.

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain?" | FQDN | e.g. digiwords.example.com |
| "Authorized domains?" | Comma-separated or `*` | AUTHORIZED_DOMAINS — build-time |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Web server?" | NGINX / Apache2 | |
| "TLS?" | Yes / No | Handled by web server |

## Software-Layer Concerns

- **PHP 8+ required**: API backend for word cloud generation.
- **No Composer**: No PHP package dependencies.
- **No database**: Stateless — word clouds are generated on demand, not persisted server-side.
- **Node.js build-only**: Vite build tooling only — not needed in production.
- **AUTHORIZED_DOMAINS**: Build-time variable embedded in JS bundle.
- **Many bundled fonts**: Includes ~20 Google Fonts (Apache 2.0), OpenDyslexic (SIL OFL) — all client-side only.

## Deployment

### 1. Install dependencies

```bash
apt install php8.1 php8.1-fpm nodejs npm
```

### 2. Clone, configure, and build

```bash
git clone https://codeberg.org/ladigitale/digiwords.git /opt/digiwords
cd /opt/digiwords

cat > .env.production << 'EOF'
AUTHORIZED_DOMAINS=digiwords.example.com
EOF

npm install
npm run build
```

### 3. Deploy

```bash
cp -r dist/ /var/www/digiwords/
chown -R www-data:www-data /var/www/digiwords/
```

### 4. NGINX configuration

```nginx
server {
    listen 443 ssl;
    server_name digiwords.example.com;

    root /var/www/digiwords;
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

## Upgrade Procedure

1. `cd /opt/digiwords && git pull`
2. `npm install && npm run build`
3. `cp -r dist/ /var/www/digiwords/`

## Gotchas

- **Stateless**: Word clouds are not stored server-side — users must save/export themselves.
- **AUTHORIZED_DOMAINS is build-time**: Rebuild required to change allowed domains.
- **Large font bundle**: Many decorative fonts are bundled — initial page load may be slow on slow connections.
- **French-language project**: UI and docs are in French. Includes Italian translation (community contributed).

## Links

- Source: https://codeberg.org/ladigitale/digiwords
- Website: https://ladigitale.dev/digiwords/
- Demo: https://ladigitale.dev/digiwords/
- Ladigitale suite: https://ladigitale.dev/
