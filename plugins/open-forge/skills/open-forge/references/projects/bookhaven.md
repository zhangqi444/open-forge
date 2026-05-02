# BookHaven

**What it is:** A self-hosted browser-based EPUB reader and library manager. Point it at your local EPUB collection and it scans, indexes, and serves your books with a clean web UI. Read in the browser, download to any device, edit metadata non-destructively, use OPDS with your e-reader app, and share with family via role-based access.

**Official URL:** https://github.com/HrBingR/BookHaven
**License:** MIT
**Stack:** Python/FastAPI + SQLite/MySQL/PostgreSQL + Redis

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS / bare metal | Docker Compose | Recommended; includes Redis sidecar |
| Homelab (NAS, Pi) | Docker Compose | Lightweight; SQLite works for personal use |

---

## Inputs to Collect

### Pre-deployment (`.env` file)
- `BASE_DIRECTORY` — path inside container where EPUBs are mounted (e.g. `/ebooks`)
- `BASE_URL` — public URL with protocol (e.g. `https://books.example.com`)
- `SECRET_KEY` — JWT signing secret (`openssl rand -hex 32`)
- `ADMIN_EMAIL` + `ADMIN_PASS` — initial admin credentials (can be removed from `.env` after first startup)
- Database: SQLite (default), MySQL, or PostgreSQL — configure via `DB_*` env vars
- Redis connection URL (required; provided by compose sidecar by default)

### Optional
- `WRITE_TO_EPUB=true` — write metadata changes back to EPUB files (⚠️ irreversible)
- `OPDS_ENABLED=true` — enable OPDS endpoint for e-reader apps
- `UI_BASE_COLOR` — `green` (default), `blue`, `red`, `yellow`, `white`, `black`, `pink`, `purple`, `orange`, `cyan`
- OIDC settings — for SSO/federated login
- CloudFlare Access flag — bypasses login screen when behind CF Access

---

## Software-Layer Concerns

**Docker Compose quick start:**
```bash
git clone https://github.com/HrBingR/BookHaven.git
cd BookHaven
cp compose.yml.example compose.yml
cp .env.example .env
# Edit .env with your settings
docker compose up -d
```

**Volume mount:** Mount your EPUB directory to match `BASE_DIRECTORY`:
```yaml
volumes:
  - /path/to/your/ebooks:/ebooks
```

**Library scanning:** Auto-scans on a configurable interval; manual scan available from the UI anytime.

**OPDS:** Enable with `OPDS_ENABLED=true`. Uses basic auth — HTTP-only OPDS is insecure; HTTPS strongly recommended. Does not work with OIDC accounts or MFA.

**Metadata editing:** Changes are stored in the database by default, leaving EPUB files untouched. Set `WRITE_TO_EPUB=true` to also update the EPUB itself — note this is one-way and irreversible, and requires an existing cover image to replace covers.

**Roles:** Admin, Editor, User — configurable per-account. Book requests feature lets users request titles; admins/editors resolve them.

**Upgrade procedure:**
1. `docker compose pull`
2. `docker compose up -d`
3. Migrations run automatically on startup

---

## Gotchas

- **EPUB only** — does not support PDF, MOBI, CBZ, or other formats
- **Redis required** — even for single-user SQLite installs; the compose example includes it
- **`ADMIN_EMAIL`/`ADMIN_PASS` are first-run only** — remove from `.env` after initial startup; `ADMIN_RESET=true` is a last-resort recovery option
- **`WRITE_TO_EPUB` is irreversible** — metadata changes written to EPUB cannot be undone; test without it first
- **OPDS + MFA incompatible** — OPDS uses basic auth; MFA-enabled accounts can't use OPDS
- **CloudFlare Access bypass** — only enable if you're already protected by CF Access; this removes the built-in login page entirely

---

## Links
- GitHub: https://github.com/HrBingR/BookHaven
- `.env.example`: https://github.com/HrBingR/BookHaven/blob/main/.env.example
