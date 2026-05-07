---
name: changedetection-io
description: changedetection.io recipe for open-forge. Self-hosted website change monitoring — watch any web page for content changes and get notified via email, Slack, Discord, webhooks, and more. Apache-2.0. Source: https://github.com/dgtlmoon/changedetection.io
---

# changedetection.io

A self-hosted web page change monitoring service. Watch any URL for content changes and receive instant notifications via email, Slack, Discord, Telegram, webhooks, Matrix, and 80+ other services (via Apprise). Supports CSS/XPath element filtering, JavaScript-rendered pages (via Playwright), visual selector tool, and AI-powered diff summaries. Apache-2.0 licensed. Source: <https://github.com/dgtlmoon/changedetection.io>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux | Docker Compose | Primary supported deployment |
| Any Linux | pip / Python venv | Manual install supported |
| Raspberry Pi | Docker Compose | ARM image available |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain?" | FQDN | e.g. changes.example.com |
| "Data directory?" | Path | Where watches and snapshots are stored |
| "Port?" | Number | Default 5000 |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Enable Playwright (JS rendering)?" | Yes / No | Requires separate browser container |
| "Notification channels?" | list | Apprise URLs (email, Slack, Discord, etc.) |
| "TLS?" | Yes / No | Handled by reverse proxy |

## Software-Layer Concerns

- **Stateless-ish**: All watch data stored under `/datastore` — back up this directory.
- **Playwright support**: JavaScript-rendered page detection requires a Playwright/browser container (sockpuppetbrowser or Selenium). Add to Compose for full JS support.
- **Apprise notifications**: Uses [Apprise](https://github.com/caronc/apprise) — supports 80+ notification services via URL schemes (e.g. `discord://webhook-id/webhook-token`, `mailto://user:pass@smtp.example.com`).
- **BASE_URL**: Set to your public URL so notification links are correct.
- **Proxy support**: HTTP/SOCKS proxy configurable per-watch or globally.
- **Rate limiting**: Be considerate — changedetection checks pages on a schedule; excessive frequency may get your IP blocked by target sites.
- **AI summaries**: Optional LLM integration (OpenAI, Ollama, etc.) for plain-language change descriptions — configured per-watch.

## Deployment

### Docker Compose (recommended)

```yaml
services:
  changedetection:
    image: ghcr.io/dgtlmoon/changedetection.io
    container_name: changedetection
    restart: unless-stopped
    volumes:
      - ./datastore:/datastore
    environment:
      - PORT=5000
      - BASE_URL=https://changes.example.com
      # Optional: enable Playwright browser
      # - PLAYWRIGHT_DRIVER_URL=ws://sockpuppetbrowser:3000
    ports:
      - "5000:5000"

  # Optional: Playwright browser for JS-rendered pages
  sockpuppetbrowser:
    image: dgtlmoon/sockpuppetbrowser:latest
    hostname: sockpuppetbrowser
    cap_add:
      - SYS_ADMIN
    restart: unless-stopped
    environment:
      - SCREEN_WIDTH=1920
      - SCREEN_HEIGHT=1024
      - SCREEN_DEPTH=16
      - MAX_CONCURRENT_CHROME_PROCESSES=10
```

```bash
docker compose up -d
# Access at http://localhost:5000 (or via reverse proxy)
```

### NGINX reverse proxy

```nginx
server {
    listen 443 ssl;
    server_name changes.example.com;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        # Required for long-polling/SSE:
        proxy_buffering off;
        proxy_read_timeout 86400s;
    }
}
```

### pip install (manual)

```bash
pip install changedetection.io
changedetection.io -d /path/to/datastore -p 5000
```

## Upgrade Procedure

```bash
# Docker
docker compose pull
docker compose up -d

# pip
pip install --upgrade changedetection.io
```

> Check release notes at https://github.com/dgtlmoon/changedetection.io/releases for any datastore migration notes.

## Gotchas

- **Playwright container requires SYS_ADMIN**: The sockpuppetbrowser container needs `cap_add: [SYS_ADMIN]` for Chrome sandbox — requires a capable Docker host.
- **Backup `/datastore`**: All watch configurations, snapshots, and history live here — no built-in export/import, so regular backups are essential.
- **BASE_URL required for notifications**: Without it, notification messages include `localhost` links that don't work externally.
- **JS rendering adds latency**: Each Playwright check launches a real browser — set longer check intervals for JS-rendered watches to avoid resource exhaustion.
- **Target site etiquette**: Very short check intervals (< 5 min) may result in rate limiting or IP bans from target sites.
- **Proxy buffering off**: NGINX must have `proxy_buffering off` or the UI's live diff view won't work correctly.
- **Auth**: No built-in authentication — use NGINX basic auth or a VPN/Tailscale if exposing externally.

## Links

- Source: https://github.com/dgtlmoon/changedetection.io
- Docs/wiki: https://github.com/dgtlmoon/changedetection.io/wiki
- Apprise notification URLs: https://github.com/caronc/apprise/wiki
- Playwright setup: https://github.com/dgtlmoon/changedetection.io/wiki/Playwright-content-fetcher
