---
name: digiread
description: Digiread recipe for open-forge. Clean-reading mode for online pages and articles using Mozilla's Readability. PHP API + Vite frontend. From Ladigitale (documentation in French). AGPL-3.0. Source: https://codeberg.org/ladigitale/digiread
---

# Digiread

A simple application to strip clutter from online pages and articles using Mozilla's Readability library, producing a clean, distraction-free reading view. Supports accessibility-focused fonts (Luciole, OpenDyslexic). Part of the Ladigitale educational suite. PHP API + Vite-built frontend. Documentation in French. Marked `depends_3rdparty: true` in ASD (fetches external URLs for reading). AGPL-3.0 licensed. Source: <https://codeberg.org/ladigitale/digiread>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux | PHP 8+ + NGINX/Apache2 | Production — PHP proxies/fetches external URLs |
| Any Linux | PHP 8+ + Node.js (build) | Node.js is build-time only |
| Docker | Custom | No official Docker image |

> **External dependency**: Digiread fetches external web pages server-side (via PHP) for Readability processing. Your server needs outbound HTTP access to the internet.

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain?" | FQDN | e.g. digiread.example.com |
| "Authorized domains?" | Comma-separated or `*` | AUTHORIZED_DOMAINS — controls POST/API access |
| "PHP version?" | 8.x | PHP 8.0+ required |
| "Outbound HTTP access?" | Yes | Required — server fetches external pages |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Web server?" | NGINX / Apache2 | Serves static dist/ + PHP API |
| "TLS?" | Yes / No | Handled by web server |

## Software-Layer Concerns

- **PHP 8+ required**: Serves the API that fetches and processes external web pages.
- **Outbound HTTP required**: The PHP API fetches URLs on behalf of the user — server needs internet access.
- **Node.js is build-only**: Not needed in production.
- **AUTHORIZED_DOMAINS**: Build-time variable — changing requires rebuild.
- **Privacy consideration**: URLs visited by users pass through your server (server-side fetch) — consider privacy policy implications.
- **Accessibility fonts**: Includes Luciole (for visually impaired) and OpenDyslexic — a notable educational feature.
- **Based on Mozilla Readability**: Uses https://github.com/mozilla/readability (Apache 2.0).

## Deployment

### 1. Install dependencies

```bash
apt install php8.1 php8.1-fpm php8.1-curl nodejs npm
```

### 2. Clone, configure, and build

```bash
git clone https://codeberg.org/ladigitale/digiread.git /opt/digiread
cd /opt/digiread

cat > .env.production << 'EOF'
AUTHORIZED_DOMAINS=digiread.example.com
EOF

npm install
npm run build
# Static assets in dist/
```

### 3. Deploy

```bash
cp -r dist/ /var/www/digiread/
chown -R www-data:www-data /var/www/digiread/
```

### 4. NGINX configuration

```nginx
server {
    listen 443 ssl;
    server_name digiread.example.com;

    root /var/www/digiread;
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

1. `cd /opt/digiread && git pull`
2. `npm install && npm run build`
3. `cp -r dist/ /var/www/digiread/`

## Gotchas

- **Server fetches external URLs**: The PHP API retrieves web pages on behalf of users — ensure outbound HTTP/HTTPS is allowed from the server. Content is processed server-side, not client-side.
- **Privacy implications**: All URLs users read pass through your server — document this in your privacy policy.
- **php-curl required**: The PHP fetch function needs `php-curl` extension installed.
- **AUTHORIZED_DOMAINS is build-time**: Must rebuild to change allowed domains.
- **French-language project**: UI and docs are in French.
- **No official Docker image**: Build from source.

## Links

- Source: https://codeberg.org/ladigitale/digiread
- Website: https://ladigitale.dev/digiread/
- Demo: https://ladigitale.dev/digiread/
- Mozilla Readability: https://github.com/mozilla/readability
- Ladigitale suite: https://ladigitale.dev/
