# Vanilla Cookbook

> Self-hosted recipe manager with a clean, uncluttered interface — smart ingredient parsing, unit conversion, recipe scaling, URL scraping from hundreds of sites, shopping list, cooking log, and optional LLM assist. Single-container Docker deployment with SQLite.

**Official URL:** https://github.com/jt196/vanilla-cookbook  
**Docs:** https://vanilla-cookbook.readthedocs.io

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker | Single container; SQLite; recommended |
| Any Linux VPS/VM | Docker Compose | Compose template provided in repo |
| Any Linux | Node.js (local) | Manual install; see upstream docs |

---

## Inputs to Collect

### Phase: Pre-Deploy
| Input | Description | Example |
|-------|-------------|---------|
| `ORIGIN` | Full URL where the app will be accessed — must match exactly to avoid CORS errors | `https://recipes.example.com` |
| `PUID` | Host user ID for file ownership (optional) | `1000` |
| `PGID` | Host group ID for file ownership (optional) | `1000` |

### Phase: Optional Features
| Input | Description | Example |
|-------|-------------|---------|
| `OPENAI_API_KEY` | OpenAI key for LLM assist (scrape assist, recipe tweak, translate, generate, semantic search) | `sk-...` |
| `ANTHROPIC_API_KEY` | Anthropic key for LLM assist | `sk-ant-...` |
| `GOOGLE_AI_API_KEY` | Google Gemini key for LLM assist | `AIza...` |
| `OLLAMA_BASE_URL` | Local Ollama endpoint for LLM assist | `http://ollama:11434` |
| OAuth config | GitHub/Google/OIDC provider credentials for SSO login | see docs |

---

## Software-Layer Concerns

### Quick Start
```bash
# Download templates
curl -o .env https://raw.githubusercontent.com/jt196/vanilla-cookbook/main/.env.template
curl -o docker-compose.yml https://raw.githubusercontent.com/jt196/vanilla-cookbook/main/docker-compose.yml.template

# Create data directories
mkdir -p ./db ./uploads

# Edit .env — set ORIGIN at minimum
# Then start
docker compose up -d
```

First run prompts for admin user setup in the browser.

### Data Directories
| Path (container / host mount) | Purpose |
|-------------------------------|---------|
| `./db` → `/app/db` | SQLite database + scheduled backups — **back this up** |
| `./uploads` → `/app/uploads` | Uploaded recipe images |

### Key Environment Variables
| Variable | Default | Description |
|----------|---------|-------------|
| `ORIGIN` | `http://localhost:3000` | Public URL — CORS will break if wrong |
| `PUID` | `1000` | Container run-as UID |
| `PGID` | `1000` | Container run-as GID |
| `BACKUP_CRON_SCHEDULE` | weekly (Sun 3am) | Cron for scheduled SQLite backups |
| `BACKUP_RETENTION_COUNT` | `6` | How many scheduled backups to keep |

### Ports
- Default: `3000` — proxy with Nginx/Caddy and terminate TLS

### Automated Backups
Built-in: weekly backups to `./db/scheduled-backup-YYYYMMDD-HHMMSS.sqlite`; pre-migration backups also created automatically. Adjust schedule via `BACKUP_CRON_SCHEDULE`.

### LLM Features
Add any one LLM API key to unlock: scrape assist (parse HTML when Schema.org is absent), recipe tweaking/summarising, translation, recipe generation from prompt, image analysis, and semantic search. Ollama is supported for fully local inference.

---

## Upgrade Procedure

1. Check `.env.template` and `docker-compose.yml.template` in the repo for any new fields — add them to your `.env`
2. Pull latest: `docker pull jt196/vanilla-cookbook` (`:latest` = bleeding edge, `:stable` = stable release)
3. Stop: `docker compose down`
4. Start: `docker compose up -d` — pre-migration backup is created automatically before schema changes
5. If permission errors appear in logs (non-root migration): `sudo chown -R ${PUID:-1000}:${PGID:-1000} ./db ./uploads`

---

## Gotchas

- **ORIGIN must match exactly** — if you access the app via a different URL than `ORIGIN`, you'll get CORS/login errors; include the protocol and port if non-standard
- **Non-root migration** — older installs wrote files as root; after upgrading to a version that runs as a non-root user, you may need a one-time `chown` on `./db` and `./uploads` (see upgrade procedure)
- **`:latest` vs `:stable`** — `:latest` tracks main branch (may be unstable); use `:stable` for production
- **LLM semantic search** — requires an LLM API key; searches by meaning, not just keyword matching
- **Recipe scraping** — hundreds of sites supported via bookmarklet or URL paste; sites that change their HTML structure may break until updated
- **OAuth setup** — GitHub, Google, and any OIDC provider (Authentik, Keycloak) are supported; configure in `.env` before first run

---

## Links
- GitHub: https://github.com/jt196/vanilla-cookbook
- Docs: https://vanilla-cookbook.readthedocs.io
- .env template: https://raw.githubusercontent.com/jt196/vanilla-cookbook/main/.env.template
