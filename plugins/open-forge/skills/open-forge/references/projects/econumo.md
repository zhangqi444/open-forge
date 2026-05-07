# Econumo

**Personal and family budgeting application** — Docker-based finance manager supporting multiple currencies, joint accounts, shared budgets, and expense tracking. Clean web UI, quick Docker Compose setup, minimal resource requirements.

**Official site:** https://econumo.com
**Source:** https://github.com/econumo/econumo
**License:** MIT
**Demo:** https://demo.econumo.com

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any VPS / bare metal | Docker Compose | Only supported deployment method |

---

## Inputs to Collect

### Phase 1 — Planning
- Domain / hostname (or localhost for personal use)
- Primary currency and additional currencies needed

### Phase 2 — Deploy
- Environment variables from `.env.example` (database credentials, app secret, etc.)
- Admin account created on first visit to the web UI

---

## Software-Layer Concerns

- **Stack:** PHP backend, bundled with Nginx; all in Docker Compose
- **Minimum RAM:** 256 MB recommended
- **First start time:** Up to 90 seconds on initial run; ready when `nginx entered RUNNING` appears in logs
- **Features:** Expense/income tracking, budget planning, multiple currencies, joint accounts, shared family budgets
- **Dockerfile/build:** Separate `build-configuration` repository handles the image build; this repo is the deployment config

---

## Deployment

```bash
git clone --single-branch https://github.com/econumo/econumo
cd econumo/deployment/docker-compose
cp .env.example .env
# Edit .env with your configuration
docker-compose up -d
# Wait up to 90 seconds for first start
# Visit http://localhost:8181 and create the first user
```

Additional configuration guides:
https://econumo.com/docs/

---

## Upgrade Procedure

```bash
docker compose pull
docker compose up -d
```

---

## Gotchas

- **First start is slow** — allow up to 90 seconds; check logs for `nginx entered RUNNING` before visiting the UI
- **Port 8181 by default** — configure a reverse proxy (Nginx/Caddy/Traefik) for HTTPS in production
- **Only Docker Compose supported** — no native install path; requires Docker and Docker Compose
- **Early-stage project** — v0.10.0; feature set is growing but some advanced features may be missing compared to mature budgeting apps

---

## Links

- Upstream README: https://github.com/econumo/econumo#readme
- Documentation: https://econumo.com/docs/
- Demo: https://demo.econumo.com
