---
name: digicard
description: Digicard recipe for open-forge. Simple graphic composition creator from Ladigitale (documentation in French). Static Node.js/Vite app with optional Pixabay API. AGPL-3.0. Source: https://codeberg.org/ladigitale/digicard
---

# Digicard

A simple online application to create graphic compositions — arrange text, images, and shapes on a canvas. Part of the Ladigitale educational suite. Purely static after build (no server-side component). Optionally uses Pixabay Search API for image search. Documentation in French. AGPL-3.0 licensed. Source: <https://codeberg.org/ladigitale/digicard>

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
| "Domain?" | FQDN | e.g. digicard.example.com |
| "Pixabay API key?" | String or blank | Optional — enables image search in the app |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Web server?" | NGINX / Apache2 | Serves static dist/ |
| "TLS?" | Yes / No | Handled by web server |

## Software-Layer Concerns

- **Fully static after build**: No Node.js, PHP, or database required in production.
- **Pixabay API key**: `VITE_PIXABAY_API` — embedded at build time. Without it, image search from Pixabay is disabled.
- **Build-time env vars**: All `VITE_`-prefixed variables are baked into the bundle at build time — changing them requires a rebuild.
- **No user accounts**: Compositions are client-side only; no server-side persistence.

## Deployment

### 1. Build

```bash
# Install Node.js (build machine only)
apt install nodejs npm

git clone https://codeberg.org/ladigitale/digicard.git /opt/digicard
cd /opt/digicard

# Optional: create build-time env file
cat > .env.production << 'EOF'
VITE_PIXABAY_API=your-pixabay-api-key-here
EOF

npm install
npm run build
# Static assets in dist/
```

### 2. Deploy static files

```bash
cp -r dist/ /var/www/digicard/
chown -R www-data:www-data /var/www/digicard/
```

### 3. NGINX configuration

```nginx
server {
    listen 443 ssl;
    server_name digicard.example.com;

    root /var/www/digicard;
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

1. `cd /opt/digicard && git pull`
2. `npm install`
3. `npm run build`
4. `cp -r dist/ /var/www/digicard/`

## Gotchas

- **VITE_PIXABAY_API is build-time**: Changing the API key requires a full rebuild — it's embedded in the JS bundle.
- **No persistence**: Compositions exist in the browser only — there's no save-to-server feature.
- **Node.js not needed in production**: Install Node.js only on the build machine; production server needs only a static file server.
- **French-language project**: UI and docs are in French.
- **Pixabay API is optional**: App works without it; image search via Pixabay is just a convenience feature.

## Links

- Source: https://codeberg.org/ladigitale/digicard
- Demo: https://ladigitale.dev/digicard/
- Pixabay API: https://pixabay.com/api/docs/
- Ladigitale suite: https://ladigitale.dev/
