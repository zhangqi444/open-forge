# Dribdat

> Self-hosted hackathon platform for data-driven civic tech sprints. Manages the full event lifecycle: publishing challenges, forming teams, tracking project progress, and showcasing results. Integrates with Git, Forgejo, Etherpad, Slack, Discord, and Mattermost. Alternative Vue.js frontend (Backboard) available. MIT-licensed.

**Official URL:** https://dribdat.cc  
**Docs:** https://docs.dribdat.cc  
**GitHub:** https://github.com/dribdat/dribdat  
**Demo:** https://demo.dribdat.cc

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker Compose (SQLite) | Quickest start; SQLite included |
| Any Linux VPS/VM | Docker Compose (PostgreSQL) | Recommended for production events |
| Any Python-capable host | Python / Ansible | See upstream deployment guide |

---

## Inputs to Collect

### Phase: Pre-Deploy
| Input | Description | Example |
|-------|-------------|---------|
| Database | SQLite (simple) or PostgreSQL (production) | `sqlite` |
| `SECRET_KEY` | Flask secret key — generate randomly | `openssl rand -hex 32` |
| Admin email + password | First admin user credentials | — |
| `SERVER_URL` | Public URL where dribdat will be hosted | `https://hack.example.com` |

### Phase: Integrations (optional)
| Input | Description |
|-------|-------------|
| Slack webhook | For project update notifications |
| Discord webhook | Alternative to Slack |
| Mattermost webhook | Alternative to Slack |
| OAuth provider | For SSO (GitHub, Gitlab, Azure, etc.) |

---

## Software-Layer Concerns

### Quick Start (Docker Compose — SQLite)
```bash
git clone https://github.com/dribdat/dribdat.git
cd dribdat
docker-compose -f docker-compose.sqlite.yml up -d
```

Access at http://localhost:5000 — the first registered user becomes admin.

### Production (Docker Compose — PostgreSQL)
```bash
cp .env.example .env
# Edit .env — set SECRET_KEY, DATABASE_URL (postgres://...), SERVER_URL
docker-compose up -d
```

Upstream deploy guide: https://docs.dribdat.cc/deploy

### Data Aggregation
Dribdat can auto-sync project content from external sources. Supported: GitHub/Gitlab READMEs, Forgejo, Etherpad, HackMD, and more. Configure in **Admin → Projects** or per-project settings.

### Alternative Frontend (Backboard)
Backboard is a Vue.js SPA that consumes the dribdat API for a more modern look:
- Repo: https://github.com/dribdat/backboard
- Deploy separately and point it at the dribdat API endpoint

### Data Directories
| Path (container) | Purpose |
|------------------|---------|
| `/app/dribdat.db` | SQLite database (SQLite mode only) |
| PostgreSQL volume | All data (PostgreSQL mode) |

### Ports
- Default: `5000` — reverse-proxy with Nginx/Caddy for TLS

### Environment Variables (key ones)
| Variable | Purpose |
|----------|---------|
| `SECRET_KEY` | Flask session secret — required |
| `DATABASE_URL` | PostgreSQL connection string (if not SQLite) |
| `SERVER_URL` | Canonical public URL |
| `DRIBDAT_ALLOW_REGISTER` | `true` to allow open registration |
| `SLACK_WEBHOOK_URL` | Slack integration |

---

## Upgrade Procedure

1. Pull latest: `git pull && docker-compose pull`
2. Restart: `docker-compose down && docker-compose up -d`
3. Database migrations run automatically on startup
4. Review https://github.com/dribdat/dribdat/releases for breaking changes

---

## Gotchas

- **First registered user is admin** — register the admin account immediately after deploy before sharing the URL publicly; or disable open registration (`DRIBDAT_ALLOW_REGISTER=false`) until ready
- **SQLite is fine for single events** — for high-concurrency events or production use, switch to PostgreSQL; SQLite writes can bottleneck under load
- **Data aggregation requires reachability** — dribdat's server must be able to reach the external sources (GitHub, Forgejo, etc.) for auto-sync to work; firewall outbound rules accordingly
- **`SECRET_KEY` must be stable** — changing it invalidates all existing sessions; set it once in `.env` and keep it
- **S3 upload (optional) depends on OpenSSL via awscrt** — if using the boto3/S3 upload feature, the instance must have a compatible OpenSSL version; see the license note in the upstream README about cryptographic software

---

## Links
- Docs: https://docs.dribdat.cc
- Deploy guide: https://docs.dribdat.cc/deploy
- GitHub: https://github.com/dribdat/dribdat
- Demo: https://demo.dribdat.cc
- Backboard (Vue.js frontend): https://github.com/dribdat/backboard
- Awesome Hackathon list: https://github.com/dribdat/awesome-hackathon
