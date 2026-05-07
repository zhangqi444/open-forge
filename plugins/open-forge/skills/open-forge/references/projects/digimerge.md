---
name: digimerge
description: Digimerge recipe for open-forge. Browser-based audio and video file merger using FFMPEG.wasm — all processing client-side, no server runtime needed. From Ladigitale (documentation in French). AGPL-3.0. Source: https://codeberg.org/ladigitale/Digimerge
---

# Digimerge

A simple browser-based application to assemble (merge/concatenate) audio and video files using FFMPEG.wasm — all processing happens client-side in the browser. No server-side media processing. Part of the Ladigitale educational suite. Sister app to Digicut. Documentation in French. AGPL-3.0 licensed. Source: <https://codeberg.org/ladigitale/Digimerge>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux | NGINX / Apache2 serving static files | Production — all processing is client-side |
| Any Linux | Node.js (build only) | Vite build tooling only |
| Docker | Any static file server | Serve the dist/ directory |

> All media processing runs **in the user's browser** via FFMPEG.wasm (WebAssembly). No server-side transcoding occurs.

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain?" | FQDN | e.g. digimerge.example.com |
| "Web server?" | NGINX / Apache2 | Serves static dist/ |
| "TLS?" | Yes / No | HTTPS required for SharedArrayBuffer (FFMPEG.wasm) |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| (no additional inputs) | — | No server-side config needed |

## Software-Layer Concerns

- **Fully static**: No server-side runtime, database, or API — only static file serving.
- **HTTPS required**: FFMPEG.wasm uses `SharedArrayBuffer` which requires a secure context (HTTPS).
- **COOP/COEP headers required**: Must set `Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp` or FFMPEG.wasm will fail.
- **Client-side processing only**: Files never leave the user's browser.
- **Large WASM bundle**: FFMPEG.wasm adds ~30–50 MB to the initial load.
- **Dev command is `npm run serve`**: Note the dev server command differs from other digi* apps (uses `serve` not `dev`).

## Deployment

### 1. Build

```bash
apt install nodejs npm

# Note: repo name uses capital D — Digimerge
git clone https://codeberg.org/ladigitale/Digimerge.git /opt/digimerge
cd /opt/digimerge
npm install
npm run build
# Static assets in dist/
```

### 2. Deploy static files

```bash
cp -r dist/ /var/www/digimerge/
chown -R www-data:www-data /var/www/digimerge/
```

### 3. NGINX configuration (with required COOP/COEP headers)

```nginx
server {
    listen 443 ssl;
    server_name digimerge.example.com;

    root /var/www/digimerge;
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

1. `cd /opt/digimerge && git pull`
2. `npm install`
3. `npm run build`
4. `cp -r dist/ /var/www/digimerge/`

## Gotchas

- **Repo name is capitalized**: `Digimerge` (capital D) on Codeberg — `git clone` is case-sensitive.
- **COOP/COEP headers mandatory**: Without these, `SharedArrayBuffer` is unavailable and FFMPEG.wasm silently fails.
- **HTTPS required**: HTTP deployments will not work for merging.
- **Dev command**: `npm run serve` (not `npm run dev` as in most digi* apps).
- **Client resources**: Merging large files consumes significant browser CPU/RAM.
- **French-language project**: UI and docs are in French.

## Links

- Source: https://codeberg.org/ladigitale/Digimerge
- Website: https://ladigitale.dev/digimerge/
- Demo: https://ladigitale.dev/digimerge/
- FFMPEG.wasm: https://github.com/ffmpegwasm/ffmpeg.wasm
- Ladigitale suite: https://ladigitale.dev/
