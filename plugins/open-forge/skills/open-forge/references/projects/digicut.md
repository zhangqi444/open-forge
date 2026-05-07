---
name: digicut
description: Digicut recipe for open-forge. Browser-based audio and video cutter using FFMPEG.wasm — no server-side processing required. From Ladigitale (documentation in French). AGPL-3.0. Source: https://codeberg.org/ladigitale/digicut
---

# Digicut

A simple browser-based application to cut audio and video files using FFMPEG.wasm — all processing happens client-side in the browser. No server required beyond serving static files. Part of the Ladigitale educational suite. Documentation in French. AGPL-3.0 licensed. Source: <https://codeberg.org/ladigitale/digicut>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux | NGINX / Apache2 serving static files | Production — all processing is client-side |
| Any Linux | Node.js (build only) | Vite build tooling only |
| Docker | Any static file server | Serve the dist/ directory |

> All media processing runs **in the user's browser** via FFMPEG.wasm (WebAssembly). No server-side media processing occurs.

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain?" | FQDN | e.g. digicut.example.com |
| "Web server?" | NGINX / Apache2 | Serves static dist/ |
| "TLS?" | Yes / No | HTTPS required for SharedArrayBuffer (FFMPEG.wasm) |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| (no additional inputs) | — | No server-side config needed |

## Software-Layer Concerns

- **Fully static**: No server-side runtime, database, or API — only static file serving.
- **HTTPS required**: FFMPEG.wasm uses `SharedArrayBuffer` which requires a secure context (HTTPS) and specific COOP/COEP headers.
- **COOP/COEP headers required**: Must set `Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp` headers, or FFMPEG.wasm will fail to initialize.
- **Client-side only**: Files never leave the user's browser — all cutting happens locally.
- **Large WASM bundle**: FFMPEG.wasm adds significant bundle size (~30–50 MB) — ensure adequate bandwidth for initial load.

## Deployment

### 1. Build

```bash
apt install nodejs npm

git clone https://codeberg.org/ladigitale/digicut.git /opt/digicut
cd /opt/digicut
npm install
npm run build
# Static assets in dist/
```

### 2. Deploy static files

```bash
cp -r dist/ /var/www/digicut/
chown -R www-data:www-data /var/www/digicut/
```

### 3. NGINX configuration (with required COOP/COEP headers)

```nginx
server {
    listen 443 ssl;
    server_name digicut.example.com;

    root /var/www/digicut;
    index index.html;

    # Required for FFMPEG.wasm SharedArrayBuffer
    add_header Cross-Origin-Opener-Policy "same-origin" always;
    add_header Cross-Origin-Embedder-Policy "require-corp" always;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

```bash
nginx -t && systemctl reload nginx
```

## Upgrade Procedure

1. `cd /opt/digicut && git pull`
2. `npm install`
3. `npm run build`
4. `cp -r dist/ /var/www/digicut/`

## Gotchas

- **COOP/COEP headers are mandatory**: Without `Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp`, `SharedArrayBuffer` is unavailable and FFMPEG.wasm fails silently or with a cryptic error.
- **HTTPS required**: `SharedArrayBuffer` is only available in secure contexts (HTTPS). HTTP deployments will not work.
- **Large initial download**: FFMPEG.wasm is large — consider caching headers and CDN if serving many users.
- **Browser compatibility**: Requires a modern browser with WebAssembly + SharedArrayBuffer support (Chrome 92+, Firefox 79+, Safari 15.2+).
- **Client resources**: Processing large video files consumes significant browser CPU/RAM — not suitable for very large files on low-end devices.
- **French-language project**: UI and docs are in French.

## Links

- Source: https://codeberg.org/ladigitale/digicut
- Website: https://ladigitale.dev/digicut/
- FFMPEG.wasm: https://github.com/ffmpegwasm/ffmpeg.wasm
- Ladigitale suite: https://ladigitale.dev/
