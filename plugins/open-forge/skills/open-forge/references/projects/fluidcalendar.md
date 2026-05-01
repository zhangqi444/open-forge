---
name: FluidCalendar
description: "Self-hosted smart calendar app with AI-powered task scheduling. Docker. Next.js + PostgreSQL. dotnetfactory/fluid-calendar. Google Calendar sync, Microsoft Outlook/Tasks sync, drag-and-drop, time blocking, auto-scheduling. MIT."
---

# FluidCalendar

**Self-hosted smart calendar with AI-powered task scheduling.** FluidCalendar syncs with Google Calendar and Microsoft Outlook/Tasks, lets you drag-and-drop events, time-block your schedule, and uses AI to automatically slot tasks into available time. Clean Next.js UI backed by PostgreSQL.

Built + maintained by **dotnetfactory**. MIT license.

- Upstream repo: <https://github.com/dotnetfactory/fluid-calendar>
- Docker Hub: `eibrahim/fluid-calendar`

## Architecture in one minute

- **Next.js 15** with App Router (full-stack — API routes + UI in one container)
- **PostgreSQL** — all data (events, tasks, settings)
- **Prisma** — database ORM
- **NextAuth.js** — authentication (Google OAuth and/or Microsoft OAuth)
- Port **3000**
- Resource: **low-medium** — Node.js + Postgres

## Compatible install methods

| Infra      | Runtime                       | Notes                                          |
| ---------- | ----------------------------- | ---------------------------------------------- |
| **Docker** | `eibrahim/fluid-calendar`     | **Primary** — single container + Postgres      |

## Install via Docker

```yaml
services:
  app:
    image: eibrahim/fluid-calendar:latest
    ports:
      - "3000:3000"
    env_file:
      - .env
    depends_on:
      db:
        condition: service_healthy
    restart: unless-stopped

  db:
    image: postgres:16-alpine
    environment:
      - POSTGRES_USER=fluid
      - POSTGRES_PASSWORD=changeme
      - POSTGRES_DB=fluid_calendar
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U fluid -d fluid_calendar"]
      interval: 5s
      timeout: 5s
      retries: 5
    restart: unless-stopped

volumes:
  postgres_data:
```

## `.env` file

```env
DATABASE_URL=postgresql://fluid:changeme@db:5432/fluid_calendar
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=your-random-secret-here

# Google Calendar / OAuth (optional — configure in Settings > System if not set here)
# GOOGLE_CLIENT_ID=
# GOOGLE_CLIENT_SECRET=

# Microsoft / Azure AD OAuth (optional)
# AZURE_AD_CLIENT_ID=
# AZURE_AD_CLIENT_SECRET=
# AZURE_AD_TENANT_ID=
```

Generate `NEXTAUTH_SECRET`:
```sh
openssl rand -base64 32
```

Visit `http://localhost:3000` after startup.

## Environment variables

| Variable | Required | Notes |
|----------|----------|-------|
| `DATABASE_URL` | ✅ | PostgreSQL connection string |
| `NEXTAUTH_URL` | ✅ | Full public URL of your instance |
| `NEXTAUTH_SECRET` | ✅ | Random string for session encryption |
| `GOOGLE_CLIENT_ID` | Optional | For Google Calendar OAuth |
| `GOOGLE_CLIENT_SECRET` | Optional | For Google Calendar OAuth |
| `AZURE_AD_CLIENT_ID` | Optional | For Microsoft Outlook/Tasks OAuth |
| `AZURE_AD_CLIENT_SECRET` | Optional | For Microsoft Outlook/Tasks OAuth |
| `AZURE_AD_TENANT_ID` | Optional | For Microsoft OAuth |

> Google and Microsoft credentials can also be configured through the UI in **Settings → System**. Environment variables serve as fallback.

## Google Calendar OAuth setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/) → **APIs & Services → Credentials**
2. Create **OAuth 2.0 Client ID** (Web application)
3. Add authorized JavaScript origins: `https://your-domain.com`
4. Add authorized redirect URIs: `https://your-domain.com/api/auth/callback/google`
5. Required scopes: `calendar.events`, `calendar`, `userinfo.email`
6. Add credentials to `.env` or Settings → System

## Microsoft (Outlook/Tasks) OAuth setup

1. Register app in [Azure Portal](https://portal.azure.com/) → **App registrations**
2. Add redirect URI: `https://your-domain.com/api/auth/callback/azure-ad`
3. Add credentials to `.env` or Settings → System

## Features overview

| Feature | Details |
|---------|---------|
| Google Calendar sync | Two-way sync with Google Calendar |
| Microsoft Outlook sync | Sync Outlook calendar events |
| Microsoft Tasks sync | Import and schedule Microsoft To-Do/Tasks |
| Drag-and-drop scheduling | Move events and tasks visually on the calendar |
| Time blocking | Block time on the calendar for focused work |
| AI task scheduling | Auto-schedule tasks into available time slots |
| Task management | Create, edit, and prioritise tasks |
| Multi-calendar view | Overlay multiple calendars in one view |
| Next.js App Router | Modern React full-stack architecture |
| Prisma + PostgreSQL | Reliable relational storage with type-safe ORM |
| NextAuth.js | OAuth-based authentication (Google, Microsoft) |

## Gotchas

- **Google OAuth requires a Consent Screen.** Before users can connect Google Calendar, you must publish the OAuth consent screen in Google Cloud Console. During development, add test users to bypass the review requirement.
- **Redirect URIs must match exactly.** OAuth callback URIs must match exactly between the provider console and your instance URL — including protocol (http vs https) and port.
- **`NEXTAUTH_URL` must be accurate.** Set this to the exact public URL (with protocol) that users reach your instance at. Mismatches break OAuth callbacks.
- **MIT license.** Free to use, modify, redistribute.

## Backup

```sh
docker compose exec db pg_dump -U fluid fluid_calendar > fluidcalendar-$(date +%F).sql
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Project health

Active Next.js 15 development, Google + Microsoft integration, AI scheduling, MIT license.

## Calendar-family comparison

- **FluidCalendar** — Next.js/Postgres, Google+Outlook sync, AI task scheduling, time blocking, MIT
- **Cal.com** — Next.js/Postgres, scheduling/booking links, team availability; broader use case; AGPL-3.0
- **Nextcloud Calendar** — PHP, DAV-based, Nextcloud ecosystem; no AI scheduling
- **Radicale** — Python, CalDAV/CardDAV server only; no UI; GPL-3.0

**Choose FluidCalendar if:** you want a self-hosted smart calendar with Google and Outlook sync, AI-powered task scheduling, and time blocking in a clean Next.js app.

## Links

- Repo: <https://github.com/dotnetfactory/fluid-calendar>
- Docker Hub: <https://hub.docker.com/r/eibrahim/fluid-calendar>
