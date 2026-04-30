---
name: Shlink
description: "PHP-based self-hosted URL shortener — run shortened URLs under your own domain. CLI + REST API + official web client. Multi-tenant domains, QR codes, tags, visit tracking with GeoLite2. MIT."
---

# Shlink

Shlink is **the established, feature-rich self-hosted URL shortener** — PHP 8.4+ with PostgreSQL/MySQL/MariaDB/SQL Server/SQLite support. Built by **Alejandro Celaya** and contributors at **shlinkio**. Around since ~2017; mature, stable, enterprise-grade feature set. Separate official web client ([shlink-web-client](https://github.com/shlinkio/shlink-web-client)) gives you a polished admin UI; public hosted demo at app.shlink.io.

Features:

- **Multi-domain support** — shorten under any domain you control
- **Custom short codes** — auto or user-specified
- **Visit tracking** — unique/total, referrer, GeoLite2 geolocation, user-agent
- **QR codes** auto-generated
- **Tags** for organizing
- **Expiration** — by date or max-visits
- **Device-type redirects** — iOS vs Android vs desktop destinations
- **URL rules** — conditional redirects
- **REST API** (OpenAPI-documented) + CLI
- **Webhooks / RabbitMQ / Redis pub-sub** for events
- **OpenAPI-documented API**
- **RoadRunner** PHP app server option (high-perf)

- Upstream repo: <https://github.com/shlinkio/shlink>
- Web client repo: <https://github.com/shlinkio/shlink-web-client>
- Docs: <https://shlink.io/documentation/>
- Docker image: <https://hub.docker.com/r/shlinkio/shlink>
- API docs: <https://shlink.io/documentation/api-docs>
- API spec sandbox: <https://api-spec.shlink.io/>
- Hosted web client: <https://app.shlink.io>

## Architecture in one minute

- **PHP 8.4 or 8.5** (latest release req'd) + required extensions: json/curl/pdo/intl/gd/gmp or bcmath
- **Database**: MySQL / MariaDB / PostgreSQL / MSSQL / SQLite
- **Optional**: RoadRunner (PHP app server), Redis (caching), RabbitMQ (events)
- **Web client is a SEPARATE deployment** — static SPA; point at Shlink API
- **Resource**: 300-500 MB RAM; scales well horizontally
- **GeoLite2 (MaxMind)** for geolocation — you must provide license key

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Single VM          | **Docker (`shlinkio/shlink`)**                                     | **Most common**                                                                    |
| Kubernetes         | Community Helm charts                                                      | Works                                                                                      |
| Bare-metal LAMP    | PHP 8.4 + MySQL + dist file                                                           | Traditional                                                                                         |
| Raspberry Pi       | arm64 Docker image                                                                               | Works well                                                                                                         |
| Shared hosting     | Possible with PHP 8.4+ availability                                                                                        | Rare at that PHP version                                                                                                                        |

## Inputs to collect

| Input                | Example                                           | Phase        | Notes                                                                    |
| -------------------- | ------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Short-link domain    | `short.example.com` OR `sho.rt`                       | URL          | Buy a short TLD; CNAME to Shlink                                                 |
| Default domain       | set via env                                                | Config       | First domain Shlink serves                                                                 |
| DB                   | MySQL / MariaDB / Postgres / SQLite                                    | Storage      | Postgres or MySQL for production                                                                         |
| GeoLite2 key         | MaxMind (free signup)                                                   | Geoloc       | REQUIRED for country/city stats — Shlink won't error without, but stats degraded                         |
| API key              | generated via CLI                                                                   | Auth         | For web client + API integrations                                                                                      |
| Web client           | Deploy separately (or use hosted app.shlink.io)                                                                    | UI           | Optional but highly useful                                                                                                              |

## Install via Docker

```yaml
services:
  shlink:
    image: shlinkio/shlink:stable                       # pin specific version in prod
    container_name: shlink
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      DEFAULT_DOMAIN: short.example.com
      IS_HTTPS_ENABLED: "true"
      DB_DRIVER: maria
      DB_HOST: db
      DB_USER: shlink
      DB_PASSWORD: CHANGE_ME
      DB_NAME: shlink
      GEOLITE_LICENSE_KEY: YOUR_MAXMIND_LICENSE_KEY
      INITIAL_API_KEY: "some-initial-api-key-for-bootstrap"
    depends_on:
      - db

  db:
    image: mariadb:11
    restart: unless-stopped
    environment:
      MARIADB_ROOT_PASSWORD: CHANGE_ROOT
      MARIADB_DATABASE: shlink
      MARIADB_USER: shlink
      MARIADB_PASSWORD: CHANGE_ME
    volumes:
      - ./db:/var/lib/mysql

  shlink-web-client:
    image: shlinkio/shlink-web-client:latest
    restart: unless-stopped
    ports:
      - "8081:8080"
    environment:
      DEFAULT_SERVER_NAME: "Shlink"
      DEFAULT_SERVER_URL: https://short.example.com
      DEFAULT_SERVER_API_KEY: "some-initial-api-key-for-bootstrap"
```

Point `short.example.com` at Shlink via reverse proxy on 443.

## First boot

1. Create first API key: `docker exec shlink shlink api-key:generate`
2. Open web client → add server (URL + API key)
3. Create first short URL: `https://short.example.com/abc`
4. Visit → verify 301 redirect works
5. Check stats page → verify visit tracked
6. Add MaxMind GeoLite2 key → restart → geolocation populates
7. Add additional domains if multi-tenant

## Data & config layout

- Database = source of truth (URLs + visits + tags + domains)
- `/etc/shlink/data/` — local cache, GeoLite2 DB
- API keys managed via CLI only (per README)

## Backup

```sh
mysqldump -u shlink --single-transaction shlink > shlink-$(date +%F).sql
```

DB can get large with high-visit links. Prune or archive old visits if needed.

## Upgrade

1. Releases: <https://github.com/shlinkio/shlink/releases>. Active, disciplined release cadence.
2. Major versions bump PHP requirements + have migration scripts.
3. **Back up DB before every major upgrade.** Shlink has excellent migration discipline but always back up.
4. Docker: bump tag → restart → migrations auto.

## Gotchas

- **PHP 8.4 / 8.5 is a hard requirement** for current Shlink. If you're stuck on PHP 8.1/8.2, pin to an older Shlink branch (check release notes). Shared hosting often lags current PHP.
- **GeoLite2 license key required** for geolocation: free MaxMind account + license key. Without it, country/city stats are empty (not broken, just blank).
- **API keys = full admin on scope** — treat as secrets. Rotate if leaked. Scope via roles where possible (domain-scoped keys).
- **Short-link domain is permanent-ish**: URLs shortened under `short.example.com` are fixed. Changing domain breaks all existing shortened links. Choose a stable domain.
- **Multi-tenant domains**: Shlink supports many short-domains on one install. Powerful + also risky if tenants aren't trusted with each other's shortlinks.
- **RoadRunner vs php-fpm**: RoadRunner is faster for high-load (10k+ redirects/sec). For most homelab/startup use, default php-fpm is fine.
- **Visit tracking + privacy**: Shlink logs IPs + user agents + geolocation by default. For GDPR, ensure you have a privacy notice on the shortener's landing / in retention policy. You CAN anonymize IPs + disable tracking.
- **URL shortener = phishing-adjacent threat**: attackers LOVE short URLs. If you run a public shortener, implement abuse reporting, rate-limits, and block obvious phishing domains. Cloudflare in front = recommended.
- **Private use vs public**: locking API-key creation is easy. Restrict who can create shorts = most deploys.
- **DB growth**: visits table can grow fast. Shlink has `short-urls:delete-expired-visits` + archival options. Plan retention.
- **Separate web client deployment** — not bundled with the server. Deploy both or use hosted app.shlink.io.
- **License**: **MIT**.
- **Bus factor**: Alejandro Celaya-led with contributors; JetBrains sponsors with IDE licenses; steady multi-year release cadence. Healthy project.
- **Alternatives worth knowing:**
  - **YOURLS** — PHP; older; simpler
  - **Polr** — PHP; simpler; less active
  - **Kutt.it** — Node.js; simpler UI
  - **LinkAce** — more bookmark-manager than shortener
  - **Simple-URL / dub-co** — commercial SaaS / newer
  - **Bitly / TinyURL** — commercial
  - **Choose Shlink if:** feature-rich, multi-domain, API-first, GeoLite2 stats, enterprise-ready.
  - **Choose YOURLS if:** LAMP-host + simpler needs.
  - **Choose Kutt.it if:** Node stack preferred + simpler UI.

## Links

- Repo: <https://github.com/shlinkio/shlink>
- Web client: <https://github.com/shlinkio/shlink-web-client>
- Docs: <https://shlink.io/documentation/>
- API docs: <https://shlink.io/documentation/api-docs>
- API sandbox: <https://api-spec.shlink.io/>
- Docker Hub: <https://hub.docker.com/r/shlinkio/shlink>
- Web client Docker: <https://hub.docker.com/r/shlinkio/shlink-web-client>
- Hosted web client: <https://app.shlink.io>
- GeoLite2 (MaxMind): <https://dev.maxmind.com/geoip/geolite2-free-geolocation-data>
- YOURLS (alt): <https://yourls.org>
- Kutt.it (alt): <https://kutt.it>
