---
name: digiface
description: Digiface recipe for open-forge. Browser-based avatar creator using the Avataaars library. From Ladigitale (documentation in French). Static app, no server runtime needed. AGPL-3.0. Source: https://codeberg.org/ladigitale/digiface
---

# Digiface

A simple online application to create customizable cartoon avatars using the Avataaars library. Part of the Ladigitale educational suite. Purely static after build — no server-side component. Multi-language (French, Italian, German). AGPL-3.0 licensed. Source: <https://codeberg.org/ladigitale/digiface>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux | NGINX / Apache2 serving static files | Production — no server runtime needed |
| Any Linux | Node.js (build only) | Vite build tooling only |
| Docker | Any static file server | Serve the dist/ directory |

> Node.js is a **build-time** dependency only — the deployed app is purely static HTML/JS/CSS.

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain?" | FQDN | e.g. digiface.example.com |
| "Web server?" | NGINX / Apache2 | Serves static dist/ |
| "TLS?" | Yes / No | Handled by web server |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| (no additional inputs) | — | No server-side config needed |

## Software-Layer Concerns

- **Fully static after build**: No Node.js, PHP, or database required in production.
- **No server persistence**: Avatars are generated and exported client-side — no save-to-server functionality.
- **Avataaars library**: Uses the open-source Avataaars React component for avatar generation.
- **No build-time env vars required**: Unlike other digi* apps, Digiface has no mandatory `VITE_`-prefixed configuration.

## Deployment

### 1. Build

```bash
apt install nodejs npm

git clone https://codeberg.org/ladigitale/digiface.git /opt/digiface
cd /opt/digiface
npm install
npm run build
# Static assets in dist/
```

### 2. Deploy static files

```bash
cp -r dist/ /var/www/digiface/
chown -R www-data:www-data /var/www/digiface/
```

### 3. NGINX configuration

```nginx
server {
    listen 443 ssl;
    server_name digiface.example.com;

    root /var/www/digiface;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

```bash
nginx -t && systemctl reload nginx
```

## Upgrade Procedure

1. `cd /opt/digiface && git pull`
2. `npm install`
3. `npm run build`
4. `cp -r dist/ /var/www/digiface/`

## Gotchas

- **Node.js not needed in production**: Install Node.js only on the build machine.
- **No server persistence**: Users must export/download their avatar — there's no account or save system.
- **French-language primary**: UI defaults to French; Italian and German translations are community-contributed.
- **No official Docker image**: Build from source and serve statically.

## Links

- Source: https://codeberg.org/ladigitale/digiface
- Website: https://ladigitale.dev/digiface/
- Demo: https://ladigitale.dev/digiface/
- Avataaars library: https://getavataaars.com/
- Ladigitale suite: https://ladigitale.dev/
