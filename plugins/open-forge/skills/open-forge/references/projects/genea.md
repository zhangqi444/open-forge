---
name: genea-project
description: Genea recipe for open-forge. Privacy-focused genealogy/family tree tool that runs entirely client-side. Static file hosting only — no server-side components. Based on upstream README at https://github.com/genea-app/genea-app.
---

# Genea

Privacy-focused genealogy tool for building and editing family trees online. Runs entirely client-side — no server required for the app itself. Stores data in GEDCOM format. Can optionally use a self-hosted Git instance (Gitea, GitLab) or any GEDCOM-compatible file store for private data persistence. MIT. Upstream: https://github.com/genea-app/genea-app. Demo: https://www.genea.app/.

## Compatible install methods

| Method | When to use |
|---|---|
| Static file hosting (nginx/Apache/Caddy) | Host your own instance; full control over the version |
| Docker (nginx serving static files) | Containerised static hosting |
| Use hosted version | Just visit https://www.genea.app/ — no install needed |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "Self-host or use genea.app?" | Self-host / Use hosted | If using hosted, no install needed |
| config | "HTTPS domain?" | FQDN | Required for Web Crypto and browser security features |
| storage | "Store GEDCOM files where?" | Local browser / Git instance / File share | Git optional; GEDCOM files are portable |
| git | "Self-hosted Git instance URL?" | URL | Optional; Gitea or GitLab for private multi-device storage |

## Software-layer concerns

| Concern | Detail |
|---|---|
| Runtime | Pure frontend (Vue.js + WebAssembly Graphviz) — no backend required |
| Data format | GEDCOM 5.5.5 — portable, widely supported |
| Data storage | Browser local storage (default) or a Git repository |
| Server requirement | Only needs to serve static HTML/JS/CSS files — any web server works |
| HTTPS | Strongly recommended; required for Web Crypto APIs used by some browsers |
| Same-sex couples | GEDCOM extension: allows two FAM.HUSB or two FAM.WIFE records |

## Install: Static files (nginx)

Source: https://github.com/genea-app/genea-app/blob/main/README.md#installation

### 1. Get the release files

Download the latest release from https://github.com/genea-app/genea-app/releases or build from source:

```bash
# Option A: Download release
wget https://github.com/genea-app/genea-app/releases/latest/download/genea-app.zip
unzip genea-app.zip -d /var/www/html/genea

# Option B: Clone and build
git clone https://github.com/genea-app/genea-app.git
cd genea-app
npm install
npm run build
cp -r dist/ /var/www/html/genea
```

### 2. Serve with nginx

```nginx
server {
    listen 443 ssl;
    server_name genea.example.com;
    root /var/www/html/genea;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

### 3. That's it

Visit https://genea.example.com — the app loads entirely in the browser.

## Install: Docker (static serving)

```yaml
services:
  genea:
    image: nginx:alpine
    restart: unless-stopped
    ports:
      - "80:80"
    volumes:
      - ./genea-dist:/usr/share/nginx/html:ro
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
```

nginx.conf:
```nginx
server {
    listen 80;
    root /usr/share/nginx/html;
    index index.html;
    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

Pre-copy the built/extracted app files into ./genea-dist/ before starting.

## Optional: Git-backed storage

Genea can store GEDCOM files in a Git repository for multi-device access and history:

1. Set up a Gitea or GitLab instance (or use GitHub)
2. Create a private repository
3. In Genea: Settings → Storage → Git Repository → enter repo URL and credentials

This gives you version history of your family tree plus easy multi-device sync.

## Upgrade procedure

Static hosting: Download the new release zip, extract, replace the files in the web root.

Docker: Replace files in the mounted volume.

## Gotchas

- No server-side processing: All computation (tree rendering via Graphviz WASM, GEDCOM parsing) happens in the browser. This is a feature — privacy is guaranteed.
- Data lives in browser by default: Without a Git backend, family tree data is stored in browser local storage. Clearing browser data will delete it. Export GEDCOM regularly.
- GEDCOM is the export format: Use File → Export to download your family tree as a portable .ged file. Import it back in any other genealogy tool.
- try_files for SPA routing: nginx must serve index.html for all routes (try_files $uri $uri/ /index.html) — Genea is a single-page app.
- Same-sex couple handling: Genea uses a non-standard GEDCOM extension for same-sex couples — other tools may not import this correctly.

## Links

- GitHub: https://github.com/genea-app/genea-app
- Hosted demo: https://www.genea.app/
- Releases: https://github.com/genea-app/genea-app/releases
- GEDCOM 5.5.5 spec: https://www.gedcom.org/specs/GEDCOM555.zip
