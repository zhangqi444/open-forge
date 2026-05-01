---
name: Marreta
description: "Self-hosted paywall and tracking bypass tool. Docker. PHP 8.4. manualdousuario/marreta. Clean URLs, remove tracking params, strip paywalled content, Selenium rendering, S3 cache, browser extensions, Telegram bot."
---

# Marreta

**Self-hosted tool that breaks through paywalls and cleans web pages for reading.** Paste an article URL; Marreta fetches the page, removes tracking parameters, strips paywall elements, injects custom styles, and returns a clean readable version. Uses Selenium (Chromium/Firefox) for JavaScript-rendered sites. Browser extensions for one-click access. Available in pt-BR, en, es, de, ru.

Built + maintained by **manualdousuario** (Manual do Usuário). See repo license.

- Upstream repo: <https://github.com/manualdousuario/marreta>
- Public instance: <https://marreta.pcdomanual.com>
- Docker Hub: `ghcr.io/manualdousuario/marreta`
- Browser extensions: Firefox + Chrome (by Clarissa Mendes)
- Telegram bot: [@leissoai_bot](https://t.me/leissoai_bot)
- Bluesky bot: available

## Architecture in one minute

- **PHP 8.4** backend with PHP-FPM + OPcache
- **Selenium Hub** + **Chromium + Firefox** nodes for JavaScript rendering
- Port **80** (web UI + API)
- File-based cache (`./app/cache`) + optional **S3 cache backend**
- Optional proxy list for request routing
- Resource: **medium** — PHP + 3 Selenium containers (can run without Selenium for HTML-only sites)

## Compatible install methods

| Infra      | Runtime                           | Notes                                              |
| ---------- | --------------------------------- | -------------------------------------------------- |
| **Docker** | `ghcr.io/manualdousuario/marreta` | **Primary** — GHCR; includes Selenium in compose   |
| **Hosted** | marreta.pcdomanual.com            | Public instance; no install needed                 |

## Install via Docker Compose

```bash
curl -o ./docker-compose.yml https://raw.githubusercontent.com/manualdousuario/marreta/main/docker-compose.yml
# Edit the file to configure your settings:
nano docker-compose.yml
docker compose up -d
```

Key environment variables in the compose file:

| Variable | Example | Description |
|----------|---------|-------------|
| `SITE_NAME` | `My Marreta` | Your instance name |
| `SITE_DESCRIPTION` | `Paywall bypass` | Instance description |
| `SITE_URL` | `https://marreta.example.com` | Full public URL (incl. port if non-standard) |
| `SELENIUM_HOST` | `selenium-hub:4444` | Selenium Hub address |
| `LANGUAGE` | `en` | Interface language: `pt-br`, `en`, `es`, `de-de`, `ru-ru` |
| `LOG_LEVEL` | `WARNING` | Log verbosity |
| `CLEANUP_DAYS` | `7` | Cache retention days |
| `PROXY_LIST` | URL to proxy list | Optional proxy rotation |

The default compose file includes Marreta + Selenium Hub + Chromium + Firefox nodes.

## Full Docker Compose stack

```yaml
services:
  marreta:
    image: ghcr.io/manualdousuario/marreta:latest
    ports:
      - "80:80"
    volumes:
      - ./app/cache:/app/cache
      - ./app/logs:/app/logs
    environment:
      - SITE_NAME=Marreta
      - SITE_URL=https://marreta.example.com
      - LANGUAGE=en
      - SELENIUM_HOST=selenium-hub:4444

  selenium-hub:
    image: selenium/hub:4.27.0-20241204
    environment:
      - GRID_MAX_SESSION=10
      - GRID_BROWSER_TIMEOUT=10

  selenium-chromium:
    image: selenium/node-chromium:4.27.0-20241204
    shm_size: 2gb
    environment:
      - SE_EVENT_BUS_HOST=selenium-hub
      - SE_EVENT_BUS_PUBLISH_PORT=4442
      - SE_EVENT_BUS_SUBSCRIBE_PORT=4443
      - SE_NODE_MAX_SESSIONS=10

  selenium-firefox:
    image: selenium/node-firefox:4.27.0-20241204
    shm_size: 2gb
    environment:
      - SE_EVENT_BUS_HOST=selenium-hub
      - SE_EVENT_BUS_PUBLISH_PORT=4442
      - SE_EVENT_BUS_SUBSCRIBE_PORT=4443
```

## First boot

1. Edit `docker-compose.yml` — set `SITE_NAME`, `SITE_URL`, `LANGUAGE`.
2. `docker compose up -d` — wait for Selenium to initialize (may take 30–60s).
3. Visit your instance URL.
4. Paste a paywalled URL → receive clean readable version.
5. Install browser extension for one-click access.
6. (Optional) Configure DMCA blocking and custom rules.

## Browser extensions

Install the extension from Clarissa Mendes to add a toolbar button — one click to bypass the current page via your Marreta instance. Configure the extension with your instance URL.

- Firefox: <https://addons.mozilla.org/pt-BR/firefox/addon/marreta/>
- Chrome: Chrome Web Store link (see README)

## Features overview

| Feature | Details |
|---------|---------|
| URL cleaning | Remove tracking parameters (utm_*, fbclid, etc.) |
| HTTPS forcing | Upgrade HTTP to HTTPS |
| User agent rotation | Bypass simple bot detection |
| HTML cleaning | Remove ads, paywall overlays, cookie banners, tracking pixels |
| Relative URL fixing | Make relative URLs absolute in cleaned output |
| Custom styles/scripts | Inject your own CSS/JS per domain |
| Element removal | Configure specific CSS selectors to remove |
| File cache | Local filesystem cache with configurable TTL |
| S3 cache | Optional S3-compatible storage for distributed caching |
| Domain blocking | Block specific domains from being processed |
| DMCA protection | Block domains with custom DMCA messages via JSON config |
| Custom headers/cookies | Configure per-domain request headers and cookies |
| Selenium rendering | JavaScript-rendered paywalls via headless Chromium/Firefox |
| Proxy support | Rotate through proxy list for request routing |
| Telegram bot | Bot integration for sharing clean links |
| Bluesky bot | Bot that responds to Bluesky mentions |

## DMCA blocking

Create `app/cache/dmca_domains.json` to block specific domains:

```json
[
  {
    "host": "blocked-site.com",
    "message": "This content has been blocked upon request"
  }
]
```

## Gotchas

- **Selenium adds significant resource overhead.** The full stack runs Selenium Hub + Chromium + Firefox nodes, each needing 1–2 GB RAM. Minimum host RAM: 4 GB for comfortable use. For text-only paywall sites that don't require JS rendering, you can run Marreta without Selenium (set `SELENIUM_HOST` to empty or a non-existent host).
- **`SITE_URL` must include port if non-standard.** If you expose on port 8080 instead of 80, set `SITE_URL=https://yoursite:8080`. The URL is used to construct internal links and cache keys.
- **Legal and ethical considerations.** Bypassing paywalls may violate the terms of service of the sites you access, and may be restricted in some jurisdictions. Use responsibly and in accordance with applicable laws.
- **Cache grows over time.** The `./app/cache` directory grows as pages are cached. Configure `CLEANUP_DAYS=7` or lower to auto-purge old entries. Monitor disk usage.
- **Chromium/Firefox `shm_size: 2gb`** — Selenium browser nodes need shared memory. The `shm_size: 2gb` in the compose file is required; without it, browsers crash on heavy pages.
- **S3 cache for multi-instance.** If running multiple Marreta instances behind a load balancer, use S3 cache so all instances share the same cache. File cache is local to each container.

## Backup

```sh
sudo tar czf marreta-$(date +%F).tgz app/cache/ app/logs/
```

Cache is regenerable — only logs strictly need backup if you care about them.

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Project health

Active PHP 8.4 development, GHCR, browser extensions (Firefox+Chrome), Telegram bot, Bluesky bot, S3 cache, Selenium integration. Maintained by manualdousuario. Brazilian Portuguese community.

## Paywall-bypass-family comparison

- **Marreta** — PHP+Selenium, full stack, browser extensions, Telegram/Bluesky bots, S3 cache
- **Wallabag** — PHP, read-later service that also retrieves article content; different focus
- **Readability (Mozilla)** — library; Marreta uses similar extraction + adds paywall removal
- **12ft.io** — SaaS; not self-hosted
- **Bypass Paywalls Clean** — browser extension only; no self-hosted server

**Choose Marreta if:** you want a self-hosted paywall bypass + article cleaner with Selenium-based rendering, browser extensions, and a Telegram/Bluesky bot.

## Links

- Repo: <https://github.com/manualdousuario/marreta>
- Public instance: <https://marreta.pcdomanual.com>
- Firefox extension: <https://addons.mozilla.org/pt-BR/firefox/addon/marreta/>
- Telegram bot: <https://t.me/leissoai_bot>
- S3 cache wiki: <https://github.com/manualdousuario/marreta/wiki>
