# Domain Watchdog

Domain Watchdog uses RDAP to collect publicly available domain name info, tracks their history, and can automatically purchase domains when they become available. Built with PHP/Symfony, PostgreSQL, Redis/Valkey, and a worker process for async RDAP monitoring. Useful for snagging expiring domains via supported registrar APIs.

- **Official site / docs:** https://domainwatchdog.eu
- **GitHub:** https://github.com/maelgangloff/domain-watchdog
- **Docker image:** `maelgangloff/domain-watchdog:latest`
- **License:** AGPL-3.0

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| VPS / bare metal | Docker Compose | Multi-container: app + PHP worker + PostgreSQL + Valkey (Redis) |

---

## Inputs to Collect

### Deploy Phase (.env.local)
| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| SERVER_NAME | No | :80 | Bind address/port (e.g. :80 or yourdomain.com) |
| APP_SECRET | Yes | — | Symfony app secret — replace with random string |
| POSTGRES_USER | No | app | PostgreSQL username |
| POSTGRES_PASSWORD | Yes | !ChangeMe! | PostgreSQL password — change this |
| POSTGRES_DB | No | app | PostgreSQL database name |
| POSTGRES_VERSION | No | 16 | PostgreSQL version |
| JWT_PASSPHRASE | Yes | — | JWT key passphrase — change from default |
| MAILER_DSN | No | null://null | Mail transport for notifications |
| HTTP_SECURE_COOKIE | No | true | Set false if running over plain HTTP (no TLS) |

Config goes in .env.local (not .env) — see the develop branch for the full example.

---

## Software-Layer Concerns

### Architecture (Docker Compose stack)
- **domainwatchdog** — Nginx + PHP-FPM application (Caddy integration for TLS)
- **php-worker** — Symfony Messenger consumer for async RDAP jobs
- **database** — PostgreSQL
- **valkey** — Redis-compatible cache and message queue

### Config
- .env.local — secrets and overrides (never commit)
- .env — default values
- Volumes: caddy_data, caddy_config for TLS; database_data for Postgres; ./public/content for static customization

### Ports
- 8080 (host) -> 80 (container), bound to 127.0.0.1 by default (use reverse proxy for HTTPS)

---

## Setup Steps

```bash
curl -O https://raw.githubusercontent.com/maelgangloff/domain-watchdog/develop/docker-compose.yml
curl -O https://raw.githubusercontent.com/maelgangloff/domain-watchdog/develop/.env
cp .env .env.local
# Edit .env.local: set APP_SECRET, POSTGRES_PASSWORD, JWT_PASSPHRASE, MAILER_DSN
docker compose pull
docker compose up -d
```

---

## Upgrade Procedure

```bash
docker compose pull
docker compose up -d
```

Symfony Doctrine migrations typically run automatically on start; verify in the docs.

---

## Gotchas

- **.env.local is the active config:** Symfony loads .env then .env.local overrides — put all secrets in .env.local
- **APP_SECRET must be changed:** A long random string; leaking it compromises session security
- **HTTP_SECURE_COOKIE=false for HTTP:** Required if accessing without HTTPS/reverse proxy
- **RDAP rate limits:** Built-in caching minimises requests, but heavy domain monitoring may still hit provider limits
- **Auto-purchase requires registrar API:** Monitoring is open; buying domains requires configuring a supported registrar API key (Gandi, OVH, etc.) — see docs for provider setup
- **php-worker is required:** The worker container runs async RDAP polling jobs — without it domains won't be actively monitored
- **Not affiliated with registrars:** You supply your own registrar API credentials

---

## References
- Installation docs: https://domainwatchdog.eu/en/install-config/install/docker-compose/
- Provider docs: https://domainwatchdog.eu/en/developing/implementing-new-provider/
- GitHub: https://github.com/maelgangloff/domain-watchdog
