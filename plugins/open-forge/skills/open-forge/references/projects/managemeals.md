# ManageMeals

**Clean, ad-free recipe manager with URL import** — SvelteKit frontend backed by a Fastify API, storing recipes in MongoDB. Import recipes from any URL, organize collections, and manage meals without ads or bloated content. Self-hosted via Docker Compose.

**Official site:** https://managemeals.com
**Source:** https://github.com/managemeals/manage-meals-web (frontend) / https://github.com/managemeals/manage-meals-api (backend)
**License:** GPL-3.0
**Demo:** https://demo.managemeals.com

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any VPS / bare metal | Docker Compose | Recommended; requires both frontend + API repos |

---

## Inputs to Collect

### Phase 1 — Planning
- Domain / hostname
- Whether to use load-balanced multi-instance setup (optional)

### Phase 2 — Deploy
- MongoDB credentials
- Redis connection (used by API for caching/sessions)
- Recipe scraper service config (bundled in Docker Compose)
- JWT/session secret

---

## Software-Layer Concerns

- **Two repositories required:**
  - `manage-meals-web` — SvelteKit frontend
  - `manage-meals-api` — Fastify (Node.js) backend
- **Stack:** SvelteKit (frontend), Fastify + Node.js (API), MongoDB, Redis
- **Recipe scraper:** A separate `recipe-scraper` microservice is included in the API's Docker Compose for URL-based recipe imports
- **Multi-instance (optional):** The frontend supports two web instances + a load balancer; expose via `docker-compose.override.yaml`
- **Self-hosting guide:** https://github.com/managemeals/manage-meals-api/wiki/Self%E2%80%90hosting

---

## Deployment

Follow the self-hosting wiki:
https://github.com/managemeals/manage-meals-api/wiki/Self%E2%80%90hosting

Key steps:
1. Clone both `manage-meals-api` and `manage-meals-web`
2. Copy `.env.docker.example` → `.env.docker` in each repo and configure
3. Start the API stack: `make build && make upd` (in `manage-meals-api`)
4. Start the frontend: `make build && make upd` (in `manage-meals-web`)
5. Expose ports via `docker-compose.override.yaml` in each repo

---

## Upgrade Procedure

```bash
# In each repo directory
git pull
make build
make upd
```

---

## Gotchas

- **Two separate repos** — both must be deployed and configured; the frontend is useless without the API
- **Port exposure requires override file** — create `docker-compose.override.yaml` to map container ports to host ports (not in the default compose file)
- **MongoDB data persistence** — ensure MongoDB data volume is on persistent storage; losing it means losing all recipes
- **Low commit activity** — active development resumed briefly in March 2026; check repo for current maintenance status

---

## Links

- Frontend README: https://github.com/managemeals/manage-meals-web#readme
- API README: https://github.com/managemeals/manage-meals-api#readme
- Self-hosting guide: https://github.com/managemeals/manage-meals-api/wiki/Self%E2%80%90hosting
- Demo: https://demo.managemeals.com
