---
name: omni-tools
description: OmniTools is a self-hosted, privacy-first collection of 100+ web-based utility tools — image/video/PDF/text/math/data processing — all executed client-side with no data leaving the browser. Single 28 MB Docker image. Upstream: https://github.com/iib0011/omni-tools
---

# OmniTools

OmniTools is a **self-hosted web toolbox** with 100+ everyday browser utilities: image resizing and conversion, video trimming and reversal, PDF splitting and merging, text case conversion and formatting, JSON/CSV/XML tools, date calculators, math utilities, and more. All processing runs **client-side** in the browser — no file is ever uploaded to the server. The Docker image is 28 MB (a static nginx serving a React/TypeScript SPA).

Upstream: <https://github.com/iib0011/omni-tools>  
Demo: <https://omnitools.app>  
Docker Hub: `iib0011/omni-tools`  
License: MIT

## What it does

- **Image tools** — resize, convert format, edit, compress
- **Video tools** — trim, reverse, convert
- **Audio tools** — extract, convert
- **PDF tools** — split, merge, edit, compress
- **Text / list tools** — case converters, list shuffler, text formatters, word/character counters
- **Date and time tools** — date calculators, timezone converters
- **Math tools** — prime number generation, Ohm's law calculator
- **Data tools** — JSON formatter/diff, CSV tools, XML tools, Base64 encode/decode, UUID generator
- **Color tools** — color picker, converters
- **Privacy-first** — all processing happens in the browser; the server only serves static files

## Architecture

- **Single container** — nginx serving a pre-built React/TypeScript/Vite SPA
- **Port**: `80` (container) → typically mapped to `8080` on host
- **Image size**: ~28 MB
- **No database, no backend API** — pure static file server

## Compatible install methods

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux host | Docker (single container) | Primary method. |
| Any Linux host | Docker Compose | Convenience wrapper; same single image. |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Host port to expose OmniTools on?" | Default `8080`. Maps to container port `80`. |
| preflight | "Domain to serve OmniTools on?" | e.g. `tools.example.com`. Front with a reverse proxy for HTTPS. |

## Docker run (quick start)

```bash
docker run -d \
  --name omni-tools \
  --restart unless-stopped \
  -p 8080:80 \
  iib0011/omni-tools:latest
```

Access at `http://<host>:8080`.

## Docker Compose

```yaml
# compose.yaml
services:
  omni-tools:
    image: iib0011/omni-tools:latest
    container_name: omni-tools
    restart: unless-stopped
    ports:
      - "${OMNI_TOOLS_PORT:-8080}:80"
```

```bash
docker compose up -d
```

## Reverse proxy

OmniTools is a static site — front with Caddy, Traefik, or nginx for HTTPS termination.

**Caddy example:**

```caddyfile
tools.example.com {
    reverse_proxy localhost:8080
}
```

**nginx example:**

```nginx
server {
    listen 443 ssl;
    server_name tools.example.com;
    # ssl_certificate / ssl_certificate_key ...

    location / {
        proxy_pass http://localhost:8080;
    }
}
```

## Upgrade

```bash
docker compose pull && docker compose up -d
```

No database or persistent state — upgrade is stateless.

## Gotchas

- **No persistent state** — OmniTools stores no user data; each session is independent. Upgrading or restarting the container loses nothing.
- **All processing is client-side** — the server only serves the SPA bundle; files are never transmitted to the server. Network traffic shows only the initial HTML/JS/CSS load.
- **Lightweight** — at ~28 MB the image is suitable for low-resource hosts (Raspberry Pi, low-tier VPS).
- **No configuration needed** — beyond the host port, there is nothing to configure for a basic deploy.
