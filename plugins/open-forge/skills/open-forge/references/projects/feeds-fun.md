# Feeds Fun

A self-hosted news reader with automatic tag assignment and AI-powered scoring. Subscribe to RSS/Atom feeds; the backend automatically assigns tags to every news entry using configurable processors (keyword rules, LLM-based via OpenAI or Gemini). You create scoring rules based on those tags to bubble up what matters and filter out noise. Multi-user or single-user. Built with Python (FastAPI) + PostgreSQL + Caddy.

- **Official site:** https://feeds.fun
- **GitHub:** https://github.com/Tiendil/feeds.fun
- **Backend image:** `tiendil/feeds-fun-backend:latest`
- **Frontend image:** `tiendil/feeds-fun-frontend:latest`
- **License:** Open-source

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Docker host | Docker Compose | Multi-container: backend-api + background workers + frontend + PostgreSQL + Caddy |
| Single-user | Docker Compose | Simplified config in docs/examples/single-user |
| Multi-user | Docker Compose | Config in docs/examples/multi-user; requires auth header setup |

---

## Inputs to Collect

### Deploy Phase (ffun.env file)
| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| FFUN_AUTH_FORCE_EXTERNAL_USER_ID | Single-user only | — | Set to any string (e.g. dev-user) to bypass auth for single-user mode |
| FFUN_AUTH_FORCE_EXTERNAL_IDENTITY_PROVIDER_ID | Single-user only | — | Set to single_user for single-user mode |
| POSTGRES_DB | No | ffun | PostgreSQL database name |
| POSTGRES_USER | No | ffun | PostgreSQL username |
| POSTGRES_PASSWORD | No | ffun | PostgreSQL password — change for production |

### Optional LLM integration (set in web UI settings, not env)
| Setting | Description |
|---------|-------------|
| OpenAI API key | For LLM-based automatic tag generation (best experience) |
| Gemini API key | Alternative to OpenAI for tag generation |

Tag processor config is in `tag_processors.toml` — tune prompts and enabled processors there.

---

## Software-Layer Concerns

### Architecture (Docker Compose stack)
- **postgres** — PostgreSQL database
- **backend-api** — FastAPI HTTP server (runs DB migrations on startup)
- **background workers** — Feed crawling, tag processing, scoring
- **frontend** — Static SPA served by Caddy
- **caddy** — Reverse proxy + HTTPS (bring your own domain for auto-HTTPS)

### Config
- `ffun.env` — backend env vars
- `tag_processors.toml` — tag processor configuration and LLM prompts

### Data Directories
- PostgreSQL named volume (persisted)
- Caddy data/config volumes for TLS

### Ports
- 80/443 — Caddy (HTTP/HTTPS)

---

## Quickstart (single-user)

```bash
git clone https://github.com/Tiendil/feeds.fun.git
cd feeds.fun/docs/examples/single-user
docker compose up -d
# Access at http://localhost/
```

No additional config required for local testing. Set an OpenAI or Gemini key in the web UI Settings to enable LLM tagging.

---

## Upgrade Procedure

```bash
docker compose pull
docker compose up -d
```

DB migrations run automatically on backend-api startup. Review CHANGELOG for breaking changes before upgrading. For production, pin to specific version tags (e.g. `tiendil/feeds-fun-backend:1.19.0`) instead of `latest`.

---

## Gotchas

- **Use :latest only for testing:** Pin to a specific version tag in production; automatic migrations work in most cases but rare upgrades may need manual steps
- **LLM keys improve tag quality dramatically:** Without an OpenAI or Gemini key, only simpler rule-based tag processors run; LLM-based tagging is what makes the reader truly useful
- **Tag processors.toml controls behavior:** Review and tune prompts in tag_processors.toml — the defaults mirror feeds.fun hosted service but you may want to customise them
- **Always use a reverse proxy for internet exposure:** Never expose the backend API directly; use Caddy (included) or nginx/Traefik in front
- **Multi-user requires auth header setup:** The multi-user example requires configuring an authentication proxy that sets a user ID header; see docs/examples/multi-user
- **Frontend build-time env vars:** VITE_FFUN_* variables must be set at image build time — if self-building the frontend, set these before npm run build; the pre-built image uses feeds.fun defaults
- **Environment variable format:** Backend uses FFUN_COMPONENT_OPTION (e.g. FFUN_LIBRARIAN_OPENAI_GENERAL_PROCESSOR__ENABLED=True)

---

## References
- GitHub: https://github.com/Tiendil/feeds.fun
- Single-user example: https://github.com/Tiendil/feeds.fun/tree/main/docs/examples/single-user
- Multi-user example: https://github.com/Tiendil/feeds.fun/tree/main/docs/examples/multi-user
- CHANGELOG: https://github.com/Tiendil/feeds.fun/blob/main/CHANGELOG.md
