---
name: digiview
description: Digiview recipe for open-forge. Distraction-free YouTube video viewer. PHP 8+ API + Vite frontend. Depends on third-party YouTube. Optional Google API key for video duration. From Ladigitale (documentation in French). AGPL-3.0. Source: https://codeberg.org/ladigitale/digiview
---

# Digiview

A simple application for viewing YouTube videos in a clean, distraction-free interface — strips ads, recommendations, and UI clutter. Part of the Ladigitale educational suite. PHP 8+ API serves as a proxy/helper; optional Google API key enables video duration metadata. Marked `depends_3rdparty: true` — requires YouTube to be accessible from the user's network. Documentation in French. AGPL-3.0 licensed. Source: <https://codeberg.org/ladigitale/digiview>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux | PHP 8+ + NGINX/Apache2 | Production |
| Any Linux | PHP 8+ + Node.js (build) | Node.js is build-time only |
| Docker | Custom | No official Docker image |

> **Third-party dependency**: Digiview embeds YouTube videos. Users must have YouTube access from their network.

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain?" | FQDN | e.g. digiview.example.com |
| "Authorized domains?" | Comma-separated or `*` | AUTHORIZED_DOMAINS |
| "Google API key?" | String or blank | VITE_GOOGLE_API — enables video duration display |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Web server?" | NGINX / Apache2 | Serves static dist/ + PHP API |
| "TLS?" | Yes / No | Handled by web server |

## Software-Layer Concerns

- **PHP 8+ required**: Provides the API backend.
- **Node.js is build-only**: Not needed in production.
- **VITE_GOOGLE_API**: Optional Google/YouTube Data API key — enables fetching video duration. Without it, duration is not displayed.
- **YouTube dependency**: The app embeds YouTube — users need YouTube access. Cannot work in YouTube-blocked environments.
- **AUTHORIZED_DOMAINS**: Build-time variable.
- **Privacy note**: No server-side YouTube proxy — video data comes directly from YouTube to the user's browser.

## Deployment

### 1. Install dependencies

```bash
apt install php8.1 php8.1-fpm nodejs npm
```

### 2. Clone, configure, and build

```bash
git clone https://codeberg.org/ladigitale/digiview.git /opt/digiview
cd /opt/digiview

cat > .env.production << 'EOF'
AUTHORIZED_DOMAINS=digiview.example.com
VITE_GOOGLE_API=
EOF

npm install
npm run build
```

### 3. Deploy

```bash
cp -r dist/ /var/www/digiview/
chown -R www-data:www-data /var/www/digiview/
```

### 4. NGINX configuration

```nginx
server {
    listen 443 ssl;
    server_name digiview.example.com;

    root /var/www/digiview;
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

1. `cd /opt/digiview && git pull`
2. `npm install && npm run build`
3. `cp -r dist/ /var/www/digiview/`

## Gotchas

- **YouTube-blocked networks**: App is non-functional in environments where YouTube is blocked (schools in some regions, China, etc.).
- **VITE_GOOGLE_API is optional**: App works without it; only video duration metadata is missing.
- **Build-time vars**: AUTHORIZED_DOMAINS and VITE_GOOGLE_API are baked in at build.
- **French-language project**: UI and docs are in French.
- **No official Docker image**: Build from source.

## Links

- Source: https://codeberg.org/ladigitale/digiview
- Website: https://ladigitale.dev/digiview/
- Demo: https://ladigitale.dev/digiview/
- Google API Console: https://console.developers.google.com/ (for YouTube Data API v3 key)
- Ladigitale suite: https://ladigitale.dev/
