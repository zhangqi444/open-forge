# Thrifty

**What it is:** A simple self-hosted monthly income and expense tracker. Not a penny-perfect ledger — designed for a rough overview of your monthly cash flow and what's left to spend. Supports groups (e.g. "streaming"), SVG icons, multiple users, auto-conversion between payment periods (weekly → monthly, etc.), and a Swagger API.

**Official URL:** https://github.com/tiehfood/thrifty
**Docker Hub:** `tiehfood/thrifty-ui` + `tiehfood/thrifty-api`
**License:** MIT
**Stack:** SvelteKit (UI) + Go (API) + SQLite; uses Traefik as internal reverse proxy

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS / bare metal | Docker Compose | Recommended; Traefik included in compose |
| Homelab | Docker Compose | Lightweight; SQLite, no external database |

---

## Inputs to Collect

### Pre-deployment
- `CURRENCY_ISO` — ISO 4217 currency code for the UI (e.g. `EUR`, `USD`, `GBP`)
- External port — default is `9090` (via Traefik)

### Optional
- `NUMBER_FORMAT` — number display format preference (configured in app settings)
- `SQLITE_DB_PATH` — custom path inside container for SQLite database (default: `/data/thrifty.sqlite`)
- `LOCAL_API_PORT` — if running without a reverse proxy, set the API container's external port

---

## Software-Layer Concerns

**Docker Compose:**
```yaml
services:
  traefik:
    image: traefik:3.6
    container_name: traefik
    ports:
      - "9090:80"
    environment:
      - TRAEFIK_PROVIDERS_DOCKER=true
      - TRAEFIK_PROVIDERS_DOCKER_EXPOSEDBYDEFAULT=true
      - TRAEFIK_ENTRYPOINTS_main_ADDRESS=:80
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro

  ui:
    image: tiehfood/thrifty-ui:latest
    container_name: ui
    environment:
      - CURRENCY_ISO=EUR

  api:
    image: tiehfood/thrifty-api:latest
    container_name: api
    environment:
      - SQLITE_DB_PATH=/data/thrifty.sqlite
    volumes:
      - database:/data

volumes:
  database:
```

**Default port:** `9090` (via Traefik → UI on internal `8080`)

**API documentation:** Available at `http://localhost:9090/swagger/index.html`

**No reverse proxy mode:** If you want to expose the API directly without Traefik, set `LOCAL_API_PORT=<your-desired-port>` on the UI container to tell it where to reach the API.

**Payment period conversion:** Enter an expense as weekly/bi-weekly/semi-annual and Thrifty calculates the monthly equivalent automatically.

**Multi-user:** Multiple users share the same instance — no per-user login, just simple user selection.

**Upgrade procedure:**
1. `docker compose pull`
2. `docker compose up -d`
3. Data is in the `database` Docker volume — unaffected by upgrades

**Build from source:**
```bash
docker compose -f docker-compose-build.yaml build
docker compose -f docker-compose-build.yaml up -d
```

---

## Gotchas

- **Two separate images** — `thrifty-ui` and `thrifty-api` are separate containers; Traefik routes between them; both must be running
- **Traefik included** — the compose file uses Traefik as the internal router, not as a full reverse proxy setup; your external reverse proxy sits in front of port `9090`
- **Currency set on UI container** — `CURRENCY_ISO` is an env var on the `ui` container, not the `api`; restart `ui` after changing it
- **SQLite only** — no PostgreSQL/MySQL support; fine for personal/family use
- **No authentication** — multiple "users" are just names, not authenticated accounts; add auth via reverse proxy if needed

---

## Links
- GitHub: https://github.com/tiehfood/thrifty
- Docker Hub (UI): https://hub.docker.com/r/tiehfood/thrifty-ui
- Docker Hub (API): https://hub.docker.com/r/tiehfood/thrifty-api
- ISO 4217 currency codes: https://en.wikipedia.org/wiki/ISO_4217
