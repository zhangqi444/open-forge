# Meerkat CRM

**What it is:** A self-hosted personal CRM (Contact Relationship Management) system for managing your social life — birthdays, relationships, reminders, and a timeline of interactions with the people you care about.

**Official URL:** https://github.com/fbuchner/meerkat-crm
**Docs:** https://fbuchner.github.io/meerkat-crm/
**License:** MIT
**Stack:** Go (backend) + React (frontend) + SQLite

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS / bare metal | Docker Compose | Recommended method |
| Any Linux VPS / bare metal | Binary (Go) | Manual build from source |
| Homelab (Pi, NAS) | Docker Compose | Works on arm64 |

---

## Inputs to Collect

### Pre-deployment
- `SECRET_KEY` — random string for session signing (generate with `openssl rand -hex 32`)
- `ADMIN_USER` / `ADMIN_PASSWORD` — initial admin credentials
- `SMTP_*` settings — optional, for e-mail reminder notifications
- Domain/reverse-proxy hostname if exposing publicly

### Runtime
- CardDAV credentials — Meerkat exposes a CardDAV server for phone contact sync
- Contact circles configuration (friends, family, work, etc.)

---

## Software-Layer Concerns

**Config:** Via `.env.docker` file (copy from `.env.docker.example`). All settings passed as environment variables to the container.

**Data directory:** SQLite database and uploaded files stored in the mounted volume. Default: `./data:/app/data`.

**Default port:** `7300` (HTTP)

**CardDAV:** Built-in CardDAV server runs on the same port. Useful for two-way sync with iOS/Android contacts apps.

**Upgrade procedure:**
1. `docker compose pull`
2. `docker compose up -d`
3. Check release notes at https://github.com/fbuchner/meerkat-crm/releases for any migration steps

---

## Docker Compose (Quick Start)

```bash
curl -O https://raw.githubusercontent.com/fbuchner/meerkat-crm/main/docker-compose.yml
curl -O https://raw.githubusercontent.com/fbuchner/meerkat-crm/main/.env.docker.example
cp .env.docker.example .env.docker
# Edit .env.docker with your settings
docker compose --env-file .env.docker up -d
```

Access at `http://localhost:7300`.

---

## Gotchas

- **Email reminders require SMTP config** — if not set, reminder notifications are silently skipped
- **CardDAV sync needs correct server URL** — typically `http://<host>:7300/carddav/<username>/`
- **SQLite only** — no Postgres/MySQL option; back up the `data/` volume regularly
- **Multi-user support is limited** — designed primarily as a single-user personal tool
- Active development; check releases for breaking changes before upgrading

---

## Links
- GitHub: https://github.com/fbuchner/meerkat-crm
- Docs: https://fbuchner.github.io/meerkat-crm/
- Live Demo: https://meerkat-crm-demo.fly.dev/login?username=demo&password=test_12345
