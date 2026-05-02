---
name: ticky
description: Ticky recipe for open-forge. Self-hosted Kanban task management with ASP.NET Core Blazor, MySQL, time tracking, subtasks, reminders, and Trello import. Based on upstream docs at https://github.com/dkorecko/Ticky.
---

# Ticky

Self-hosted Kanban-style task management system built with ASP.NET Core Blazor + MySQL. Features boards, columns, cards with drag-and-drop, subtasks, deadlines, time tracking, labels, priorities, attachments, card linking, email reminders, user management, dark mode, Trello import, repeat cards, and snooze cards. Always free and open-source. Upstream: <https://github.com/dkorecko/Ticky>.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Docker host (VPS, home server, laptop) | Docker Compose (ticky-app + ticky-db) | Recommended — app + MySQL 8 |
| Any Docker host (fully offline) | Docker Compose with `FULLY_OFFLINE=true` | Disables Gravatar avatars and external CDN assets; works air-gapped |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "What host port for Ticky?" | Default `4088` → maps to container port `8080` |
| preflight | "Public URL (BASE_URL)?" | Used for clickable links in emails; e.g. `http://localhost:4088` or `https://ticky.example.com` |
| security | "Database password?" | Replace all `your-secure-password` placeholders in compose — must match `DB_PASSWORD`, `MYSQL_ROOT_PASSWORD`, and `MYSQL_PASSWORD` |
| smtp | "Enable SMTP? (SMTP_ENABLED)" | Set `false` to disable email entirely (password resets via Admin Panel only) |
| smtp | "SMTP host and port?" | e.g. host: `smtp.gmail.com`, port: `587` |
| smtp | "SMTP email and display name?" | From address and sender name shown in emails |
| smtp | "SMTP username and password?" | Auth credentials for the SMTP server |
| smtp | "Use TLS? (SMTP_SECURITY)" | `true` for TLS/STARTTLS; set to match your provider's requirement |
| advanced | "Disable user self-registration?" | Set `DISABLE_USER_SIGNUPS=true` — admins then create users via Admin Panel |

## Software-layer concerns

**Key env vars** (from upstream `docker-compose.yaml`):

| Variable | Default | Purpose |
|---|---|---|
| `DB_HOST` | `ticky-db` | MySQL hostname (compose service name) |
| `DB_NAME` | `ticky` | Database name |
| `DB_USERNAME` | `ticky` | DB user |
| `DB_PASSWORD` | _(must set)_ | DB password — **change from placeholder** |
| `BASE_URL` | `http://localhost:4088` | Public URL for email links |
| `SMTP_ENABLED` | `true` | Toggle SMTP; `false` disables email features |
| `SMTP_HOST` | _(set your provider)_ | SMTP server hostname |
| `SMTP_PORT` | _(set your provider)_ | SMTP port (587 for STARTTLS, 465 for SSL) |
| `SMTP_DISPLAY_NAME` | `Ticky` | Sender display name |
| `SMTP_EMAIL` | _(set your email)_ | From address |
| `SMTP_USERNAME` | _(set your username)_ | SMTP auth user |
| `SMTP_PASSWORD` | _(set your password)_ | SMTP auth password |
| `SMTP_SECURITY` | `true` | TLS on/off |
| `FULLY_OFFLINE` | _(commented out)_ | Uncomment to disable all external CDN/avatar requests |
| `DISABLE_USER_SIGNUPS` | _(commented out)_ | Uncomment to disable self-registration |

**MySQL env vars:**

| Variable | Purpose |
|---|---|
| `MYSQL_DATABASE` | Must match `DB_NAME` |
| `MYSQL_USER` | Must match `DB_USERNAME` |
| `MYSQL_ROOT_PASSWORD` | Root password — **change from placeholder** |
| `MYSQL_PASSWORD` | Must match `DB_PASSWORD` |

**Ports:** `4088` (configurable) → container `8080`.

**Data volumes:** MySQL data is persisted via a named volume in compose (mapped to `ticky-db` service).

**Healthcheck:** MySQL uses `service_healthy` condition — Ticky app waits for DB to be ready before starting.

## Upgrade procedure

1. Pull new image: `docker compose pull`
2. Restart: `docker compose down && docker compose up -d`
3. Pin to a specific version in compose (e.g. `ghcr.io/dkorecko/ticky:v1.0.0`) for manual controlled upgrades — use `latest` for automatic updates.
4. Check logs: `docker logs ticky-app`

## Gotchas

- **All three password placeholders** (`DB_PASSWORD`, `MYSQL_ROOT_PASSWORD`, `MYSQL_PASSWORD`) must be changed to the **same value** before first start.
- `SMTP_ENABLED=false` disables password reset via email — admins must reset passwords through the Admin Panel.
- `FULLY_OFFLINE=true` disables auto-generated Gravatar avatars and any external font/asset loading — enable for air-gapped or privacy-sensitive deployments.
- Trello import maps Trello members to Ticky users — users must exist in Ticky first for the mapping to work.
- `BASE_URL` must be set correctly for reminder emails to contain clickable links; wrong URL = broken email links.

## Links

- GitHub: <https://github.com/dkorecko/Ticky>
- Docker Hub / GHCR: `ghcr.io/dkorecko/ticky:latest`
