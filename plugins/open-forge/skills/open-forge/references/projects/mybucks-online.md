---
name: mybucks-online
description: Mybucks.online recipe for open-forge. Seedless, browser-based, self-custodial crypto wallet — private key derived from passphrase+PIN using Scrypt. Static deployment only. Source: https://github.com/mybucks-online/app
---

# Mybucks.online

A seedless, self-custodial cryptocurrency wallet that runs entirely in the browser. Generates a private key deterministically from a passphrase + PIN using the Scrypt KDF — no seed phrases, no storage, no server-side tracking. Closing or refreshing the browser leaves no footprint. MIT licensed, Node.js/React app. Upstream: <https://github.com/mybucks-online/app>. Live demo: <https://app.mybucks.online>

> ℹ️ **Security model**: The private key is derived client-side from credentials using Scrypt (N=2^17). Security depends entirely on passphrase and PIN strength. There is no recovery mechanism — a forgotten passphrase means lost funds.

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Any webserver | Static file serving | Build once, serve as static HTML/JS/CSS |
| Any CDN / static host | Static files | Vercel, Netlify, S3, Cloudflare Pages, etc. |
| Any Linux VPS | Docker (nginx static) | Wrap built assets in nginx container |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain to serve from?" | FQDN | e.g. wallet.example.com |
| "HTTPS required?" | Yes (always) | Crypto wallet must be served over HTTPS |

## Software-Layer Concerns

- **Fully static after build**: No server-side logic, no database, no API calls for key management.
- **Zero storage**: No localStorage, no cookies, no server sessions. Each page load re-derives the key from credentials.
- **Client-side only**: All cryptography runs in the browser — the server never sees credentials or keys.
- **No recovery mechanism**: Lost passphrase = lost wallet permanently. Users must understand this.
- **1-click gifting**: Can share a wallet as a URL — the recipient opens the URL and takes ownership.
- **Supported networks**: Check upstream for current supported blockchains (Ethereum-compatible networks at minimum).
- **Build required**: App is built with Vite — must `npm install && npm run build` before serving.

## Deployment

### Static build + NGINX

```bash
git clone https://github.com/mybucks-online/app.git
cd app
npm install
npm run build
# dist/ contains the built static files
```

```nginx
server {
    listen 443 ssl;
    server_name wallet.example.com;
    root /var/www/mybucks/dist;
    index index.html;
    try_files $uri $uri/ /index.html;  # SPA routing
}
```

### Docker Compose (nginx static)

```yaml
services:
  mybucks:
    image: nginx:alpine
    ports:
      - "8080:80"
    volumes:
      - ./dist:/usr/share/nginx/html:ro
    restart: unless-stopped
```

Build first: `npm run build`, then start the container.

## Upgrade Procedure

1. `git pull` to get new source.
2. `npm install && npm run build` to rebuild.
3. Replace the served static files with the new `dist/` contents.
4. No data migration needed — stateless by design.

## Gotchas

- **HTTPS mandatory**: A crypto wallet served over HTTP is a severe security risk — browsers may also block crypto APIs on non-HTTPS origins.
- **No seed phrase / no recovery**: This is by design — users must treat their passphrase+PIN like a private key. Losing it means losing access permanently.
- **Passphrase strength is security**: Scrypt makes brute force expensive but a weak passphrase is still attackable. Enforce strong credentials.
- **SPA routing**: Requires the webserver to serve `index.html` for all routes (try_files /index.html for NGINX).
- **Gifting via URL**: Wallet-as-URL feature embeds credentials in the URL — advise users to transfer funds out immediately after using a gifted wallet URL.

## Links

- Source: https://github.com/mybucks-online/app
- Website: https://mybucks.online
- Live app: https://app.mybucks.online
- Releases: https://github.com/mybucks-online/app/releases
