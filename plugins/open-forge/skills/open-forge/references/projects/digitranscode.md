---
name: digitranscode
description: Digitranscode recipe for open-forge. Browser-based audio and video format converter using FFMPEG.wasm — all processing client-side. COOP/COEP headers and HTTPS required. From Ladigitale (documentation in French). AGPL-3.0. Source: https://codeberg.org/ladigitale/digitranscode
---

# Digitranscode

A simple browser-based application to convert audio and video files between formats using FFMPEG.wasm — all transcoding happens client-side in the user's browser. No server-side media processing. Part of the Ladigitale educational suite. Sister app to Digicut and Digimerge. Documentation in French. AGPL-3.0 licensed. Source: <https://codeberg.org/ladigitale/digitranscode>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux | NGINX / Apache2 serving static files | Production — all processing is client-side |
| Any Linux | Node.js (build only) | Vite build tooling only |
| Docker | Any static file server | Serve the dist/ directory |

> All media transcoding runs **in the user's browser** via FFMPEG.wasm (WebAssembly). No server-side transcoding occurs.

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain?" | FQDN | e.g. digitranscode.example.com |
| "Web server?" | NGINX / Apache2 | Serves static dist/ |
| "TLS?" | Yes / No | HTTPS required for SharedArrayBuffer |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| (no additional inputs) | — | No server-side config needed |

## Software-Layer Concerns

- **Fully static after build**: No server runtime, database, or PHP — static files only.
- **HTTPS required**: FFMPEG.wasm uses `SharedArrayBuffer`, available only in secure contexts.
- **COOP/COEP headers required**: `Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp` must be set or FFMPEG.wasm will fail.
- **Client-side only**: Files never leave the user's browser during transcoding.
- **Large WASM bundle**: FFMPEG.wasm adds ~30–50 MB to the initial page load.
- **Dev command is `npm run dev`**: Standard Vite dev server (differs from Digicut/Digimerge which use `serve`).

## Deployment

### 1. Build

```bash
apt install nodejs npm

git clone https://codeberg.org/ladigitale/digitranscode.git /opt/digitranscode
cd /opt/digitranscode
npm install
npm run build
# Static assets in dist/
```

### 2. Deploy static files

```bash
cp -r dist/ /var/www/digitranscode/
chown -R www-data:www-data /var/www/digitranscode/
```

### 3. NGINX configuration (with required COOP/COEP headers)

```nginx
server {
    listen 443 ssl;
    server_name digitranscode.example.com;

    root /var/www/digitranscode;
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

1. `cd /opt/digitranscode && git pull`
2. `npm install && npm run build`
3. `cp -r dist/ /var/www/digitranscode/`

## Gotchas

- **COOP/COEP headers mandatory**: Without these, `SharedArrayBuffer` is disabled and FFMPEG.wasm fails silently.
- **HTTPS required**: HTTP deployments will not work for transcoding.
- **Large initial load**: FFMPEG.wasm is ~30–50 MB — consider caching headers for repeat visits.
- **Browser compatibility**: Requires modern browser with WebAssembly + SharedArrayBuffer support.
- **Client resource usage**: Transcoding large files consumes significant browser CPU/RAM.
- **French-language project**: UI and docs are in French.

## Links

- Source: https://codeberg.org/ladigitale/digitranscode
- Website: https://ladigitale.dev/digitranscode
- Demo: https://ladigitale.dev/digitranscode
- FFMPEG.wasm: https://github.com/ffmpegwasm/ffmpeg.wasm
- Ladigitale suite: https://ladigitale.dev/
