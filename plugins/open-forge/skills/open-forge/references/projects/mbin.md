---
name: mbin-project
description: Mbin recipe for open-forge. Self-hosted decentralized content aggregator, voting, discussion, and microblogging platform on the fediverse. Fork of /kbin. ActivityPub federation with Mastodon, Lemmy, Pixelfed, Pleroma, PeerTube. Community-maintained. PHP/Symfony + PostgreSQL + Redis + RabbitMQ + Mercure. Complex multi-container deployment. Upstream: https://github.com/MbinOrg/mbin
---

# Mbin

A self-hosted, decentralized content aggregator, voting, discussion, and microblogging platform for the fediverse. Fork and community continuation of /kbin. Federates with Mastodon, Lemmy, Pixelfed, Pleroma, PeerTube, and other ActivityPub services. Supports all ActivityPub Actor Types including "Service" (robot) accounts.

Community-maintained with no single maintainer -- PRs can be merged by any maintainer with merge rights.

Built on PHP/Symfony with PostgreSQL, Redis, RabbitMQ, and Mercure. Complex multi-container deployment.

Upstream: <https://github.com/MbinOrg/mbin> | Docs: <https://docs.joinmbin.org> | Instances list: <https://joinmbin.org/servers>

> **Note**: Mbin is a complex, production-grade fediverse platform. Follow the official Docker deployment guide for a complete and current setup: <https://docs.joinmbin.org/admin/installation/docker/>

## Compatible combos

| Infra | Notes |
|---|---|
| Public VPS (AMD64, 2+ GB RAM) | Requires a real public domain for federation; multiple services |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Domain name?" | Required for ActivityPub federation (e.g. `mbin.example.com`) -- cannot change after launch |
| preflight | "Admin email?" | For Let's Encrypt and admin account |
| config | "DB credentials?" | `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB` |
| config | "App secret?" | `APP_SECRET` -- generate with `openssl rand -hex 32` |
| config | "S3/storage config?" | Optional; for media storage (local filesystem or S3-compatible) |

## Software-layer concerns

For the complete, current Docker Compose setup, environment variable reference, and first-run instructions, refer exclusively to the official documentation:

**Docker installation guide**: <https://docs.joinmbin.org/admin/installation/docker/>
**Bare metal / VM guide**: <https://docs.joinmbin.org/admin/installation/bare_metal>

The upstream repo also includes a development server guide: <https://docs.joinmbin.org/contributing/development_server>

### General stack

Mbin requires several services working together:

| Service | Purpose |
|---|---|
| PHP-FPM / Caddy (or nginx) | Application server + web server |
| PostgreSQL | Primary database |
| Redis | Caching and session storage |
| RabbitMQ | ActivityPub message queue (federation) |
| Mercure | Real-time push notifications |
| Meilisearch | Full-text search (optional but recommended) |

### Key concerns

- **Domain is permanent** -- the domain name is embedded in all ActivityPub objects (users, posts, magazines). Once you set it and start federating, you cannot change it without breaking federation.
- **Public domain required** -- other fediverse instances need to reach your server over HTTPS on port 443 for federation to work. A LAN-only or private IP setup will not federate.
- **APP_SECRET** -- must be a long random string. Generate: `openssl rand -hex 32`. Do not reuse across instances.
- **Federation queue** -- RabbitMQ handles the async ActivityPub delivery queue. Without it, federation stalls.
- **Migrations** -- run `php bin/console doctrine:migrations:migrate` after every upgrade.

### Update strategy

```bash
docker compose pull
docker compose up -d
# Then run migrations:
docker compose exec php php bin/console doctrine:migrations:migrate --no-interaction
```

Always check the [release notes](https://github.com/MbinOrg/mbin/releases) before upgrading -- some releases require additional steps.

## Upgrade procedure

Follow the official upgrade guide in the docs: <https://docs.joinmbin.org>

Key steps:
1. `docker compose pull`
2. `docker compose up -d`
3. Run database migrations
4. Clear caches if needed: `php bin/console cache:clear`

Check release notes for any additional upgrade steps before applying.

## Gotchas

- **Complex setup** -- Mbin is not a quick-deploy app. Budget time for initial setup, especially DNS, TLS, and RabbitMQ configuration.
- **Resource requirements** -- PHP-FPM, RabbitMQ, Redis, and PostgreSQL together require at least 2 GB RAM. 4 GB recommended for active instances.
- **Domain is final** -- set your domain carefully before first run. Changing it breaks all existing federation and user accounts.
- **Always refer to official docs** -- the Docker setup is actively maintained and changes between releases. Use <https://docs.joinmbin.org/admin/installation/docker/> rather than any third-party tutorial.
- **Queue workers** -- RabbitMQ consumers must be running for federation to work. Monitor queue depth and consumer health.
- **Media storage** -- default is local filesystem; configure S3-compatible storage for scalability and backups.
- **Security advisories** -- Mbin has Dependabot, GitHub Security Advisories, and code scanning enabled. Subscribe to release notifications to stay on top of security updates.

## Links

- Upstream README: <https://github.com/MbinOrg/mbin>
- Docker installation: <https://docs.joinmbin.org/admin/installation/docker/>
- Bare metal installation: <https://docs.joinmbin.org/admin/installation/bare_metal>
- Releases: <https://github.com/MbinOrg/mbin/releases>
- Instances list: <https://joinmbin.org/servers>
- Matrix chat: <https://matrix.to/#/#mbin:melroy.org>
- Translations: <https://hosted.weblate.org/engage/mbin/>
