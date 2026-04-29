---
name: excalidraw-project
description: Excalidraw recipe for open-forge. MIT-licensed virtual whiteboard. Covers the official Docker image (excalidraw/excalidraw) single-container static-serve, optional excalidraw-room (collaboration), and excalidraw-json (export-to-PNG/SVG sidecar). Browser-native storage — no DB unless you add the collab/json services.
---

# Excalidraw (virtual whiteboard)

MIT-licensed, hand-drawn-style whiteboard. The core editor is a pure-client static React app — drawings live in the browser (IndexedDB) by default. No backend is required for solo use.

**Upstream README:** https://github.com/excalidraw/excalidraw/blob/master/README.md
**Upstream docs:** https://docs.excalidraw.com
**Self-host docs:** https://docs.excalidraw.com/docs/@excalidraw/excalidraw/installation

## What the repo actually ships

The main repo contains (a) the `@excalidraw/excalidraw` npm **library** for embedding in your own React app and (b) the [excalidraw-app](https://github.com/excalidraw/excalidraw/tree/master/excalidraw-app) at `excalidraw.com`. Related services live in sibling repos:

- **excalidraw/excalidraw** (this repo) — editor library + hosted app code. Docker Hub image: `excalidraw/excalidraw`.
- **excalidraw/excalidraw-room** — WebSocket collaboration server. Docker Hub image: `excalidraw/excalidraw-room`.
- **excalidraw/excalidraw-json** — headless export service (PNG/SVG). Docker Hub image: `excalidraw/excalidraw-json`.

Self-hosting "Excalidraw" usually means running the first image; adding the other two is only needed if you want real-time collaboration or server-side export.

The `docker-compose.yml` in the main repo is a **development** compose — it mounts source and runs in dev mode. Do **not** use it for production self-host. Use the pre-built Docker Hub image instead.

## Compatible combos

| Infra | Runtime | Status | Notes |
|---|---|---|---|
| localhost | Docker | ✅ default | `docker run -p 8080:80 excalidraw/excalidraw` |
| byo-vps | Docker | ✅ | Reverse-proxy with Caddy/Nginx for TLS |
| byo-vps | Docker Compose | ✅ | Only needed when adding `excalidraw-room` + `excalidraw-json` |
| aws/ec2 | Docker | ✅ | Static-serve; S3 + CloudFront is arguably nicer but non-canonical |
| kubernetes | community chart | ⚠️ | No official chart; community options exist |
| static host (Nginx, S3+CDN) | native | ✅ | Build once (`yarn build:app`), serve `/build` — editor works standalone |

Collaboration and JSON-export are **separate services**; treat them as optional modules.

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| dns | "Domain to host Excalidraw on?" | Free-text | e.g. `draw.example.com` |
| tls | "Email for Let's Encrypt notices?" | Free-text | |
| features | "Want real-time collaboration?" | AskUserQuestion: Yes / No | Adds `excalidraw-room` + wires `VITE_APP_WS_SERVER_URL` |
| features | "Want server-side PNG/SVG export?" | AskUserQuestion: Yes / No | Adds `excalidraw-json` |
| storage | "Want to back up drawings to the server (portal)?" | AskUserQuestion: Yes / No | If yes, use Excalidraw+; otherwise drawings are browser-local |

## Install methods

### 1. Docker (single container, editor only) — from Docker Hub

```bash
docker run -d --name excalidraw --restart unless-stopped \
  -p 8080:80 \
  excalidraw/excalidraw
```

Visit `http://localhost:8080/`. All drawing state lives in your browser's IndexedDB — switch browsers or clear storage and your local drawings are gone.

### 2. Docker Compose (editor + collaboration + JSON export)

> The upstream repo does not ship a prod compose file; this is synthesized from the three upstream Docker Hub images' individual READMEs.

```yaml
services:
  excalidraw:
    image: excalidraw/excalidraw:latest
    restart: unless-stopped
    ports:
      - "127.0.0.1:8080:80"
    environment:
      # Collaboration server WebSocket URL
      VITE_APP_WS_SERVER_URL: wss://collab.example.com
      # JSON / export service
      VITE_APP_BACKEND_V2_GET_URL: https://api.example.com/api/v2/
      VITE_APP_BACKEND_V2_POST_URL: https://api.example.com/api/v2/post/

  excalidraw-room:
    image: excalidraw/excalidraw-room:latest
    restart: unless-stopped
    ports:
      - "127.0.0.1:3002:80"

  excalidraw-json:
    image: excalidraw/excalidraw-json:latest
    restart: unless-stopped
    ports:
      - "127.0.0.1:8888:8888"
```

Front it all with a single reverse proxy mapping the three services to different hostnames (editor, `collab.`, `api.`).

### 3. Build static + host on any CDN

```bash
git clone https://github.com/excalidraw/excalidraw.git
cd excalidraw
yarn
yarn build:app
# Output in build/
```

Upload `build/` to S3 / Cloudflare Pages / Netlify / Nginx root. End-to-end encryption + client-only editor means a CDN is the cheapest viable host.

### 4. Embed the npm library

If you're integrating the editor into your own React app rather than self-hosting the full app, the README quick-start applies — `npm install @excalidraw/excalidraw`. Not a "deploy" in the open-forge sense; noting for completeness.

## Software-layer concerns

### Env vars (editor image)

Most env vars prefixed `VITE_APP_*` — they're baked in at build time of the Docker image. For the published `excalidraw/excalidraw` image, they're already set to the `excalidraw.com` defaults. Overriding them typically means **building your own image** from the repo with the env file.

| Var | Purpose |
|---|---|
| `VITE_APP_WS_SERVER_URL` | Collab WebSocket server (e.g. `wss://collab.example.com`) |
| `VITE_APP_BACKEND_V2_GET_URL` | Shared-drawings GET endpoint |
| `VITE_APP_BACKEND_V2_POST_URL` | Shared-drawings POST endpoint |
| `VITE_APP_FIREBASE_CONFIG` | Firebase config for Excalidraw+'s portal (skip for self-host) |
| `VITE_APP_PORTAL_URL` | Portal URL (skip for self-host) |

Full list: https://github.com/excalidraw/excalidraw/blob/master/.env.development

For self-host, the pragmatic answer: use the published image as-is unless you need collaboration across your own domain.

### Paths

None — the editor is stateless static assets. All user data is browser-side (IndexedDB). Back up by **exporting `.excalidraw` files**, not by volumes.

### Reverse proxy

Standard. Caddy:

```caddy
draw.example.com {
  reverse_proxy 127.0.0.1:8080
}
collab.example.com {
  reverse_proxy 127.0.0.1:3002
}
api.example.com {
  reverse_proxy 127.0.0.1:8888
}
```

WebSocket passthrough works out of the box in Caddy; for Nginx you need the `proxy_http_version 1.1 / Upgrade` headers.

## Upgrade procedure

1. `docker pull excalidraw/excalidraw:latest` (and collab/json if used).
2. `docker compose up -d` (or re-run the single `docker run`).
3. No DB, no migrations — upgrade is trivial. User data is in the browser.
4. Pin tags in compose (`excalidraw/excalidraw:v0.17.x`) for reproducibility; upstream tags releases roughly weekly.

## Gotchas

- **Drawings are browser-local by default.** Users assume "open source whiteboard" means server-hosted; it isn't, without the portal/Excalidraw+. Set expectations.
- **The repo's `docker-compose.yml` is dev-only.** It mounts source + runs in dev mode. Ignore it for self-host; use the Docker Hub image.
- **`VITE_APP_*` is baked at build time.** Overriding WebSocket/API URLs for your domain means building a custom image with your `.env`, not setting env vars at runtime on the published image.
- **`excalidraw-room` uses WebSockets.** Make sure your reverse proxy forwards WS upgrade headers.
- **End-to-end encryption is client-side.** If you enable the collab server, you're *not* able to inspect drawings on the server — that's the point. Don't treat excalidraw-room as a content moderation point.
- **SVG/PNG export via `excalidraw-json` is headless Chromium.** The image is heavier than the editor; expect a few hundred MB.
- **`/build` is all you need** — no server required if serving static.

## TODO — verify on subsequent deployments

- [ ] Actually exercise the 3-service compose end-to-end and confirm collab + export work.
- [ ] Evaluate a Cloudflare-Pages-only path for the editor (no Docker at all).
- [ ] Confirm community Helm charts are current; flag most-active one.
- [ ] Excalidraw+ self-host status — historically not self-hostable; re-check.
