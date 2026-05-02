# Ziit

**What it is:** A self-hosted, open-source alternative to WakaTime for tracking coding time. Captures project, language, editor, file, branch, and OS data via IDE extensions and displays it in a clean Plausible-inspired dashboard.

**Official URL:** https://github.com/0PandaDEV/Ziit
**Docs:** https://docs.ziit.app
**License:** GPL-3.0
**Stack:** Next.js + TimescaleDB (PostgreSQL extension)

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS / bare metal | Docker Compose | Recommended; TimescaleDB required |
| Homelab | Docker Compose | arm64 supported |

---

## Inputs to Collect

### Pre-deployment
- `DATABASE_URL` — TimescaleDB/PostgreSQL connection string
- `NEXTAUTH_SECRET` — random string (`openssl rand -hex 32`)
- `NEXTAUTH_URL` — public URL of the instance (e.g. `https://ziit.example.com`)
- GitHub OAuth app credentials (`GITHUB_CLIENT_ID`, `GITHUB_CLIENT_SECRET`) — if enabling GitHub login
- SMTP settings — for email/password login option

### Runtime
- API key generated per-user after login — used by IDE extensions

---

## Software-Layer Concerns

**Config:** All via `.env` file based on `.env.example`.

**Database:** TimescaleDB (a PostgreSQL extension optimized for time-series data). Must use TimescaleDB, not plain PostgreSQL — the schema relies on time-series hypertables.

**Default port:** `3000`

**IDE extensions supported:**
- VS Code (and all forks like Cursor, Windsurf)
- JetBrains IDEs

**Data import:** Can import from WakaTime or WakAPI exports.

**Public features:** Optional public stats page and coding leaderboard viewable without login.

**Upgrade procedure:**
1. `docker compose pull`
2. `docker compose up -d`
3. Run database migrations if noted in release: `docker compose exec app bunx prisma migrate deploy`

---

## Docker Compose (Quick Start)

Follow the deploy guide at https://docs.ziit.app/deploy — it covers Docker Compose with TimescaleDB.

Core environment variables in `.env`:
```
DATABASE_URL=postgresql://ziit:password@db:5432/ziit
NEXTAUTH_SECRET=<random>
NEXTAUTH_URL=https://ziit.example.com
```

---

## Gotchas

- **TimescaleDB is mandatory** — plain PostgreSQL will fail; use `timescale/timescaledb` Docker image
- **⚠️ Account deletion note:** Self-hosted accounts are separate from ziit.app cloud; see [issue #81](https://github.com/0pandadev/Ziit/issues/81) for context about the public instance
- **API key required in IDE** — generate from user settings after first login
- **GitHub OAuth optional** — email/password login also available
- Active project; check release notes before upgrading

---

## Links
- GitHub: https://github.com/0PandaDEV/Ziit
- Docs: https://docs.ziit.app
- Public instance: https://ziit.app
