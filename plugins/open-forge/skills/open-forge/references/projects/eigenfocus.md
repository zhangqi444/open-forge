---
name: Eigenfocus
description: "Self-hosted project management tool — without the clutter. Docker. Ruby on Rails. Eigenfocus/eigenfocus. Unlimited projects, boards, issues; list + board views; time tracking; focus space with timers; markdown; file attachments. Free edition AGPL-3.0; Pro edition available (one-time purchase)."
---

# Eigenfocus

**Self-hosted project management — powerful enough for complex projects, simple enough to actually use.** Unlimited projects, boards, and issues with list and board views, markdown descriptions, file attachments, labels, comments, due dates, and built-in time tracking. Includes a Focus Space with timers and ambient sounds for deep work. Available as a free (AGPL-3.0) edition and a paid Pro edition (one-time purchase, no subscriptions).

Built + maintained by **Eigenfocus**. Free edition: AGPL-3.0. Pro edition: commercial one-time purchase.

- Upstream repo: <https://github.com/Eigenfocus/eigenfocus>
- Docker Hub: `eigenfocus/eigenfocus`
- Website: <https://eigenfocus.com>
- Live demo (Pro): <https://pro-demo.eigenfocus.com/>

## Architecture in one minute

- **Ruby on Rails** web app
- **SQLite** — built-in, file-based database (no external DB needed)
- Port **3000** (internal), mapped to **3001** by default
- Data persisted in a single volume (`./app-data`)
- Resource: **low-medium** — Rails app with SQLite; no separate DB container required

## Compatible install methods

| Infra      | Runtime                    | Notes                                       |
| ---------- | -------------------------- | ------------------------------------------- |
| **Docker** | `eigenfocus/eigenfocus`    | **Primary** — single container, SQLite built-in |
| Cloud      | [eigenfocus.com](https://eigenfocus.com/pricing) | Managed cloud edition available |

## Install via Docker

```bash
docker run \
  --restart unless-stopped \
  -v ./app-data:/eigenfocus-app/app-data \
  -p 3001:3000 \
  -e DEFAULT_HOST_URL=http://localhost:3001 \
  -d \
  eigenfocus/eigenfocus:latest
```

Visit `http://localhost:3001`.

## Install via Docker Compose

```yaml
services:
  web:
    image: eigenfocus/eigenfocus:latest
    restart: unless-stopped
    volumes:
      - ./app-data:/eigenfocus-app/app-data
    environment:
      - DEFAULT_HOST_URL=http://localhost:3001   # Set to your public URL
    ports:
      - 3001:3000
```

```bash
docker compose up -d
```

## Environment variables

| Variable | Default | Notes |
|----------|---------|-------|
| `DEFAULT_HOST_URL` | _(required)_ | URL used to access Eigenfocus — e.g. `http://localhost:3001` or `https://tasks.example.com` |
| `FORCE_SSL` | `false` | If `true`, redirects all HTTP to HTTPS |
| `ASSUME_SSL_REVERSE_PROXY` | `false` | Set `true` behind a reverse proxy that terminates TLS (avoids infinite redirect loop when `FORCE_SSL=true`) |
| `HTTP_AUTH_USER` | _(empty)_ | Enable HTTP Basic Auth with this username |
| `HTTP_AUTH_PASSWORD` | _(empty)_ | HTTP Basic Auth password |

## Features overview

| Feature | Free | Pro |
|---------|------|-----|
| Unlimited projects, boards, issues | ✅ | ✅ |
| List and Board views | ✅ | ✅ |
| Markdown descriptions + file attachments | ✅ | ✅ |
| Labels, comments, due dates | ✅ | ✅ |
| Time tracking + reports | ✅ | ✅ |
| Focus Space (timers + ambient sounds) | ✅ | ✅ |
| Light and Dark themes | ✅ | ✅ |
| Multiple users with roles | ❌ | ✅ |
| Custom Fields | ❌ | ✅ |
| Grid View (columns + swimlanes) | ❌ | ✅ |
| Timeline View | ❌ | ✅ |
| Custom statuses + issue types | ❌ | ✅ |
| Project templates | ❌ | ✅ |
| SSO (Google, Microsoft, GitHub, OIDC) | ❌ | ✅ |

## Gotchas

- **`DEFAULT_HOST_URL` is required.** The app generates URLs and links based on this variable. Set it to the exact URL you'll use to access Eigenfocus — including protocol and port.
- **Reverse proxy + TLS.** When using a reverse proxy (Nginx, Caddy, Traefik), set `FORCE_SSL=true` and `ASSUME_SSL_REVERSE_PROXY=true` to avoid redirect loops.
- **HTTP Basic Auth.** If exposing to the internet, either use the Pro edition's user management or set `HTTP_AUTH_USER` + `HTTP_AUTH_PASSWORD` for a basic access gate.
- **Free edition is personal-use.** The free edition is AGPL-3.0 and lacks multi-user/team features. Upgrade to Pro for team workflows.
- **Pro is a one-time purchase.** No subscription — buy once, use forever.
- **AGPL-3.0 (free edition).** Network-service usage of modified Eigenfocus requires publishing changes under AGPL-3.0.

## Backup

```sh
# All data (SQLite + uploads) is in ./app-data
tar czf eigenfocus-backup-$(date +%F).tar.gz ./app-data
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Project health

Active Ruby on Rails development, free + Pro editions, AGPL-3.0 (free).

## Project-management-family comparison

- **Eigenfocus** — Rails/SQLite, clean UI, time tracking, Focus Space, free + Pro; AGPL-3.0 / commercial
- **Plane** — Next.js/Django, team-oriented, Jira-like; AGPL-3.0
- **Leantime** — PHP, Lean/Agile PM, goal tracking; GPL-2.0
- **Taiga** — Django/Angular, team PM, sprints; AGPL-3.0
- **Linear** — SaaS only; no self-hosted

**Choose Eigenfocus if:** you want a clean, distraction-free self-hosted project manager with time tracking and focus tools — especially for solo use or small teams (upgrade to Pro for team features).

## Links

- Repo: <https://github.com/Eigenfocus/eigenfocus>
- Docker Hub: <https://hub.docker.com/r/eigenfocus/eigenfocus>
- Website: <https://eigenfocus.com>
- Features comparison: <https://eigenfocus.com/features>
- Live Pro demo: <https://pro-demo.eigenfocus.com/>
