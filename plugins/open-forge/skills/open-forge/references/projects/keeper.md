---
name: Keeper
description: "Self-hosted unified calendar aggregator with MCP server. Docker. TypeScript/Node.js + PostgreSQL. ridafkih/keeper.sh. Sync Google/Outlook/iCloud/CalDAV/Fastmail calendars into one view, AI agent access via MCP OAuth 2.1, encrypted credentials. MIT."
---

# Keeper

**Self-hosted unified calendar aggregator.** Connect Google Calendar, Outlook, iCloud, CalDAV, Fastmail, and more — view all your calendars in one place without giving third parties access. Stores calendar data locally in PostgreSQL with encrypted credentials. Includes an MCP (Model Context Protocol) server for AI agent access to your calendar data via OAuth 2.1.

Built + maintained by **ridafkih (Rida F'kih)**. MIT license.

- Upstream repo: <https://github.com/ridafkih/keeper.sh>
- Docker Hub: check GHCR (`ghcr.io/ridafkih/keeper`) for images
- MCP: `https://your-keeper/mcp`

## Architecture in one minute

- **TypeScript / Node.js** monorepo (Turborepo)
- **PostgreSQL** database (Drizzle ORM)
- Services: `api` + `web` + `cron` + optional `mcp`
- Convenience images: `keeper-standalone` (all-in-one) or `keeper-services` (separate)
- Cron worker syncs calendar events on schedule
- Port: configured per service in compose
- Resource: **low-medium** — Node.js + PostgreSQL

## Compatible install methods

| Infra              | Runtime                     | Notes                                                   |
| ------------------ | --------------------------- | ------------------------------------------------------- |
| **Docker Compose** | `keeper-standalone`         | **Easiest** — all-in-one image; see repo compose        |
| **Docker Compose** | `keeper-services` + `web`   | Separate containers; more control                       |

Full install: see README + `docker-compose.yml` in the repo.

## Inputs to collect

| Input | Example | Phase | Notes |
|-------|---------|-------|-------|
| `DATABASE_URL` | `postgresql://...` | DB | PostgreSQL connection string |
| `BETTER_AUTH_SECRET` | random string | Auth | Session signing secret |
| `BETTER_AUTH_URL` | `https://keeper.example.com` | Auth | Public URL |
| OAuth credentials | Google/Microsoft OAuth app | Calendars | Required per calendar provider you want to connect |
| iCloud credentials | Apple ID + app-specific password | Calendars | For iCloud Calendar sync |

## Calendar providers supported

| Provider | Auth method |
|----------|------------|
| Google Calendar | OAuth 2.0 |
| Microsoft Outlook | OAuth 2.0 |
| iCloud Calendar | App-specific password + DAV |
| CalDAV (any) | Username + password |
| Fastmail | CalDAV (built-in integration) |

## MCP server (AI agent integration)

Keeper includes an **optional MCP server** (separate `keeper-mcp` container) exposing:

| Tool | Description |
|------|-------------|
| `list_calendars` | List all connected calendars |
| `get_events` | Get events within a date range (ISO 8601 datetimes + IANA timezone) |
| `get_event_count` | Total number of synced events |

MCP uses **OAuth 2.1** with a consent flow — AI agents (Claude, etc.) authorize via browser before accessing your calendar.

**Claude Desktop / Claude Code MCP config:**
```json
{
  "mcpServers": {
    "keeper": {
      "type": "url",
      "url": "https://keeper.example.com/mcp"
    }
  }
}
```

MCP is fully optional — not setting MCP environment variables skips it entirely.

## Install via Docker Compose

```bash
git clone https://github.com/ridafkih/keeper.sh.git
cd keeper.sh
# Copy .env.example → .env; configure DB + auth secrets + OAuth credentials
cp .env.example .env
docker compose up -d
```

## First boot

1. Configure `.env` with DB credentials, auth secret, and public URL.
2. Set up OAuth apps in Google Cloud Console and/or Azure AD for calendar providers.
3. `docker compose up -d`.
4. Visit the web UI → sign in.
5. Connect calendars (Google/Outlook/iCloud/CalDAV).
6. Wait for the cron worker to sync events.
7. (Optional) Enable MCP for AI agent access.
8. Put behind TLS.

## Gotchas

- **OAuth app setup is required for Google/Outlook.** You must create OAuth 2.0 apps in Google Cloud Console (for Google Calendar) and Azure AD (for Outlook/Microsoft 365) with the correct redirect URIs pointing to your Keeper instance.
- **iCloud uses app-specific passwords.** Don't use your main Apple ID password. Create an app-specific password at appleid.apple.com.
- **MCP is not in standalone/services images.** The `keeper-mcp` image is separate — add it to your compose file explicitly if you want MCP. The README provides the env vars needed.
- **Cron worker syncs on schedule.** Calendar events are fetched by the cron container periodically, not in real-time. New events appear after the next sync cycle.
- **Encrypted credentials storage.** Calendar provider credentials (OAuth tokens, passwords) are stored encrypted in PostgreSQL using `BETTER_AUTH_SECRET`. Don't lose this secret — you'll need to re-connect all calendars if it changes.

## Backup

```sh
docker compose exec postgres pg_dump -U keeper keeper > keeper-$(date +%F).sql
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Project health

Active TypeScript/Node.js monorepo, MCP server with OAuth 2.1, Google/Outlook/iCloud/CalDAV/Fastmail providers, Turborepo, Drizzle ORM. Solo-maintained by ridafkih. MIT license.

## Calendar-aggregator-family comparison

- **Keeper** — TypeScript, multi-provider sync, MCP/AI agent access, encrypted credentials, MIT
- **Radicale** — Python, CalDAV/CardDAV server; not an aggregator
- **DAVx⁵** — Android CalDAV/CardDAV client; phone-only; not a server
- **Nextcloud Calendar** — PHP CalDAV server; can federate but not aggregate external providers
- **Fantastical** — SaaS, multi-provider calendar view; not self-hosted

**Choose Keeper if:** you want a self-hosted calendar aggregator that syncs Google/Outlook/iCloud/CalDAV calendars into one encrypted local view, with MCP server support for AI agents.

## Links

- Repo: <https://github.com/ridafkih/keeper.sh>
- MCP setup: see README MCP section
