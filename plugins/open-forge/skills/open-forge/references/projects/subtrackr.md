---
name: subtrackr-project
description: SubTrackr recipe for open-forge. Self-hosted subscription management app. Track subscriptions, visualize monthly/annual spending, calendar view of renewal dates, email + Pushover notifications, multi-currency (14 currencies + optional real-time conversion via Fixer.io), iCal export, 5 themes, MCP server for AI integration. Go + HTMX + SQLite. Single container. Multi-arch (AMD64 + ARM64). Upstream: https://github.com/bscott/subtrackr
---

# SubTrackr

A self-hosted subscription management app built with Go and HTMX. Track all your subscriptions, visualize monthly and annual spending, see a calendar view of renewal dates, and get email or Pushover notifications before renewals hit. Multi-currency support (14 currencies + optional real-time conversion via Fixer.io API). Export to CSV, JSON, or iCal. Includes an MCP server for AI assistant integration (Claude etc.). Five visual themes including a festive Christmas theme with snowfall animation.

No external database — uses SQLite.

Upstream: <https://github.com/bscott/subtrackr> | Container: `ghcr.io/bscott/subtrackr`

Multi-arch: AMD64 + ARM64 (including Apple Silicon and Raspberry Pi).

## Compatible combos

| Infra | Notes |
|---|---|
| Any Linux host (AMD64/ARM64) | Single container; SQLite; no external DB needed |
| Raspberry Pi | ARM64 image available |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Host port?" | Default: `8080` — web UI |
| config | "Fixer.io API key?" | `FIXER_API_KEY` — optional; only needed for real-time currency conversion |

## Software-layer concerns

### Image

```
ghcr.io/bscott/subtrackr:latest
```

GitHub Container Registry. Multi-arch (AMD64 + ARM64).

### Compose

```yaml
services:
  subtrackr:
    image: ghcr.io/bscott/subtrackr:latest
    container_name: subtrackr
    ports:
      - "8080:8080"
    volumes:
      - ./data:/app/data
    environment:
      - PORT=8080
      # Optional: Fixer.io API key for real-time currency conversion
      # - FIXER_API_KEY=your_fixer_api_key_here
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    restart: unless-stopped

volumes:
  subtrackr_data:
```

> Source: upstream README — <https://github.com/bscott/subtrackr>

### Key environment variables

| Variable | Required | Default | Purpose |
|---|---|---|---|
| `PORT` | — | `8080` | Server port |
| `FIXER_API_KEY` | — | None | Fixer.io API key for real-time currency conversion (optional) |

### Volumes

| Path | Purpose |
|---|---|
| `./data:/app/data` | SQLite database and app data |

### Features

- **Dashboard** — monthly and annual spending totals with per-subscription breakdown
- **Calendar view** — visual calendar of all renewal dates; iCal export + subscription URL
- **Analytics** — spending by category; savings tracking
- **Email notifications** — SMTP-based renewal reminders (configured in web UI)
- **Pushover notifications** — push notifications to mobile devices
- **Multi-currency** — USD, EUR, GBP, JPY, RUB, SEK, PLN, INR, CHF, BRL, COP, BDT, CNY; optional real-time conversion via Fixer.io
- **Export** — CSV, JSON, iCal
- **Themes** — Default (Light), Dark, Christmas 🎄 (snowfall animation), Midnight (Purple), Ocean (Cyan)
- **MCP server** — Model Context Protocol integration for Claude and other AI assistants
- **Optional auth** — enable login for your SubTrackr instance; configured in Settings
- **Mobile responsive** — hamburger menu navigation on small screens

### Email notifications

Configure SMTP settings in the web UI under Settings → Notifications. Supports common SMTP providers (Gmail, custom SMTP servers, etc.).

### Currency conversion

14 currencies are supported with static conversion rates. For real-time conversion, sign up at [Fixer.io](https://fixer.io) (free tier available) and set `FIXER_API_KEY`.

### MCP server

SubTrackr exposes an MCP (Model Context Protocol) endpoint for AI assistant integration. This allows Claude or other MCP-compatible AI tools to query your subscription data. See upstream README for configuration details.

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Data persists in `./data` bind mount (SQLite database).

## Gotchas

- **`./data` directory must exist** — create it before first run (`mkdir -p data`) or Docker creates it as root-owned, which may cause write permission errors.
- **Fixer.io is optional** — the app works fully without it using static exchange rates. Only add `FIXER_API_KEY` if real-time currency conversion matters to you.
- **No built-in TLS** — front with Caddy or nginx for HTTPS if exposing beyond localhost. Wrap with basic auth if you don't enable the built-in optional auth.
- **SQLite** — no PostgreSQL or Redis needed. The entire database is in `./data`. Back this up regularly.
- **Upstream compose uses `build:` context** — the repo's `docker-compose.yml` builds from source. The compose above uses the prebuilt GHCR image instead (`ghcr.io/bscott/subtrackr:latest`), which is the recommended production approach.

## Links

- Upstream README: <https://github.com/bscott/subtrackr>
- Container registry: <https://github.com/bscott/subtrackr/pkgs/container/subtrackr>
- Fixer.io (currency API): <https://fixer.io>
