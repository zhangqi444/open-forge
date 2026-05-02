# Koffan

Lightweight collaborative shopping list app for couples and families.  
**~2.5 MB RAM, ~16 MB disk** — written in Go (rewritten from Next.js for minimal resource use).

- **Official site / repo:** https://github.com/PanSalut/Koffan
- **License:** MIT + Commons Clause (free to use, cannot sell as a service)

---

## What it does

Real-time shared shopping lists via WebSocket. One password to log in — no per-user registration.  
PWA-installable, offline-capable, dark mode, multi-language (EN/PL/DE/ES/FR/PT/UK/NO/LT/EL/SK/SV/RU), section/aisle organisation, REST API.

---

## Compatible combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Docker host | Docker / Compose | Single container, SQLite, no external DB needed |
| Railway / Render / DigitalOcean / Heroku | PaaS | One-click deploy buttons available |
| Coolify | Docker Compose | Enable "Connect to Predefined Network" |
| Bare metal | Go binary | `go run main.go` — no Docker required |

> **Port note (≥ 2.10.0):** Container listens on **8080**, not 80. Update reverse-proxy upstreams and port mappings if upgrading from 2.9.x.

---

## Inputs to collect

| Phase | Variable | Default | Notes |
|-------|----------|---------|-------|
| Deploy | `APP_PASSWORD` | `shopping123` | **Change this** — shared login password |
| Deploy | `APP_ENV` | `development` | Set `production` for secure cookies |
| Deploy | `DISABLE_AUTH` | `false` | `true` to skip auth behind a reverse proxy |
| Deploy | `DEFAULT_LANG` | `en` | UI language code |
| Deploy | `DB_PATH` | `./shopping.db` | SQLite file path inside container |
| Optional | `API_TOKEN` | *(disabled)* | Enables REST API when set |
| Rate-limit | `LOGIN_MAX_ATTEMPTS` | `5` | Attempts before lockout |
| Rate-limit | `LOGIN_WINDOW_MINUTES` | `15` | Rolling window for attempt count |
| Rate-limit | `LOGIN_LOCKOUT_MINUTES` | `30` | Lockout duration |
| Network | `PORT` | `8080` (Docker) / `3000` (bare metal) | Internal listen port |

---

## Software-layer concerns

### Data directory
- SQLite database lives at `/data/shopping.db` inside the container.
- Mount a named volume: `-v koffan-data:/data`

### Compose example
```yaml
services:
  koffan:
    image: ghcr.io/pansalut/koffan:latest
    container_name: koffan
    restart: unless-stopped
    ports:
      - "3000:8080"
    volumes:
      - koffan-data:/data
    environment:
      APP_PASSWORD: "change-me"
      APP_ENV: production

volumes:
  koffan-data:
```

### Reverse proxy
Point upstream to container port **8080**.

---

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

SQLite database persists in the named volume — no migration steps documented.  
If upgrading from ≤ 2.9.x, change any `80` port references to `8080`.

---

## Gotchas

- Default password `shopping123` is public knowledge — always override `APP_PASSWORD`.
- `APP_ENV=production` is required for cookies to be marked Secure (HTTPS deployments).
- Single shared password means all household members use the same credential; for separate households, run [multiple instances](https://github.com/PanSalut/Koffan/wiki/Multiple-Instances).
- REST API is disabled unless `API_TOKEN` is set.

---

## Further reading

- README: https://github.com/PanSalut/Koffan
- REST API docs: https://github.com/PanSalut/Koffan/wiki/REST-API
- Multiple instances: https://github.com/PanSalut/Koffan/wiki/Multiple-Instances
