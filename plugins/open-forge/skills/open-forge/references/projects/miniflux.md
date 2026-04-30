---
name: Miniflux
description: "Minimalist, opinionated, single-binary RSS/Atom feed reader written in Go. Keyboard-first UI, OPML import, Postgres-backed, REST API, Fever/Google Reader API compatibility, OIDC/LDAP, built-in content scraping. Apache-2.0."
---

# Miniflux

Miniflux is a minimalist, opinionated, **single-binary Go** RSS/Atom reader. It's the antidote to bloated feed readers: no infinite scroll, no algorithms, no tracking, no ads, no mobile app lock-in — just clean, keyboard-driven feed reading that renders fast on every device.

What makes it stand out:

- **Single Go binary** — statically linked; ~20 MB; no runtime deps
- **Postgres-only** backend — no SQLite support (design decision for robustness)
- **Fever + Google Reader API** — works with Reeder, NetNewsWire, FeedMe, etc.
- **Keyboard-first** — `j/k` next/prev, `m` mark read, `s` star, `v` view original
- **Content scraping** — strips ads/trackers, readability-style cleanup
- **OIDC + LDAP + Google auth** — enterprise-ready SSO
- **Webhook / Pushover / Telegram / Matrix / Discord / Slack / Gotify / Ntfy** — per-feed notifications
- **Full-text search** (Postgres FTS)
- **OPML import/export**
- **Feed integrations** — share to Wallabag, Pinboard, Pocket, Instapaper, Shaarli, Linkding, Shiori, Espial, Telegram, Notion, …
- **Youtube / Nebula / Bilibili / Odysee / Invidious / PeerTube / Mastodon** feed support
- **PWA** installable

- Upstream repo: <https://github.com/miniflux/v2>
- Website: <https://miniflux.app>
- Docs: <https://miniflux.app/docs/>
- Hosted Miniflux: <https://miniflux.app/hosted.html> ($15/year, supports the project)

## Architecture in one minute

- **Go binary** — `miniflux` — HTTP server + feed refresher + background jobs
- **Postgres 12+** — the only supported DB
- **No Redis, no queue, no S3** — self-contained
- **Workers** — configurable pollers pull feeds on a schedule
- **Templates + assets** embedded in binary
- Single replica scales to thousands of feeds; multi-replica unnecessary for most

## Compatible install methods

| Infra       | Runtime                                               | Notes                                                           |
| ----------- | ----------------------------------------------------- | --------------------------------------------------------------- |
| Single VM   | Docker (`ghcr.io/miniflux/miniflux`)                     | **Most common**                                                     |
| Single VM   | Native binary from release                                   | Deb / RPM / tarball / `go install`                                       |
| Single VM   | Snap or Homebrew                                              | Available                                                                  |
| Kubernetes  | Plain Deployment + Postgres                                       | Tiny; no special handling                                                        |
| Raspberry Pi | arm64 image                                                      | Runs on Pi 3/4                                                                  |
| BSD         | FreeBSD port / NetBSD pkgsrc                                         | Supported                                                                            |

## Inputs to collect

| Input              | Example                         | Phase     | Notes                                                        |
| ------------------ | ------------------------------- | --------- | ------------------------------------------------------------ |
| Database URL       | `postgres://user:pass@db/miniflux?sslmode=disable` | DB | Postgres 12+ required                              |
| Port               | `8080`                            | Network   | `LISTEN_ADDR=:8080`                                                 |
| Admin user         | created via `CREATE_ADMIN=1`       | Bootstrap | Or `miniflux -create-admin` CLI                                          |
| Base URL           | `https://reader.example.com`        | URL       | `BASE_URL`; used for links in notifications                                    |
| OIDC (optional)    | issuer URL + client ID/secret         | Auth      | SSO                                                                                        |
| Scheduler tunables | `POLLING_FREQUENCY`, `WORKER_POOL_SIZE`   | Perf      | Defaults (60 min / 16 workers) are fine for most                                                          |

## Install via Docker Compose

```yaml
services:
  miniflux:
    image: ghcr.io/miniflux/miniflux:2.x   # pin; check releases
    container_name: miniflux
    restart: unless-stopped
    depends_on:
      db: { condition: service_healthy }
    ports:
      - "8080:8080"
    environment:
      DATABASE_URL: postgres://miniflux:<strong>@db/miniflux?sslmode=disable
      RUN_MIGRATIONS: "1"
      CREATE_ADMIN: "1"
      ADMIN_USERNAME: admin
      ADMIN_PASSWORD: <strong>
      BASE_URL: https://reader.example.com
      POLLING_FREQUENCY: "60"        # minutes
      WORKER_POOL_SIZE: "16"
      METRICS_COLLECTOR: "1"          # Prometheus /metrics

  db:
    image: postgres:16-alpine
    container_name: miniflux-db
    restart: unless-stopped
    environment:
      POSTGRES_USER: miniflux
      POSTGRES_PASSWORD: <strong>
      POSTGRES_DB: miniflux
    volumes:
      - miniflux-db:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U miniflux"]
      interval: 10s

volumes:
  miniflux-db:
```

Browse `http://<host>:8080` → log in with `admin` / `<strong>`.

## Install via Deb/RPM

```sh
# Debian/Ubuntu
wget https://github.com/miniflux/v2/releases/download/vX.Y.Z/miniflux_X.Y.Z_amd64.deb
sudo dpkg -i miniflux_X.Y.Z_amd64.deb
sudo -u postgres createuser -P miniflux
sudo -u postgres createdb -O miniflux miniflux
sudo -u postgres psql miniflux -c "CREATE EXTENSION hstore"
sudo vi /etc/miniflux.conf    # set DATABASE_URL, LISTEN_ADDR, BASE_URL
sudo miniflux -migrate
sudo miniflux -create-admin
sudo systemctl enable --now miniflux
```

## First boot

1. Log in
2. Settings → Integrations → enable any (Wallabag, Pocket, Shaarli, etc.)
3. Subscribe → paste feed or site URL (feed discovery works for most sites)
4. OPML import: Settings → Import
5. Keyboard shortcuts: `?` shows them all
6. Mobile clients: enable Fever API (Settings → Integrations → Fever) → connect Reeder/NetNewsWire/FeedMe with the Fever endpoint + API key

## Data & config layout

All state is in Postgres — no files outside the DB (except logs).

Config: `/etc/miniflux.conf` (deb/rpm) or environment variables (Docker).

## Backup

```sh
# Everything
pg_dump -h db -U miniflux miniflux | gzip > miniflux-$(date +%F).sql.gz

# Or OPML export via UI for portability
```

## Upgrade

1. Releases: <https://github.com/miniflux/v2/releases>. Very active.
2. Docker: `docker compose pull && docker compose up -d`. Migrations auto-run if `RUN_MIGRATIONS=1`.
3. Native: `apt install miniflux_new.deb` → `miniflux -migrate` → `systemctl restart miniflux`.
4. Breaking changes rare; read CHANGELOG.
5. Backward-compatible with Miniflux v1 schemas? No — v2 is a rewrite; v1 migration was a one-time flow years ago.

## Gotchas

- **Postgres-only — no SQLite.** This is deliberate (robust concurrent FTS, transactional migrations). If you want SQLite, pick FreshRSS / Tiny Tiny RSS / Kavita-for-feeds / Selfoss instead.
- **OPFS-style `hstore` extension required** — the Postgres role needs rights to `CREATE EXTENSION hstore`. Docker image handles this; native install requires running the `CREATE EXTENSION` manually.
- **`BASE_URL` matters** — wrong value = broken notification links + OIDC redirects. Set it to the full public URL including scheme.
- **Feed refresh frequency** — default 60 min. Setting aggressively low (e.g., 1-5 min) for many feeds will get you rate-limited or banned from sites. Respect `Cache-Control` + `ETag` headers, which Miniflux does.
- **Content scraping** is per-feed — enable "Fetch original content" on feeds that only publish summaries. Uses readability-style extraction.
- **Feed-level rules** (rewrite, block, keep, replace URL) are powerful. Learn them: <https://miniflux.app/docs/rules.html>.
- **Fever API vs Google Reader API**: Fever is read-centric; Google Reader API is fuller (share/starred/folders). Many mobile apps support both. Reeder on macOS/iOS is the gold standard; pairs beautifully with Miniflux.
- **OIDC config** requires exact issuer URL + redirect URL. See `OAUTH2_*` env vars in docs; misconfiguration gives cryptic "state mismatch" errors.
- **No built-in email digest** (yet) — use integrations (Telegram, Matrix, Pushover) or external scripts via API.
- **Full-text search** uses Postgres FTS — good for hundreds of thousands of articles; not a replacement for Elasticsearch-grade search.
- **Metrics** — enable `METRICS_COLLECTOR=1` for Prometheus `/metrics`. Limit access via reverse proxy.
- **Youtube feed support**: paste a YouTube channel URL, Miniflux figures out the RSS. Works well; bypasses the "Google-killed-Reader" narrative nicely.
- **No offline mode** — fetches require server to be up. PWA caches UI but not article content.
- **No per-user Fever API instance sharing** — each user has their own Fever endpoint + key.
- **Pre-release feature**: Miniflux 2.x continues active development; check release notes for new integrations.
- **Hosted Miniflux** ($15/year) is the upstream-blessed managed option; supports development.
- **License**: Apache-2.0 (permissive).
- **Alternatives worth knowing:**
  - **FreshRSS** — PHP/MySQL/PostgreSQL/SQLite; multi-user; Fever + Google Reader API; very active (separate recipe)
  - **Tiny Tiny RSS (tt-rss)** — PHP/PostgreSQL; venerable; more complex; plugin ecosystem
  - **Selfoss** — simpler PHP reader
  - **Wallabag** — "read-later" more than RSS; complementary (separate recipe)
  - **CommaFeed** — Java/Spring; Google Reader-style
  - **Reeder (macOS/iOS)** — commercial client; pairs with Miniflux via Fever/Google Reader API
  - **Feedbin / Feedly / Inoreader / NewsBlur** — SaaS readers
  - **Choose Miniflux if:** you want minimal, fast, opinionated, keyboard-first, Go-single-binary + Postgres.
  - **Choose FreshRSS if:** you need SQLite/MySQL, multi-user, or want PHP stack.
  - **Choose Wallabag if:** your goal is read-later articles, not RSS feed reading.

## Links

- Repo: <https://github.com/miniflux/v2>
- Website: <https://miniflux.app>
- Docs: <https://miniflux.app/docs/>
- Config reference: <https://miniflux.app/docs/configuration.html>
- Docker: <https://miniflux.app/docs/docker.html>
- Packages: <https://miniflux.app/docs/installation.html>
- Rules guide: <https://miniflux.app/docs/rules.html>
- Integrations: <https://miniflux.app/docs/services.html>
- Releases: <https://github.com/miniflux/v2/releases>
- Hosted: <https://miniflux.app/hosted.html>
- Mastodon: <https://fosstodon.org/@miniflux>
