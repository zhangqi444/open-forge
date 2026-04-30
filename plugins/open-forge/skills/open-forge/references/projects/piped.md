---
name: Piped
description: Privacy-focused alternative frontend for YouTube. Watch/listen without ads, tracking, or Google servers — Piped fetches via NewPipeExtractor and proxies streams. SponsorBlock, LBRY, Return-YouTube-Dislike, subscriptions, playlists, PWA. AGPL-3.0.
---

# Piped

Piped is an open-source, privacy-focused alternative frontend for YouTube. It lets you watch, subscribe, and build playlists without ever touching Google's servers from your browser. Piped's backend fetches video metadata via [NewPipeExtractor](https://github.com/TeamNewPipe/NewPipeExtractor) (the same extraction engine behind NewPipe on Android), proxies stream URLs through your instance, and serves everything over a clean ad-free SPA.

Features:

- **No ads, no tracking, no Google cookies**
- **SponsorBlock** — skip sponsored segments
- **Return YouTube Dislike** — show dislike counts
- **LBRY integration** — stream from LBRY where available
- **Subscriptions** — without a Google account
- **Playlists** — local + synced via server account
- **Geo-unrestricted** — federated load-balancing can route around region locks
- **4K + audio-only** streaming
- **PWA** — installable on desktop + mobile
- **Public JSON API** — usable by third-party clients (LibreTube, Yattee, Pipeline)
- **Matrix federation** — instances can cooperate

Public instances list: <https://github.com/TeamPiped/documentation/blob/main/content/docs/public-instances/index.md>

- Main repo (meta): <https://github.com/TeamPiped/Piped>
- Frontend: <https://github.com/TeamPiped/Piped-Frontend>
- Backend: <https://github.com/TeamPiped/Piped-Backend>
- Proxy: <https://github.com/TeamPiped/piped-proxy>
- Docs: <https://docs.piped.video>
- Self-hosting guide: <https://docs.piped.video/docs/self-hosting/>
- Hosted flagship: <https://piped.video>

## Architecture in one minute

Piped is a **multi-service stack**:

- **Piped-Backend** (Java / Javalin) — API server; calls NewPipeExtractor
- **Piped-Frontend** (Vue.js) — SPA; calls backend API
- **piped-proxy** (Rust) — proxies media stream URLs through your server (so YouTube never sees viewer IPs)
- **PostgreSQL** — backend state (user accounts, subscriptions, playlists)
- **NewPipeExtractor** — Java library embedded in backend; handles YouTube page parsing
- **NGINX** — reverse proxy in front of everything; routes `/` to frontend, `/api` to backend, `/videoplayback` to proxy

## Compatible install methods

| Infra       | Runtime                                       | Notes                                                              |
| ----------- | --------------------------------------------- | ------------------------------------------------------------------ |
| Single VM   | Docker Compose (upstream-provided)              | **Recommended** — 5+ services wired together                          |
| Kubernetes  | Community manifests                                | DIY                                                                       |
| Single VM   | Manual (Java JAR + NGINX + Postgres + Rust proxy)     | Not beginner-friendly                                                        |
| Tunnel      | Cloudflare Tunnel / Tailscale for private access      | For personal-only instances                                                       |

## Inputs to collect

| Input                        | Example                                | Phase     | Notes                                                          |
| ---------------------------- | -------------------------------------- | --------- | -------------------------------------------------------------- |
| Frontend domain              | `piped.example.com`                     | DNS       | User-facing                                                       |
| API domain                   | `api.piped.example.com` (or `/api`)      | DNS       | Backend; separate subdomain recommended                              |
| Proxy domain                 | `proxy.piped.example.com`                | DNS       | Stream proxy; separate subdomain required (see gotchas)                 |
| Postgres creds               | strong                                   | DB        | Backend state                                                            |
| `HTTP_WORKERS`               | `2`-`4`                                   | Perf      | Backend worker threads                                                          |
| `PROXY_PART`                 | your proxy domain                         | Config    | Frontend rewrites stream URLs to this                                                |
| `BACKEND_URL` / `FRONTEND_URL` | your domains                             | Config    | Cross-domain config; wiring must match CORS                                                 |
| TLS (Let's Encrypt)          | required for all 3 subdomains              | Security  | Browsers + PWA need HTTPS                                                                       |
| `MATRIX_SERVER`              | optional federation                        | Federation | For cross-instance cooperation                                                                            |

## Install via Docker Compose

Upstream provides `docker-compose.yaml` in the [Piped repo](https://github.com/TeamPiped/Piped/blob/master/docker-compose.yaml). Typical stack:

```yaml
services:
  postgres:
    image: postgres:17-alpine
    container_name: piped-db
    restart: unless-stopped
    environment:
      POSTGRES_USER: piped
      POSTGRES_PASSWORD: <strong>
      POSTGRES_DB: piped
    volumes:
      - piped-pg:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U piped"]
      interval: 10s

  piped-backend:
    image: 1337kavin/piped:latest    # pin in prod
    container_name: piped-backend
    restart: unless-stopped
    depends_on:
      postgres: { condition: service_healthy }
    volumes:
      - ./config.properties:/app/config.properties:ro

  piped-frontend:
    image: 1337kavin/piped-frontend:latest
    container_name: piped-frontend
    restart: unless-stopped
    environment:
      BACKEND_HOSTNAME: api.piped.example.com
    command: /bin/sh -c 'sed -i "s/pipedapi.kavin.rocks/${BACKEND_HOSTNAME}/g" /usr/share/nginx/html/assets/* && nginx -g "daemon off;"'

  piped-proxy:
    image: 1337kavin/piped-proxy:latest
    container_name: piped-proxy
    restart: unless-stopped
    environment:
      UDS: "0"

  nginx:
    image: nginx:mainline-alpine
    container_name: piped-nginx
    restart: unless-stopped
    ports:
      - "8080:80"    # behind reverse proxy with TLS
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      - piped-backend
      - piped-frontend
      - piped-proxy

volumes:
  piped-pg:
```

`config.properties` (backend):

```properties
PORT: 8080
HTTP_WORKERS: 2
PROXY_PART: https://proxy.piped.example.com
API_URL: https://api.piped.example.com
FRONTEND_URL: https://piped.example.com
COMPROMISED_PASSWORD_CHECK: true
DISABLE_REGISTRATION: false
FEED_RETENTION: 30
hibernate.connection.url: jdbc:postgresql://postgres:5432/piped
hibernate.connection.driver_class: org.postgresql.Driver
hibernate.dialect: org.hibernate.dialect.PostgreSQLDialect
hibernate.connection.username: piped
hibernate.connection.password: <strong>
```

**Read the full upstream docker-compose** at <https://github.com/TeamPiped/Piped/blob/master/docker-compose.yaml> — it's more comprehensive and battle-tested than this sketch.

## Reverse proxy

Front it with Caddy/Traefik/nginx with Let's Encrypt on all three subdomains:

```
piped.example.com       → piped-frontend
api.piped.example.com   → piped-backend
proxy.piped.example.com → piped-proxy
```

## Data & config layout

- Postgres — user accounts, subscriptions, playlists (if users sign up)
- Backend config — `config.properties`
- Frontend baked at build time; runtime-configured via env substitution in nginx

## Backup

```sh
# Postgres = all user data
docker compose exec -T postgres pg_dump -U piped piped | gzip > piped-db-$(date +%F).sql.gz

# Config files
tar czf piped-config-$(date +%F).tgz config.properties nginx.conf docker-compose.yaml
```

## Upgrade

1. Releases (separate repos): Piped-Backend, Piped-Frontend, piped-proxy.
2. `docker compose pull && docker compose up -d`. All 3 images.
3. **No stability guarantees** — backend config keys change between versions. Watch upstream closely.
4. Matrix room + Lemmy community have migration tips.
5. **YouTube breaks Piped periodically** — when Google changes YouTube's HTML/API, NewPipeExtractor needs an update. Stale backend = videos stop loading. Update frequently.

## Gotchas

- **YouTube actively breaks alternative frontends** — expect periodic outages when YouTube ships anti-scraping changes. NewPipeExtractor is usually patched within days, but plan on some downtime per month.
- **Legal gray area** — YouTube's TOS prohibits automated access. Running a public Piped instance has seen DMCA-style takedowns historically. Private/personal-only instances are lower-risk.
- **Stream proxy uses YOUR bandwidth** — every video watched = your server downloads it from YouTube + reuploads to the viewer. A small instance (5-10 users) can pass 100s of GB/month. Public instances can easily exceed 10 TB/month.
- **Three subdomains recommended** — frontend, API, proxy. Same-domain deploys with path-routing are tricky due to CORS + nginx regex-path complexity.
- **Postgres is mandatory for user features** — if you just want anonymous watching, you still need Postgres (for playlists/subscriptions stored server-side).
- **Account data portability** — subscriptions can be exported/imported as JSON or imported from YouTube Takeout.
- **`DISABLE_REGISTRATION=true`** — recommended for private instances; Piped servers are spam-target-rich.
- **TURN/STUN** not needed — Piped is pure server-to-client streaming; no WebRTC.
- **PWA installability** requires HTTPS on the main domain.
- **Matrix federation** lets multiple Piped instances share load; niche feature.
- **IPFS build** — community-run IPFS mirror at piped-ipfs.kavin.rocks.
- **Mobile apps** using Piped's API: LibreTube (Android), Yattee (iOS/macOS), Pipeline (Linux), PlasmaTube (KDE), Harmony Music (Android/Windows/Debian).
- **Piped-Redirects / LibRedirect / Predirect** browser extensions — auto-redirect YouTube links to your Piped instance.
- **Not a YouTube backup** — Piped streams live; if YouTube removes a video, Piped stops too. Use yt-dlp for archival.
- **Videos have watermarks and interstitials** — Piped strips YouTube ads but cannot remove in-video sponsor segments — that's what SponsorBlock is for.
- **AGPL-3.0 license** — SaaS hosting = source disclosure obligation to users.
- **Alternatives worth knowing:**
  - **Invidious** — older alternative YT frontend; Ruby/Crystal; similar philosophy (separate recipe)
  - **FreeTube** — desktop app (Electron); no server needed; uses Invidious/local extraction
  - **NewPipe** (Android) — native Android app; what NewPipeExtractor was extracted from
  - **LibreTube** — Android client that uses Piped backend
  - **yt-dlp** — CLI downloader (not a frontend, for archival)
  - **SmartTube / SkyTube** (Android TV) — alternative YT for TV
  - **Choose Piped if:** you want a self-hosted YouTube frontend with subscriptions, proxy, and SponsorBlock integrated.
  - **Choose Invidious if:** you prefer Ruby/Crystal stack, similar features.
  - **Choose FreeTube if:** you want no server at all (desktop app only).

## Links

- Main repo: <https://github.com/TeamPiped/Piped>
- Frontend repo: <https://github.com/TeamPiped/Piped-Frontend>
- Backend repo: <https://github.com/TeamPiped/Piped-Backend>
- Proxy repo: <https://github.com/TeamPiped/piped-proxy>
- Self-hosting docs: <https://docs.piped.video/docs/self-hosting/>
- Public instances list: <https://github.com/TeamPiped/documentation/blob/main/content/docs/public-instances/index.md>
- API docs: <https://docs.piped.video/docs/api-documentation/>
- OpenAPI spec: <https://github.com/TeamPiped/OpenAPI>
- Hosted flagship: <https://piped.video>
- Matrix: <https://matrix.to/#/#piped:matrix.org>
- Lemmy: <https://feddit.rocks/c/piped>
- NewPipeExtractor: <https://github.com/TeamNewPipe/NewPipeExtractor>
- SponsorBlock: <https://github.com/ajayyy/SponsorBlock>
- Return YouTube Dislike: <https://returnyoutubedislike.com>
- LibreTube (Android): <https://github.com/Libre-tube/LibreTube>
- Yattee (iOS/macOS): <https://github.com/yattee/yattee>
