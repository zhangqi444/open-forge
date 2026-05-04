---
name: omnivore
description: Omnivore recipe for open-forge. Complete open-source read-it-later solution with highlighting, notes, newsletter ingestion, PDF support, and mobile/browser clients.
---

# Omnivore

Complete, open-source read-it-later solution. Save articles, PDFs, and newsletters; add highlights and notes; search full text; sync across web, iOS, Android, and browser extensions.

> ℹ️ **Cloud deprecated:** Omnivore's hosted cloud was shut down in November 2024. The project is now fully self-hosted. Active community continues on Discord.

Upstream: <https://github.com/omnivore-app/omnivore>. Self-hosting guide: <https://github.com/omnivore-app/omnivore/blob/main/self-hosting/GUIDE.md>.

## Compatible install methods

| Method | When to use |
|---|---|
| Docker Compose (recommended) | Standard self-hosted deployment |

## Architecture

Multi-service application:
- **web** — Next.js frontend
- **api** — Node.js/TypeScript backend
- **workers** — background jobs (fetching, parsing)
- **content-fetch** — headless Chrome for article fetching
- **db** — PostgreSQL

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Domain for your Omnivore instance?" | Used in env vars for cross-service communication |
| preflight | "JWT secret?" | Random string for session signing |
| optional | "SMTP credentials?" | For newsletter email ingestion and account emails |

## Docker Compose example

Refer to the official self-hosting guide for the full compose file — it is multi-service and changes with releases:

```
https://github.com/omnivore-app/omnivore/blob/main/self-hosting/GUIDE.md
```

Key environment variables:

```env
BASE_URL=https://omnivore.example.com
SERVER_AUTH_JWT_SECRET=<random-secret>
PG_HOST=db
PG_USER=omnivore
PG_PASSWORD=changeme
PG_DB=omnivore
```

## Software-layer concerns

- PostgreSQL required; included in the compose stack
- `content-fetch` service runs a headless Chromium instance for full-page article fetching — resource-intensive; allocate at least 1 GB RAM for this container
- Newsletter ingestion: each Omnivore account gets a dedicated `@inbox.omnivore.app`-style address; requires SMTP/MX configuration on your domain
- Obsidian and Logseq plugins available for syncing highlights to your PKM
- Browser extensions: Chrome, Firefox, Safari, Edge

## Upgrade procedure

1. `docker compose pull`
2. `docker compose up -d`
3. Migrations run automatically at startup

## Gotchas

- **Cloud shutdown:** omnivore.app cloud is offline; you must self-host
- `content-fetch` (Chromium) is the heaviest service — plan memory accordingly
- Newsletter email ingestion requires DNS MX records pointing to your instance
- The iOS/Android apps can be configured to point at a self-hosted instance in Settings → Advanced

## Links

- GitHub: <https://github.com/omnivore-app/omnivore>
- Self-hosting guide: <https://github.com/omnivore-app/omnivore/blob/main/self-hosting/GUIDE.md>
- Web app: <https://omnivore.work/>
