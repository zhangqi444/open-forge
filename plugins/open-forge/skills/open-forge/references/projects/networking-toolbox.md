---
name: networking-toolbox
description: Networking Toolbox recipe for open-forge. 100+ offline-first networking tools and utilities in a single self-hosted web app. Covers DNS, IP, SSL, HTTP, routing, encoding, and more. No data leaves the browser. Built with SvelteKit. Upstream: https://github.com/Lissy93/networking-toolbox
---

# Networking Toolbox

A self-hosted collection of 100+ offline-first networking tools and utilities, all running in the browser with no data sent to any external server. Covers DNS lookups, IP analysis, SSL/TLS inspection, HTTP headers, subnet calculations, port scanning references, encoding/decoding, and more. Upstream: <https://github.com/Lissy93/networking-toolbox>. License: MIT.

Networking Toolbox is a SvelteKit static-output web application served by a minimal Node.js process. The entire tool suite runs client-side; the server only serves the app bundle. No database, no persistent state, no external API calls.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux host | Docker Compose | Recommended — single container, official image. |
| Any Linux host | Docker run | One-liner quick start. |
| Any platform | npm / Node.js | `npm install && npm start` for non-Docker deploys. |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "Which port should Networking Toolbox be accessible on?" | Integer | Default `3000`. |

No authentication, no secrets, and no persistent storage required — the app is purely client-side tooling.

## Software-layer concerns

### docker-compose.yml (from upstream)

```yaml
# compose.yml
# Source: https://github.com/Lissy93/networking-toolbox/blob/main/docker-compose.yml
services:
  app:
    image: lissy93/networking-toolbox:latest
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - PORT=3000
      - HOST=0.0.0.0
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "-qO-", "http://127.0.0.1:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

Source: <https://github.com/Lissy93/networking-toolbox/blob/main/docker-compose.yml>

### Quick start

```bash
# Docker run (one-liner)
docker run -p 3000:3000 lissy93/networking-toolbox:latest

# Docker Compose
curl -LO https://raw.githubusercontent.com/Lissy93/networking-toolbox/main/docker-compose.yml
docker compose up -d

# Open in browser
# http://<host>:3000
```

### Changing the port

To expose on a different host port, change the left side of the `ports` mapping:

```yaml
ports:
  - "8080:3000"   # expose on host port 8080
```

The `PORT` environment variable controls the internal container port (default `3000`); both values must match.

## Upgrade procedure

```bash
docker compose pull
docker compose up -d --force-recreate
```

No data volume to migrate — the app is stateless.

## Gotchas

- **All tools run client-side** — computations happen in the browser. The container only serves the static bundle; no sensitive data is processed server-side or sent to third parties.
- **Some tools require internet access from the browser** — tools such as live DNS lookups or SSL certificate fetches make requests from the user's browser, not from the container. If the browser is on an air-gapped network, those specific tools won't work, but offline/local tools (subnet calculator, encoding, CIDR math, etc.) will.
- **PORT env var and ports mapping must agree** — if you change `PORT` in the environment, update the container-side port in the `ports` mapping too, or the healthcheck and internal routing will break.
- **No authentication built in** — the app has no login screen. If you want to restrict access, place it behind a reverse proxy with HTTP Basic Auth, Authelia, or similar.

## Upstream docs

- GitHub: <https://github.com/Lissy93/networking-toolbox>
- Docker Hub: <https://hub.docker.com/r/lissy93/networking-toolbox>
- Live demo: <https://networking.lissy.me>
