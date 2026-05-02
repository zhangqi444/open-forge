# Kitsu

**What it is:** Collaborative production tracking and project management platform for animation, VFX, and video game studios. Manages tasks, reviews, deliveries, and communication across teams.

**Official URL:** https://kitsu.cg-wire.com  
**GitHub:** https://github.com/cgwire/kitsu  
**Stars:** 626

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/bare-metal | Docker Compose (via Zou) | Official recommended deployment |
| Any Linux VPS/bare-metal | Manual | Requires Zou backend + Node.js frontend |

Kitsu is the frontend UI; it requires **Zou** (https://github.com/cgwire/zou) as its backend API server.

---

## Inputs to Collect

### Before deploying
- Domain name for the web UI (e.g., `kitsu.example.com`)
- Domain name for the API backend (Zou) — often a subdomain like `zou.example.com`
- Admin email and password

### Environment / Config
- `DATABASE_URI` — PostgreSQL connection string (Zou)
- `SECRET_KEY` — Flask secret key for Zou
- `MAIL_*` — SMTP settings for email notifications
- `EVENT_STREAM_HOST` — Kitsu event server address

---

## Software-Layer Concerns

- **Two-component architecture:** Kitsu (Vue.js SPA) is served separately from Zou (Python/Flask API). Both must be deployed together.
- **Database:** PostgreSQL (managed by Zou)
- **Search indexing:** Zou uses its own internal indexer — no Elasticsearch required
- **File storage:** Previews and attachments stored on disk; mount a persistent volume for Zou's `previews/` directory
- **Reverse proxy:** Nginx or Caddy recommended to unify Kitsu UI + Zou API under one domain with path-based routing (`/api` → Zou)

---

## Upgrade Procedure

1. Pull latest images: `docker compose pull`
2. Run migrations: `docker compose run zou flask db upgrade`
3. Restart services: `docker compose up -d`

---

## Gotchas

- Kitsu **requires Zou** — deploying Kitsu alone will result in a non-functional UI
- The event streaming server (part of Zou) must be reachable from the Kitsu frontend for real-time updates
- CORS must be correctly configured between Kitsu's origin and Zou's API endpoint
- First-time setup requires running `zou init-db` and `zou create-admin` commands inside the Zou container

---

## References

- Full documentation: https://kitsu.cg-wire.com
- Zou backend: https://github.com/cgwire/zou
- Installation guide: https://zou.cg-wire.com/getting-started-docker/
