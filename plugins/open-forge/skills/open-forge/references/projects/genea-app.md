---
name: genea-app
description: Genea.app recipe for open-forge. Privacy-focused browser-based family tree builder. No server required for the app itself — static files served over HTTPS. Stores data in GEDCOM format. Source: https://github.com/genea-app/genea-app
---

# Genea.app

Browser-based family tree builder with a focus on privacy. Authors and edits genealogy data in the standard GEDCOM format. All processing happens in the browser — no server-side components, no data sent externally. Supports same-sex marriages. Renders trees using Graphviz compiled to WebAssembly. Vue.js. MIT licensed.

Optional: back up GEDCOM files to a self-hosted Git server (Gitea, Forgejo, GitLab) or manage them as plain files.

Upstream: https://github.com/genea-app/genea-app | Live: https://www.genea.app | Android: Google Play

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any | Static file server (HTTPS) | HTTPS required for PWA features |
| Any | Nginx / Caddy | Serve the built static files |
| Any | GitHub Pages / Cloudflare Pages | No-effort hosting option |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| deploy | HTTPS URL | App must be served over HTTPS for full PWA functionality |
| optional | Git server URL | For syncing GEDCOM files across devices via Gitea/GitLab |

## Software-layer concerns

- No backend required: Genea is a fully static SPA; the server just serves HTML/JS/CSS files
- GEDCOM storage: family tree data saved as .ged files locally or synced via Git integration
- HTTPS required: PWA features (offline, install prompt) only work over HTTPS; HTTP fine for testing
- Git sync (optional): connect to any Git host to store GEDCOM files and sync across devices
- No database, no user accounts, no authentication

## Install -- Nginx (static)

```bash
git clone https://github.com/genea-app/genea-app.git
cd genea-app
npm install
npm run build   # outputs to dist/
cp -r dist/ /var/www/genea/
```

nginx config:

```nginx
server {
    listen 443 ssl;
    server_name genea.example.com;
    root /var/www/genea;
    index index.html;
    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

## Install -- Docker (Nginx)

Build static files first (npm run build), then:

```yaml
services:
  genea:
    image: nginx:alpine
    restart: unless-stopped
    ports:
      - 8080:80
    volumes:
      - ./dist:/usr/share/nginx/html:ro
```

## Upgrade procedure

```bash
cd genea-app
git pull
npm install
npm run build
cp -r dist/ /var/www/genea/
```

## Gotchas

- HTTPS is practically required: browsers block PWA install and some storage APIs over plain HTTP. Use Caddy or Let's Encrypt for automatic TLS.
- Data lives in the browser: GEDCOM files are stored in browser local storage and/or exported as files. Clearing browser data or switching devices loses the tree unless you export first or use Git sync.
- Git sync setup: create a repo on your Gitea/Forgejo instance and connect it from Genea settings. The GEDCOM file is committed/pulled on each save/load.
- GEDCOM quirk: Genea deviates slightly from the standard for same-sex marriages (FAM can have two HUSB or two WIFE records). Importing these files into other tools may produce warnings.

## Links

- Source: https://github.com/genea-app/genea-app
- Live demo: https://www.genea.app
- GEDCOM 5.5.5 spec: https://www.gedcom.org/specs/GEDCOM555.zip
- GEDCOM sample files: https://www.gedcom.org/samples.html
