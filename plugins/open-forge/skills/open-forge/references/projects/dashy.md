---
name: Dashy
description: Self-hosted start-page / dashboard with status-checking, widgets, icons, and theme/layout editing (Node.js + Vue).
---

# Dashy

Dashy is a single-container dashboard that renders a configurable start page of services and widgets driven by a YAML file (`conf.yml`). It ships a small Node.js/Express server plus a Vue SPA and optional status-check ping backend.

- Upstream repo: <https://github.com/Lissy93/dashy>
- Live demo + docs: <https://dashy.to/docs/>
- Official image (Docker Hub): `lissy93/dashy` — also published to `ghcr.io/lissy93/dashy`

## Compatible install methods

| Infra               | Runtime                              | Notes                                     |
| ------------------- | ------------------------------------ | ----------------------------------------- |
| Any Linux host      | Docker + Compose                     | Recommended; upstream publishes `compose.yml` |
| Kubernetes          | Helm / plain manifests               | Community charts exist; not official      |
| Bare metal (Node)   | `yarn build && yarn start` (node 20) | Dev/hack only                             |

## Inputs to collect

| Input          | Example                          | Phase   | Notes                                                         |
| -------------- | -------------------------------- | ------- | ------------------------------------------------------------- |
| Domain/host    | `dash.example.com`               | Runtime | Reverse proxy terminates TLS; Dashy itself serves plain HTTP  |
| Listen port    | `4000`                           | Runtime | Container listens on 8080; `-p 4000:8080` by default          |
| Config file    | `./user-data/conf.yml`           | Runtime | Required — without it Dashy boots a default demo dashboard    |
| UID/GID        | `1000:1000`                      | Runtime | Match host owner of `user-data/` if perm errors appear        |

## Install via Docker Compose

Upstream ships this minimal `compose.yml` (verbatim at <https://github.com/Lissy93/dashy/blob/master/docker-compose.yml>). Pin a tag in production — track releases at <https://github.com/Lissy93/dashy/releases>.

```yaml
services:
  dashy:
    container_name: Dashy
    image: lissy93/dashy:3.1.1   # pin; avoid :latest for production
    ports:
      - 4000:8080
    volumes:
      - ./user-data:/app/user-data
    environment:
      - NODE_ENV=production
    restart: unless-stopped
    healthcheck:
      test: ['CMD', 'node', '/app/services/healthcheck.js']
      interval: 1m30s
      timeout: 10s
      retries: 3
      start_period: 30s
```

1. `mkdir -p user-data && touch user-data/conf.yml`
2. Populate `conf.yml` — start from <https://github.com/Lissy93/dashy/blob/master/user-data/conf.yml> (the upstream sample).
3. `docker compose up -d`; browse `http://<host>:4000`.

Dashy hot-reloads `conf.yml` after a "rebuild app" action in the UI (saves + runs `yarn build` inside the container). A full file replace also works; no restart needed for most changes.

## Data & config layout

- `/app/user-data/conf.yml` — main config (sections, items, themes, auth, widgets)
- `/app/user-data/` — also holds any local icons, custom CSS, fonts you reference from `conf.yml`
- The Vue bundle lives under `/app/dist` inside the image; rebuilt on config save

Back up the entire `user-data/` directory — that's your dashboard.

## Upgrade

1. Bump the image tag in `compose.yml` (see <https://github.com/Lissy93/dashy/releases>).
2. `docker compose pull && docker compose up -d`.
3. Check release notes for config schema changes — Dashy validates `conf.yml` at boot and logs errors.

## Gotchas

- **No built-in auth by default.** Dashy has optional client-side auth via `conf.yml > appConfig.auth` but it is not server-enforced. Put Dashy behind an auth-aware reverse proxy (Authelia, Authentik, Tailscale Funnel, etc.) if exposing publicly.
- **Volume permissions.** If you mount `user-data/` from the host, Dashy's internal rebuild step needs write access. Set `user: "1000:1000"` or `chown -R 1000:1000 user-data` on the host.
- **`conf.yml` required for real use.** Without it the container serves the default sample — fine for trying, confusing in production.
- **Widgets that poll external services** (ping, status) hit those services from *inside* the Dashy container. Services reachable only on your host network need the container on `network_mode: host` or appropriate egress rules.
- **Rebuilding from UI is destructive** to any `conf.yml` edits made outside Docker — keep a copy in version control.

## Links

- Docs: <https://dashy.to/docs/>
- Quick-start: <https://dashy.to/docs/quick-start>
- Configuring: <https://dashy.to/docs/configuring>
- Releases: <https://github.com/Lissy93/dashy/releases>
- Docker Hub: <https://hub.docker.com/r/lissy93/dashy>
