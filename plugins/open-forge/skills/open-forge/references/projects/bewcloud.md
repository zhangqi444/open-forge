---
name: bewCloud
description: "Self-hosted cloud storage with CalDAV/CardDAV and desktop/mobile sync. Docker. Deno + PostgreSQL + Radicale. bewcloud/bewcloud. Files, photos, notes, contacts, calendars, desktop sync app, mobile app."
---

# bewCloud

**Self-hosted cloud storage combining file hosting, CalDAV/CardDAV, and desktop/mobile sync.** Upload and manage files and photos through a web UI; sync with the bewCloud desktop app (Windows/macOS/Linux) and mobile app (iOS/Android); manage contacts and calendars via Radicale (CardDAV/CalDAV). A privacy-first alternative to Dropbox + Google Contacts + Google Calendar.

Built + maintained by **bewCloud team**. MIT license.

- Upstream repo: <https://github.com/bewcloud/bewcloud>
- Website: <https://bewcloud.com>
- Desktop app: <https://github.com/bewcloud/bewcloud-desktop>
- Mobile app: <https://github.com/bewcloud/bewcloud-mobile>
- GHCR: `ghcr.io/bewcloud/bewcloud`

## Architecture in one minute

- **Deno** backend (TypeScript runtime) + web UI
- **PostgreSQL 18** database (Prisma-managed)
- **Radicale** (CardDAV/CalDAV server) — for contacts and calendars
- Docker Compose: `website` + `postgresql` + `radicale` containers
- Port **8000** (bound to `127.0.0.1` by default — reverse proxy expected)
- Files stored in `./data-files/` volume
- Config: `bewcloud.config.ts` (TypeScript config file)
- Resource: **low** — Deno + PostgreSQL (256 MB mem limits per service)

## Compatible install methods

| Infra              | Runtime                         | Notes                                              |
| ------------------ | ------------------------------- | -------------------------------------------------- |
| **Docker Compose** | `ghcr.io/bewcloud/bewcloud`     | **Primary** — GHCR; pin to version tag             |

## Inputs to collect

| Input                      | Example                          | Phase   | Notes                                                             |
| -------------------------- | -------------------------------- | ------- | ----------------------------------------------------------------- |
| `.env` file                | from `.env.sample`               | Config  | DB credentials, secrets, SMTP, base URL                          |
| `bewcloud.config.ts`       | from `bewcloud.config.sample.ts` | Config  | App settings (auth, storage quotas, features)                    |
| `radicale-config/config`   | from sample                      | CalDAV  | Radicale server config; only if using CalDAV/CardDAV             |
| DB password                | strong random                    | DB      | Set in `.env` + docker-compose                                   |
| Base URL                   | `https://cloud.example.com`      | Network | Set in `.env`                                                     |

## Install via Docker Compose

```bash
# Create data directories
mkdir -p data-files data-radicale radicale-config

# Download config files
curl -O https://raw.githubusercontent.com/bewcloud/bewcloud/main/docker-compose.yml
curl -o .env https://raw.githubusercontent.com/bewcloud/bewcloud/main/.env.sample
curl -o bewcloud.config.ts https://raw.githubusercontent.com/bewcloud/bewcloud/main/bewcloud.config.sample.ts
curl -o radicale-config/config https://raw.githubusercontent.com/bewcloud/bewcloud/main/radicale-config/config

# Edit .env and bewcloud.config.ts with your settings

# Start containers
docker compose up -d

# Run DB migrations (required on first run and after updates)
docker compose run --rm website bash -c "cd /app && make migrate-db"
```

Visit `http://localhost:8000` (or via reverse proxy).

## .env key settings

| Variable | Notes |
|----------|-------|
| `APP_URL` | Your public base URL |
| `POSTGRES_USER` / `POSTGRES_PASSWORD` / `POSTGRES_DB` | DB credentials |
| `SESSION_SECRET` | Random secret for session signing |
| `SMTP_*` | Email settings for password reset / notifications |

## bewcloud.config.ts key settings

```typescript
export const config = {
  auth: {
    allowSignups: false,   // disable public registration; first signup = admin
  },
  storage: {
    maxQuota: 10 * 1024 * 1024 * 1024,  // 10 GB per user
  },
  // ...
};
```

## First boot

1. Edit `.env` (URL, DB creds, session secret, SMTP).
2. Edit `bewcloud.config.ts` (registration on/off, quotas).
3. `docker compose up -d`.
4. Run DB migrations: `docker compose run --rm website bash -c "cd /app && make migrate-db"`.
5. Visit your instance → **first signup = admin** (even with signups disabled).
6. Change admin password.
7. Disable signups in `bewcloud.config.ts` + restart if not using public registration.
8. Install **desktop sync app** from [bewcloud-desktop](https://github.com/bewcloud/bewcloud-desktop).
9. Install **mobile app** from [bewcloud-mobile](https://github.com/bewcloud/bewcloud-mobile).
10. Configure CalDAV/CardDAV client using the Radicale endpoint.
11. Put behind TLS.

## Features overview

| Feature | Details |
|---------|---------|
| File storage | Upload, download, organize files in folders |
| Photo gallery | View uploaded images in a gallery layout |
| Notes | Simple note-taking |
| Contacts | CardDAV via Radicale; sync with phone/desktop clients |
| Calendars | CalDAV via Radicale; sync with calendar clients |
| Desktop sync | Windows/macOS/Linux sync app (bewcloud-desktop) |
| Mobile app | iOS/Android app (bewcloud-mobile) |
| User management | Admin can create/manage users |
| Storage quotas | Configurable per-user storage limits |
| 256 MB mem limits | Lean resource footprint per container |

## CalDAV/CardDAV endpoints

- CalDAV: `https://your-cloud.example.com/dav/calendars/<username>/`
- CardDAV: `https://your-cloud.example.com/dav/contacts/<username>/`

Use these in any standard CalDAV/CardDAV client (Apple Calendar/Contacts, Thunderbird, DAVx⁵ on Android, etc.).

## Gotchas

- **`make migrate-db` is mandatory** on first run and after every update. Without it, the database schema doesn't exist and the app won't work. Don't skip it.
- **First signup = admin even with signups disabled.** The README explicitly notes this. On a fresh install, `allowSignups: false` still allows the first account to be created and it becomes admin. This is intentional for bootstrapping.
- **Port bound to `127.0.0.1` by default.** The compose file uses `127.0.0.1:8000:8000` — not `0.0.0.0`. This is intentional (reverse proxy expected). Don't change to `0.0.0.0` without TLS in front.
- **Pin to a version tag.** The compose file example pins to a specific GHCR tag (e.g. `v4.4.0`). Don't use `:latest` in production — check the releases page and update the tag deliberately.
- **File permissions.** If you run into permission issues, `sudo chown -R 1993:1993 data-files` — Deno's Docker image uses UID 1993 by default.
- **Radicale is optional.** If you don't need CalDAV/CardDAV, you can remove the `radicale` service from the compose file. File storage + sync works without it.
- **256 MB mem limits.** The compose file sets `mem_limit: 256m` on all services. This is sufficient for personal use but may need increasing for many users or large file operations.
- **Deno runtime.** Deno is a secure JavaScript/TypeScript runtime (alternative to Node.js). No `node_modules` — dependencies are fetched as URLs. This is a different mental model if you're used to Node.

## Backup

```sh
docker compose stop
docker compose exec postgresql pg_dump -U postgres bewcloud > bewcloud-$(date +%F).sql
sudo tar czf bewcloud-files-$(date +%F).tgz data-files/ data-radicale/
docker compose start
```

## Upgrade

1. Update the image tag in `docker-compose.yml` to the new version.
2. `docker compose pull && docker compose up -d`.
3. Run migrations: `docker compose run --rm website bash -c "cd /app && make migrate-db"`.

## Project health

Active Deno development, GHCR, desktop app (Windows/macOS/Linux), mobile app (iOS/Android), CalDAV/CardDAV, NLnet Foundation funded. bewCloud team. MIT license.

## Self-hosted-cloud-family comparison

- **bewCloud** — Deno, files + CalDAV/CardDAV, desktop + mobile sync apps, lean (256 MB), MIT
- **Nextcloud** — PHP, massive ecosystem, everything + kitchen sink, heavier
- **ownCloud** — PHP, files focus, lighter than Nextcloud
- **Seafile** — C, very fast file sync, no CalDAV/CardDAV built-in
- **Vikunja** — tasks focus; not file storage

**Choose bewCloud if:** you want a lightweight self-hosted cloud combining file storage, CalDAV/CardDAV, and desktop/mobile sync — without the weight of Nextcloud.

## Links

- Repo: <https://github.com/bewcloud/bewcloud>
- Website: <https://bewcloud.com>
- Desktop app: <https://github.com/bewcloud/bewcloud-desktop>
- Mobile app: <https://github.com/bewcloud/bewcloud-mobile>
