---
name: Lowcoder
description: "Open-source low-code platform — build internal apps, websites, meeting tools, and dashboards. Docker. Node.js + MongoDB + Redis. lowcoder-org/lowcoder. Retool/Appsmith alternative. 120+ components."
---

# Lowcoder

**Open-source low-code platform to build internal apps, customer-facing web apps, interactive presentations, and collaboration tools.** 120+ built-in UI components, visual drag-and-drop editor, JavaScript everywhere, native data connections (PostgreSQL, MongoDB, MySQL, Redis, Elasticsearch, REST API, SMTP, WebSockets), RBAC, app themes, video meeting components, and a native embed SDK (no iFrames). Fork of the abandoned Openblocks project.

Built + maintained by the **Lowcoder team**. Community cloud at [app.lowcoder.cloud](https://app.lowcoder.cloud).

- Upstream repo: <https://github.com/lowcoder-org/lowcoder>
- Docs: <https://docs.lowcoder.cloud>
- Community cloud: <https://app.lowcoder.cloud>
- Docker Hub: <https://hub.docker.com/u/lowcoderorg>

## Architecture in one minute

- **Node.js** API service + **React** frontend
- **MongoDB 7** — primary DB (app definitions, users, data sources)
- **Redis 7** — caching + sessions
- Two Docker Compose variants: **all-in-one** (single container) or **multi-service** (separate containers)
- Ports: `3000` (frontend), `8080` (API) — or combined on one port in all-in-one
- Resource: **medium-to-heavy** — Node.js + MongoDB + Redis; plan for ≥2 GB RAM

## Compatible install methods

| Infra             | Runtime                          | Notes                                                                |
| ----------------- | -------------------------------- | -------------------------------------------------------------------- |
| **Docker (all-in-one)** | `lowcoderorg/lowcoder-all-in-one` | Simplest — single container with all services                  |
| **Docker Compose (multi)** | separate containers         | `deploy/docker/docker-compose-multi.yaml` — recommended for prod  |
| **Community cloud** | app.lowcoder.cloud              | Free tier SaaS; no self-host needed for evaluation                   |

## Inputs to collect

| Input                     | Example                          | Phase    | Notes                                                                           |
| ------------------------- | -------------------------------- | -------- | ------------------------------------------------------------------------------- |
| MongoDB password          | strong random                    | Storage  | `MONGO_INITDB_ROOT_PASSWORD` in compose                                         |
| Domain                    | `apps.example.com`               | URL      | Reverse proxy + TLS; set `LOWCODER_PUBLIC_URL` env                              |
| SMTP (optional)           | provider creds                   | Notify   | For invite emails + workspace notifications                                     |
| Admin user                | email + password                 | Auth     | Created via registration on first visit                                         |

## Install via Docker all-in-one

```sh
docker run -d \
  --name lowcoder \
  -p 3000:3000 \
  -v ./lowcoder-stacks:/lowcoder-stacks \
  --restart unless-stopped \
  lowcoderorg/lowcoder-all-in-one
```

Visit `http://<host>:3000`.

## Install via Docker Compose (multi-service, recommended)

```sh
curl -O https://raw.githubusercontent.com/lowcoder-org/lowcoder/main/deploy/docker/docker-compose-multi.yaml
# Edit: change MongoDB + Redis passwords, set LOWCODER_PUBLIC_URL
docker compose -f docker-compose-multi.yaml up -d
```

See [docs.lowcoder.cloud/setup-and-run/self-hosting](https://docs.lowcoder.cloud/lowcoder-documentation/setup-and-run/self-hosting) for full env var reference.

## First boot

1. Deploy container(s).
2. Visit the app URL → register admin account.
3. Create a **workspace** (org/team container).
4. Connect a **data source** (Postgres, REST API, etc.) — Data Sources section.
5. Build your first **app** with the visual editor.
6. Set up **RBAC** groups + permissions for your team.
7. Put behind TLS.
8. Back up MongoDB volume + `lowcoder-stacks/`.

## Data & config layout

- `./lowcoder-stacks/` (all-in-one) — MongoDB data + app assets + config
- Multi: `./lowcoder-stacks/data/mongodb/` + Redis volume

## Backup

```sh
docker compose exec mongodb mongodump \
  --username lowcoder --password <pw> \
  --db lowcoder --archive=/data/db/backup.archive
docker compose cp mongodb:/data/db/backup.archive ./lowcoder-backup-$(date +%F).archive
```

Contents: **all app definitions, data source connections (including credentials), users, RBAC config**. Treat data-source credentials as secrets.

## Upgrade

1. Releases: <https://github.com/lowcoder-org/lowcoder/releases>
2. `docker compose pull && docker compose up -d`
3. Review release notes — MongoDB schema migrations run automatically on start.

## Gotchas

- **All-in-one vs multi-service.** All-in-one is great for PoC; for production, use the multi-service compose — allows independent scaling + backup of each component.
- **MongoDB password change after init.** `MONGO_INITDB_ROOT_PASSWORD` only applies on first DB init. To change it later, exec into the container and use `mongosh` — just changing the env var does nothing once the DB is initialized.
- **`LOWCODER_PUBLIC_URL` must match what users see.** Lowcoder embeds this URL in OAuth redirects, email invites, and native embed links. Wrong URL = broken auth flows.
- **Resource floor.** MongoDB alone needs ~200 MB RAM idle; full stack realistically needs ≥2 GB. Don't run on a 512 MB VPS.
- **Native embed (no iFrame) is a standout feature** — allows Lowcoder apps to render as genuine DOM elements inside existing websites. Requires the embed SDK script tag. See [native embed docs](https://docs.lowcoder.cloud/lowcoder-documentation/lowcoder-extension/native-embed-sdk).
- **Video meeting components** — built-in WebRTC group video. Useful for building custom meeting rooms inside low-code apps (think "schedule a call" button that opens a meeting room inline).
- **WebSocket datasources** — real-time streaming data into components. Differentiator vs Retool/Appsmith.
- **Community plugin ecosystem** on npm (`lowcoder-comp-*`) for custom components.
- **Forked from Openblocks** (abandoned 2023) — existing Openblocks data directories are largely compatible; check migration notes in the Lowcoder README/MANIFESTO.

## Project health

Active, Docker Hub CI, community cloud, docs site, npm plugin ecosystem, Discord. Multi-contributor team. Forked from Openblocks.

## Low-code-platform-family comparison

- **Lowcoder** — Node.js + MongoDB + Redis, 120+ components, native embed, WebSocket, video meeting, RBAC
- **Appsmith** — similar scope, more mature, larger community, Java backend
- **Tooljet** — Node.js, similar feature set, strong integrations catalog
- **Budibase** — Node.js, PostgreSQL, built-in DB, strong on forms/workflows
- **Retool** — SaaS (self-host paid), most polished, enterprise-focused

**Choose Lowcoder if:** you want a fully open-source Retool/Appsmith alternative with native website embedding, WebSocket real-time data, and built-in video meeting components.

## Links

- Repo: <https://github.com/lowcoder-org/lowcoder>
- Docs: <https://docs.lowcoder.cloud>
- Self-hosting guide: <https://docs.lowcoder.cloud/lowcoder-documentation/setup-and-run/self-hosting>
- Appsmith (alt): <https://www.appsmith.com>
- Tooljet (alt): <https://www.tooljet.com>
