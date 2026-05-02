# Mbin

Mbin is a decentralized content aggregator, voting, discussion, and microblogging platform running on the fediverse (ActivityPub). It can communicate with Mastodon, Lemmy, Pixelfed, Pleroma, PeerTube and other ActivityPub services. Mbin is a community-focused fork of /kbin — built with PHP (Symfony), PostgreSQL, Redis, RabbitMQ, and Mercure for real-time federation.

- **Official site / docs:** https://docs.joinmbin.org
- **GitHub:** https://github.com/MbinOrg/mbin
- **Docker image:** `ghcr.io/mbinorg/mbin` (multi-service stack, see Docker guide)
- **License:** AGPL-3.0

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| VPS / bare metal | Docker Compose | Full stack: PHP-FPM, Nginx, PostgreSQL, Redis, Mercure, RabbitMQ, workers |
| VPS / bare metal | Bare metal | PHP 8.2+, nginx, PostgreSQL, Redis, Mercure, RabbitMQ — see bare metal guide |

---

## Inputs to Collect

### Deploy Phase (key environment variables)
| Variable | Required | Description |
|----------|----------|-------------|
| `SERVER_NAME` | Yes | Your domain name (e.g. `mbin.example.com`) |
| `APP_SECRET` | Yes | Random string for Symfony secrets (use `openssl rand -hex 32`) |
| `POSTGRES_PASSWORD` | Yes | PostgreSQL password |
| `POSTGRES_DB` | No | Database name (default: `kbin`) |
| `MERCURE_JWT_SECRET` | Yes | Mercure hub JWT secret |
| `RABBITMQ_PASSWORD` | Yes | RabbitMQ password |
| `MAILER_DSN` | Yes | Mail transport (e.g. `smtp://user:pass@smtp.host:587`) |
| `DEFAULT_LOCALE` | No | Locale, default `en` |
| `KBIN_DOMAIN` | Yes | Your domain (same as `SERVER_NAME`) |
| `KBIN_TITLE` | No | Instance title |
| `KBIN_DEFAULT_LANG` | No | Default UI language |
| `KBIN_FEDERATION_ENABLED` | No | Enable ActivityPub federation (`1` = yes) |
| `KBIN_REGISTRATIONS_ENABLED` | No | Enable open signups (`1` = yes) |

---

## Software-Layer Concerns

### Architecture (Docker Compose stack)
Mbin requires multiple services:
- **www** — Nginx web server
- **php** — PHP-FPM application
- **messenger** — Symfony messenger worker (async jobs)
- **messenger_ap** — ActivityPub messenger worker
- **redis** — Session/cache store
- **db** — PostgreSQL database
- **rabbitmq** — Message queue
- **mercure** — Real-time event hub (SSE/WebSockets for federation)

### Config
- App config via `.env` file (copy from `.env.example`)
- Symfony `config/packages/` for advanced settings

### Data Directories
- PostgreSQL data volume (persistent)
- Public uploads (avatars, media) — volume mounted at Nginx/PHP paths

### Ports
- `443` / `80` — Nginx (HTTPS + HTTP redirect)

---

## Setup Steps

Follow the official Docker guide: https://docs.joinmbin.org/admin/installation/docker/

Key steps:
```bash
git clone https://github.com/MbinOrg/mbin.git && cd mbin
cp .env.example .env
# Edit .env: fill in required vars (see above)
docker compose build
docker compose up -d
docker compose exec php bin/console doctrine:migrations:migrate
docker compose exec php bin/console mbin:admin:create
```

---

## Upgrade Procedure

```bash
git pull
docker compose build
docker compose up -d
docker compose exec php bin/console doctrine:migrations:migrate --no-interaction
docker compose exec php bin/console cache:clear
```

Check release notes for breaking changes before upgrading.

---

## Gotchas

- **Complex stack:** Mbin is a full fediverse platform — not a simple single-container app; read the docs before deploying
- **RabbitMQ required:** Both messenger workers rely on RabbitMQ; without it, federation and async jobs won't function
- **Mercure required:** Real-time federation (activity delivery) uses Mercure — required for proper ActivityPub behavior
- **Email required:** Password resets and email verification require a working `MAILER_DSN`
- **Migrations on upgrade:** Always run `doctrine:migrations:migrate` after updating — schema changes are common
- **`/kbin` legacy config names:** Many env vars still use `KBIN_` prefix (Mbin's fork origin) — this is intentional
- **Federation DNS:** Your instance needs a public HTTPS domain for federation — self-signed certs or local IPs won't federate with other instances
- **Bare metal guide available:** If Docker is too complex, the bare metal guide at docs.joinmbin.org covers nginx + systemd setup

---

## References
- Docker installation guide: https://docs.joinmbin.org/admin/installation/docker/
- Bare metal guide: https://docs.joinmbin.org/admin/installation/bare_metal/
- GitHub: https://github.com/MbinOrg/mbin
- Matrix community: https://matrix.to/#/#mbin:melroy.org
