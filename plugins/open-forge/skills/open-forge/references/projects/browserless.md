---
name: Browserless
description: "Self-hosted headless browser service — run Chromium/Chrome/Firefox via Puppeteer, Playwright, or CDP over a Docker container. Use for web scraping, PDF generation, screenshots, and automated testing without managing browser installs. Open-source core (SSPL)."
---

# Browserless

**What it is:** A Docker-based headless browser service that exposes Chromium (and optionally Firefox) over WebSocket/HTTP. Drop-in remote endpoint for Puppeteer and Playwright — instead of launching a local browser, your scripts connect to `ws://localhost:3000`. Also provides REST endpoints for screenshots, PDFs, content scraping, and a built-in debugger/playground UI.

**Official site:** https://browserless.io
**Docs:** https://docs.browserless.io
**GitHub:** https://github.com/browserless/browserless
**License:** SSPL v1 (source-available; free for self-hosting, commercial SaaS use requires a license)

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Docker | `ghcr.io/browserless/chromium` | Recommended; Chromium-based |
| Docker | `ghcr.io/browserless/firefox` | Firefox variant |
| Docker | `ghcr.io/browserless/chrome` | Chrome (non-Chromium) variant |
| Docker Compose | Any Linux host | For persistent config + multiple instances |
| Kubernetes | Any cluster | Scale horizontally for load |

---

## Inputs to Collect

### Optional but recommended
- `TOKEN` — API token; if set, all requests require `?token=<value>` or `Authorization: Bearer <token>`. Leave unset for open access (LAN-only deployments).
- `CONCURRENT` — max simultaneous browser sessions (default: 10)
- `TIMEOUT` — session timeout in ms (default: 30000)
- `MAX_QUEUE_LENGTH` — queue depth before returning 429 (default: 10)

### For production
- `CORS_ALLOW_METHODS` / `CORS_ALLOW_ORIGIN` — CORS configuration
- `EXIT_ON_HEALTH_FAILURE` — `true` to crash container if health check fails (useful with orchestrators)

---

## Software-Layer Concerns

### Image variants
| Image | Browser | Use case |
|-------|---------|---------|
| `ghcr.io/browserless/chromium` | Chromium (open source) | Default; most compatible |
| `ghcr.io/browserless/chrome` | Google Chrome | Needs Chrome-specific features |
| `ghcr.io/browserless/firefox` | Firefox | Playwright Firefox only |

### Exposed port
- `3000` — WebSocket endpoint + HTTP REST API + built-in docs/debugger

### Key endpoints
| Path | Description |
|------|-------------|
| `GET /docs` | Interactive API docs + playground |
| `GET /screenshot` | Take a screenshot (query params) |
| `GET /pdf` | Generate PDF of a URL |
| `GET /content` | Return rendered HTML of a URL |
| `GET /scrape` | Extract structured data |
| `GET /function` | Run a custom Puppeteer function |
| `WS /` | WebSocket endpoint for Puppeteer/Playwright `connect()` |

---

## Deployment Steps

### Quickstart (single container)
```bash
docker run -d -p 3000:3000 \
  -e TOKEN=mysecrettoken \
  -e CONCURRENT=5 \
  --name browserless \
  ghcr.io/browserless/chromium

# Docs + playground: http://localhost:3000/docs
```

### Docker Compose
```yaml
version: "3"
services:
  browserless:
    image: ghcr.io/browserless/chromium
    ports:
      - "3000:3000"
    environment:
      TOKEN: mysecrettoken
      CONCURRENT: "10"
      TIMEOUT: "30000"
    restart: unless-stopped
```

### Connect with Puppeteer
```js
import puppeteer from 'puppeteer-core';

const browser = await puppeteer.connect({
  browserWSEndpoint: 'ws://localhost:3000?token=mysecrettoken',
});
const page = await browser.newPage();
await page.goto('https://example.com');
const screenshot = await page.screenshot();
await browser.close();
```

### Connect with Playwright
```js
import { chromium } from 'playwright-core';

const browser = await chromium.connectOverCDP(
  'ws://localhost:3000?token=mysecrettoken'
);
```

---

## Upgrade Procedure

```bash
docker pull ghcr.io/browserless/chromium
docker stop browserless && docker rm browserless
# Re-run the docker run command with the same options
```

Or with Compose:
```bash
docker compose pull && docker compose up -d
```

---

## Gotchas

- **SSPL license** — Browserless is source-available under SSPL. You can self-host freely, but if you offer it as a cloud service to others, you must open-source your entire stack or purchase a commercial license.
- **No auth by default** — Without `TOKEN`, the service is completely open. Always set a token for internet-facing deployments.
- **Browser versioning** — The Chromium version is pinned in the image. If your Puppeteer/Playwright version requires a newer browser API, update to the latest image tag.
- **Shared browser sessions** — By default each WebSocket connection gets its own browser context but shares the same Chromium process. For strict isolation, set `ISOLATION_MODE=full` (higher memory usage).
- **Memory** — Each concurrent browser session uses ~100–200 MB RAM. Set `CONCURRENT` to match available memory.
- **ARM support** — Chromium builds for `linux/arm64` exist but may lag behind x86 releases. Check image tags before deploying on ARM.
- **Sandbox** — The container runs Chromium with `--no-sandbox` by default (required for Docker). Don't use this to browse untrusted user-supplied URLs without additional isolation.

---

## Links
- GitHub: https://github.com/browserless/browserless
- Docs: https://docs.browserless.io
- Docker Hub: https://hub.docker.com/r/browserless/chrome
- REST API reference: https://docs.browserless.io/rest-apis/
