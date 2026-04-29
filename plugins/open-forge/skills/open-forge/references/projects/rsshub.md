---
name: rsshub-project
description: RSSHub recipe for open-forge. MIT-licensed universal RSS feed generator — turns 1000+ websites (Twitter/X, Instagram, Reddit, Bilibili, YouTube, news sites, e-commerce, etc.) into RSS. Covers the upstream docker-compose (Redis + optional Browserless/Puppeteer for JS-rendered sites), native Node.js install, and the minimum config needed for private deploys (access control + proxy). Default port 1200. Stateless app — Redis is the only persistence (cache only, safe to lose).
---

# RSSHub

MIT-licensed RSS/Atom feed generator covering 1000+ websites. Upstream: <https://github.com/DIYgod/RSSHub>. Docs: <https://docs.rsshub.app/>.

Every route under `/routes/<provider>/<path>` returns an RSS/Atom feed. Routes are community-maintained; there's a docs page per provider.

## Architecture (minimum)

- **rsshub** — Node.js app (Koa), stateless, port `1200`.
- **redis** — cache layer (TTL-based; losing Redis means a cold start, not data loss).
- **browserless/chrome** — OPTIONAL headless Chrome for JS-rendered sites (Twitter/X, Instagram, etc. often need this). Uses ~500MB+ RAM.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | `docker-compose.yml` on `master` | ✅ Recommended | Upstream-maintained compose shipping `diygod/rsshub` + Redis + (optional) Browserless. |
| Docker single container | `docker run diygod/rsshub` | ✅ | Quick test; no Redis = slower, higher upstream rate-limit risk. |
| Native Node.js (pnpm) | <https://docs.rsshub.app/install/> | ✅ | Dev / custom. Needs Node 22+ and pnpm. |
| Build from source | Standard `pnpm build` | ✅ | Dev / patches. |
| `diygod/rsshub:chromium-bundled` | Same image family | ✅ | Single container variant with Chromium bundled in (simpler than spinning up Browserless separately; larger image). |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion`: `docker-compose` / `docker-chromium-bundled` / `native` | Drives section. |
| features | "Need JS-rendered sites (Twitter/X, Instagram)?" | Boolean | If yes → enable Browserless / chromium-bundled image. |
| secrets | "Access key for private deploys?" | Free-text (sensitive) | Set `ACCESS_KEY` env. Without it, RSSHub is an open proxy anyone can hit. |
| auth | "Whitelist user IPs?" | Free-text comma-list | `WHITELIST` / `BLACKLIST` env vars. |
| proxy | "Outbound HTTP(S) proxy?" | Free-text URL | Many routes are IP-rate-limited or geo-blocked; set `PROXY_URI` / `PROXY_AUTH` if you need an outbound proxy. |
| cache | "Cache TTL (seconds)?" | Integer, default `300` | `CACHE_EXPIRE`. Longer = fewer upstream hits, staler feeds. |
| dns | "Public domain + reverse proxy for TLS?" | Free-text | RSSHub doesn't terminate TLS; front it with Caddy/Nginx/Traefik. |

## Install — Docker Compose (upstream-recommended)

From upstream's `docker-compose.yml` on `master`:

```yaml
services:
  rsshub:
    image: diygod/rsshub              # or diygod/rsshub:chromium-bundled for JS-render
    restart: always
    ports:
      - '1200:1200'
    environment:
      NODE_ENV: production
      CACHE_TYPE: redis
      REDIS_URL: 'redis://redis:6379/'
      PUPPETEER_WS_ENDPOINT: 'ws://browserless:3000'   # remove if not using browserless
      ACCESS_KEY: '${ACCESS_KEY}'                      # add for private deploys
    healthcheck:
      test: ['CMD', 'curl', '-f', 'http://localhost:1200/healthz']
      interval: 30s
      timeout: 10s
      retries: 3
    depends_on:
      - redis
      - browserless                                    # remove if not using browserless

  browserless:
    image: browserless/chrome
    restart: always
    ulimits:
      core: { hard: 0, soft: 0 }
    healthcheck:
      test: ['CMD', 'curl', '-f', 'http://localhost:3000/pressure']
      interval: 30s
      timeout: 10s
      retries: 3

  redis:
    image: redis:alpine
    restart: always
    volumes:
      - redis-data:/data
    healthcheck:
      test: ['CMD', 'redis-cli', 'ping']
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 5s

volumes:
  redis-data:
```

```bash
echo "ACCESS_KEY=$(openssl rand -hex 16)" > .env
docker compose up -d
curl http://localhost:1200/healthz
curl "http://localhost:1200/github/issue/DIYgod/RSSHub?key=$(grep ACCESS_KEY .env | cut -d= -f2)"
```

### Single container (chromium-bundled)

```bash
docker run -d \
  --name rsshub \
  -p 1200:1200 \
  -e ACCESS_KEY="$(openssl rand -hex 16)" \
  --restart always \
  diygod/rsshub:chromium-bundled
```

No Redis → no cache → higher upstream rate-limit risk. Fine for personal use with low fetch frequency.

## Install — Native Node.js

```bash
# Node 22+
git clone https://github.com/DIYgod/RSSHub.git
cd RSSHub
corepack enable
pnpm install
pnpm build
pnpm start
```

Put behind pm2 / systemd; add Redis separately.

## Authentication (critical for public deploys)

Without `ACCESS_KEY`, anyone on the internet can hit your RSSHub as a scraping proxy. Three auth options (combine as needed):

| Env var | Effect |
|---|---|
| `ACCESS_KEY=<hex>` | Append `?key=<hex>` to every feed URL, or compute `code=md5(/path + key)`. |
| `WHITELIST=1.2.3.0/24,5.6.7.8` | Only these CIDRs / IPs can access. |
| `BLACKLIST=9.10.11.0/24` | These are blocked; everyone else allowed. |
| `AUTH_HTTP_BASIC_ROUTES=twitter,instagram` + `HTTPBASIC_USERNAME_*` / `HTTPBASIC_PASSWORD_*` | HTTP basic-auth per-route. |

Full auth docs: <https://docs.rsshub.app/deploy/config#access-control-configurations>

## Reverse proxy (Caddy)

```caddy
rss.example.com {
    reverse_proxy 127.0.0.1:1200
}
```

## Common operational env vars

| Var | Purpose |
|---|---|
| `CACHE_TYPE` | `redis` (default in compose) or `memory` (single-process). |
| `CACHE_EXPIRE` | Per-route cache TTL in seconds. Default 300. |
| `REDIS_URL` | `redis://redis:6379/` |
| `PROXY_URI` | Outbound HTTP/SOCKS proxy for routes that need geo-unblocking. |
| `PROXY_AUTH` | Base64 auth for proxy. |
| `UA` | Override default User-Agent (some routes' upstreams block generic UAs). |
| `LOGGER_LEVEL` | `info` / `debug` / `silent`. |
| `TITLE_LENGTH_LIMIT` | Truncate titles; useful for RSS readers with narrow columns. |

## Upgrade procedure

```bash
# Docker Compose
docker compose pull
docker compose up -d

# Native
cd /path/to/RSSHub
git pull
pnpm install
pnpm build
# restart pm2/systemd
```

Routes change frequently (Twitter/X breaks every few months). If a feed starts 404-ing, check the route's docs page and the #rsshub-broken tag in the repo issues.

## Data & backups

**RSSHub is stateless.** The only persistence is Redis cache, which is safe to lose (will rebuild on next request). No user accounts, no feed subscriptions — your RSS reader holds the subscription list. Backups are not required.

## Gotchas

- **`ACCESS_KEY` is effectively mandatory on public deploys.** Without it, you're running a public scraping proxy; you WILL be used for abuse. Set it + optionally firewall to WireGuard/Tailscale.
- **Route churn.** Upstream sites change APIs / add anti-bot; routes break. Upstream moves fast to patch, but expect 5-10% of routes to be broken at any time. Keep images fresh (`docker compose pull`).
- **Browserless is heavy.** ~500 MB RAM for a running Chromium. On small VPS (<2GB), skip Browserless and accept that Twitter/X/Instagram feeds won't work.
- **Some routes need cookies / tokens.** Private sources (e.g. your Bilibili watchlist) need `SCOOPER_COOKIE_*` / provider-specific env vars. Each route's docs page lists the env vars.
- **Cache TTL trade-off.** Too short → hammers upstream → rate-limit / IP-ban. Too long → RSS reader shows stale items. 300s is fine for most; bump to 3600s for polite scraping.
- **`diygod/rsshub:chromium-bundled` is big** (2+ GB). Don't use if you don't need JS-rendered routes.
- **Upstream Node version requirement moves.** Check `package.json` `engines.node` before native install; currently Node 22+.
- **Redis cache is insecure by default.** On Docker's internal network it's fine; don't expose the Redis port to the host unless you set a password.
- **PUPPETEER_WS_ENDPOINT** must point at the Browserless service. If Browserless exits on low memory, JS-rendered routes silently fall back to non-JS fetch and return empty feeds.

## Links

- Upstream repo: <https://github.com/DIYgod/RSSHub>
- Docs site: <https://docs.rsshub.app/>
- Install guides: <https://docs.rsshub.app/install/>
- Config (env vars): <https://docs.rsshub.app/deploy/config>
- Route catalogue: <https://docs.rsshub.app/routes/popular>
- Radar (bookmark helper): <https://github.com/DIYgod/RSSHub-Radar>
- Docker image: <https://hub.docker.com/r/diygod/rsshub>
