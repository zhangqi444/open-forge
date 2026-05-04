# changedetection.io

Website change detection and monitoring tool. Watches web pages for content changes and sends notifications via Discord, email, Slack, Telegram, webhooks, and many more. Supports AI-powered change summaries, visual element selectors, browser-step automation, and restock/price monitoring.

**Official site:** https://changedetection.io  
**Source:** https://github.com/dgtlmoon/changedetection.io  
**Upstream docs:** https://github.com/dgtlmoon/changedetection.io/wiki

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Docker Compose | Primary supported method |
| Any Linux host | Docker Compose + SockPuppetBrowser | Adds full Chrome/Playwright support |

---

## Inputs to Collect

### All phases
| Variable | Description | Example |
|----------|-------------|---------|
| `DATA_DIR` | Host path for persistent watch data | `./changedetection-data` |
| `PORT` | Listening port inside container | `5000` |
| `BASE_URL` | Public URL of your instance (used in notifications) | `https://changes.example.com` |
| `TZ` | Timezone for scheduling checks | `America/New_York` |

### Optional — Playwright/Chrome browser support
| Variable | Description |
|----------|-------------|
| `PLAYWRIGHT_DRIVER_URL` | WebSocket URL of SockPuppetBrowser container | `ws://browser-sockpuppet-chrome:3000` |

### Optional — proxy
| Variable | Description |
|----------|-------------|
| `HTTP_PROXY` / `HTTPS_PROXY` | Outbound proxy for fetching pages | `socks5h://10.0.0.1:1080` |
| `NO_PROXY` | Comma-separated bypass list | `localhost,192.168.0.0/24` |

---

## Software-Layer Concerns

### Docker Compose (basic — no browser)
```yaml
services:
  changedetection:
    image: ghcr.io/dgtlmoon/changedetection.io
    container_name: changedetection
    hostname: changedetection
    volumes:
      - changedetection-data:/datastore
    environment:
      - BASE_URL=https://changes.example.com
      - TZ=UTC
    ports:
      - 127.0.0.1:5000:5000
    restart: unless-stopped

volumes:
  changedetection-data:
```

### Docker Compose (with SockPuppetBrowser for JavaScript-heavy sites)
```yaml
services:
  changedetection:
    image: ghcr.io/dgtlmoon/changedetection.io
    container_name: changedetection
    hostname: changedetection
    volumes:
      - changedetection-data:/datastore
    environment:
      - BASE_URL=https://changes.example.com
      - PLAYWRIGHT_DRIVER_URL=ws://browser-sockpuppet-chrome:3000
      - TZ=UTC
    ports:
      - 127.0.0.1:5000:5000
    depends_on:
      - browser-sockpuppet-chrome
    restart: unless-stopped

  browser-sockpuppet-chrome:
    hostname: browser-sockpuppet-chrome
    image: dgtlmoon/sockpuppetbrowser:latest
    cap_add:
      - SYS_ADMIN
    restart: unless-stopped
    environment:
      - SCREEN_WIDTH=1920
      - SCREEN_HEIGHT=1024
      - SCREEN_DEPTH=16
      - MAX_CONCURRENT_CHROME_PROCESSES=10

volumes:
  changedetection-data:
```

### Config paths and env vars
| Variable | Purpose | Default |
|----------|---------|---------|
| `PORT` | Internal listen port | `5000` |
| `BASE_URL` | Included in notification messages | unset |
| `TZ` | Timezone for scheduled checks | system TZ |
| `FETCH_WORKERS` | Parallel page fetchers | `10` |
| `MINIMUM_SECONDS_RECHECK_TIME` | Minimum interval between checks | `3` |
| `HIDE_REFERER` | Strip Referer header from requests | `false` |
| `DISABLE_VERSION_CHECK` | Opt out of telemetry/version checks | `false` |
| `PLAYWRIGHT_DRIVER_URL` | Enable JS-capable fetching via SockPuppetBrowser | unset |
| `EXTRA_PACKAGES` | Additional Python packages (processor plugins) | unset |
| `ALLOW_FILE_URI` | Allow file:/// URIs (security risk) | `false` |

---

## Upgrade Procedure

1. Pull the latest image: `docker compose pull`
2. Recreate the container: `docker compose up -d`
3. The datastore volume is preserved automatically
4. Check the releases page for breaking changes: https://github.com/dgtlmoon/changedetection.io/releases

---

## Gotchas

- **JavaScript sites require SockPuppetBrowser** — plain HTTP fetcher cannot render JS; add the `browser-sockpuppet-chrome` sidecar for sites that require a real browser
- **SYS_ADMIN cap_add** — required by Chrome inside SockPuppetBrowser for sandbox support
- **Selenium is deprecated** — the older `browser-selenium-chrome` sidecar does not capture full-page screenshots; use SockPuppetBrowser instead
- **macOS port conflict** — AirPlay uses port 5000; bind to host port 5050 on macOS: `127.0.0.1:5050:5000`
- **Notifications require BASE_URL** — without it, notification links will be relative/broken
- **LLM features** — AI change summaries require an API key (OpenAI/Gemini/Anthropic/Ollama) configured per-watch; no global key required at startup

---

## Links
- Upstream README: https://github.com/dgtlmoon/changedetection.io
- Wiki / proxy config: https://github.com/dgtlmoon/changedetection.io/wiki
- Playwright content fetcher: https://github.com/dgtlmoon/changedetection.io/wiki/Playwright-content-fetcher
- Plugin directory: https://changedetection.io/plugins
