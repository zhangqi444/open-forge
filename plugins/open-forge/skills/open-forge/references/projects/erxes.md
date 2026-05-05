---
name: erxes-project
description: Erxes recipe for open-forge. Open-source XOS (Experience Operating System) — CRM, marketing, sales, and support platform. Docker. Upstream: https://github.com/erxes/erxes
---

# erxes

Open-source Experience Operating System (XOS) that unifies CRM, marketing, sales, operations, and support into a single platform. Plugin-based architecture — replaces tools like HubSpot, Zendesk, Linear. Includes team inbox, live chat, messenger, sales pipelines, lead capture forms, email campaigns, contact management, task management, and a knowledge base. Licensed AGPLv3. Upstream: https://github.com/erxes/erxes. Docs: https://erxes.io/docs

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Ubuntu 20.04+ VPS/bare-metal | Docker Compose | Primary self-host method; requires Ubuntu |
| MacOS | Docker Compose | macOS supported for dev; not recommended for prod |

erxes is a complex monorepo (Nx) with multiple services. Docker Compose is the only officially supported self-hosted deployment method.

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Ubuntu 20.04 or higher? | Hard requirement from upstream |
| preflight | Domain for erxes | Used for service URLs and reverse proxy |
| preflight | Node.js v12+ and npm 6+ installed? | Required for some setup tasks |
| preflight | Minimum 4 CPU / 8 GB RAM available? | Recommended for production |
| smtp | SMTP credentials | For email campaigns and notifications |
| smtp | From email / domain | Outbound email identity |

## Software-layer concerns

### Prerequisites

- Ubuntu 20.04 or higher
- Docker + Docker Compose
- Node.js v12+ / npm 6+
- Minimum 4 vCPU, 8 GB RAM, 40 GB disk recommended

### Install

Follow the official installation guide: https://erxes.io/docs/installation

The install process uses the erxes CLI / Docker Compose stack. Upstream docs walk through the full setup steps including DNS, certificates, and first-run configuration.

### Services architecture

erxes is a microservices system. The Docker Compose stack typically includes:

- Core API (GraphQL Federation gateway)
- Worker services
- Plugin services (inbox, sales, contacts, etc.)
- MongoDB — primary data store
- Redis — caching and message queue
- RabbitMQ — service bus
- Elasticsearch (optional) — full-text search

### Plugin marketplace

After installing erxes XOS, additional plugins can be installed from the marketplace: https://erxes.io/marketplace

Plugins include: Team Inbox, Messenger, Sales Management, Lead Generation, Engage (email/SMS campaigns), Contact Management, Knowledge Base, Task Management.

### Port reference

- 3000 — erxes UI (default)
- 3300 — Core API (default)
- Reverse proxy (nginx/Caddy) recommended for TLS on 443

### Data persistence

Mount volumes for:
- MongoDB data directory
- Uploaded media/assets

## Upgrade procedure

```bash
# Pull latest images and restart
docker compose pull
docker compose up -d
```

Check changelog before upgrading: https://erxes.io/changelog

For major version upgrades, consult the migration docs on https://erxes.io/docs — data migrations may be required.

## Gotchas

- Ubuntu only for production — upstream only documents and supports Ubuntu 20.04+; other Linux distros may work but are unsupported.
- Heavy resource requirements — erxes runs 10+ services; a small VPS (1–2 GB RAM) will struggle. Minimum 8 GB RAM recommended.
- MongoDB + Redis + RabbitMQ required — erxes depends on three infrastructure services; plan for managing and backing them up.
- Microservices complexity — unlike single-binary apps, erxes updates can involve multiple service versions changing simultaneously; always test upgrades on a staging instance.
- AGPLv3 license — if you modify erxes and expose it as a network service, you must release your modifications under AGPLv3.
- Plugin state — plugins are installed/enabled per-instance; document which plugins your instance uses so they can be re-enabled after a fresh install.
- Email deliverability — Engage (email campaigns) requires a properly configured SMTP relay with SPF/DKIM/DMARC for acceptable deliverability.

## Links

- Upstream repo: https://github.com/erxes/erxes
- Website: https://erxes.io
- Documentation: https://erxes.io/docs
- Installation guide: https://erxes.io/docs/installation
- Plugin marketplace: https://erxes.io/marketplace
- Changelog: https://erxes.io/changelog
- Discord community: https://discord.com/invite/aaGzy3gQK5
