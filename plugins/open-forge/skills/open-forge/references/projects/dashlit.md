# DashLit

**What it is:** Simple, self-hosted browser startpage / new-tab dashboard. Features a built-in drag-and-drop editor to create an application hub — no file editing required. Supports optional password protection and reverse-proxy headers.

**Official URL:** https://github.com/codewec/dashlit  
**Docs:** https://dashlit.cwec.dev  
**Live demo:** https://demo.dashlit.cwec.dev

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Docker Compose | Recommended |
| Any Linux host | Docker run | Single container |

---

## Inputs to Collect

| Phase | Input | Notes |
|-------|-------|-------|
| Deploy | `ORIGIN` | Full public URL (e.g. `http://localhost:3000` or `https://dash.example.com`) — required for SvelteKit |
| Deploy | Host port | Default `3000` |
| Deploy | Data directory | Mounted at `/app/data` for persistent dashboard config |
| Optional | `PASSWORD` | Enable simple password protection |
| Optional | `SECRET_KEY` | JWT signing key (used with password auth; random string) |
| Optional | `HOST_HEADER` | Header name for real IP behind nginx (default `HOST`) |
| Optional | `ADDRESS_HEADER` | Real-IP header (default `X-Real-IP`) |
| Optional | `PROTOCOL_HEADER` | Proto header (default `X-Forwarded-Proto`) |

---

## Software-Layer Concerns

### Docker image
```
ghcr.io/codewec/dashlit:latest
```

### docker-compose.yml (minimal, no password)
```yaml
services:
  app:
    container_name: dashlit-app
    image: ghcr.io/codewec/dashlit:latest
    restart: unless-stopped
    environment:
      ORIGIN: '${ORIGIN:-http://localhost:3000}'
    ports:
      - '3000:3000'
    volumes:
      - ./data:/app/data
```

### docker-compose.yml (with password)
```yaml
services:
  app:
    container_name: dashlit-app
    image: ghcr.io/codewec/dashlit:latest
    environment:
      ORIGIN: '${ORIGIN:-http://localhost:3000}'
      NODE_ENV: '${NODE_ENV:-production}'
      HOST_HEADER: '${HOST_HEADER:-HOST}'
      ADDRESS_HEADER: '${ADDRESS_HEADER:-X-Real-IP}'
      PROTOCOL_HEADER: '${PROTOCOL_HEADER:-X-Forwarded-Proto}'
      PASSWORD: '${PASSWORD:-password}'
      SECRET_KEY: '${SECRET_KEY:-any-secret-string-for-jwt-auth}'
    restart: unless-stopped
    ports:
      - '3000:3000'
    volumes:
      - ./data:/app/data
```

### Data directory
- Dashboard configuration persisted in `./data/`
- No database — file-based storage

---

## Upgrade Procedure

```bash
docker compose pull
docker compose up -d
```

Dashboard config is in the mounted volume; no migration needed.

---

## Gotchas

- **`ORIGIN` must match your access URL** — SvelteKit uses this to prevent CSRF; if you access via a domain but set `ORIGIN` to localhost, auth will break
- **Reverse proxy setup** — set `HOST_HEADER`, `ADDRESS_HEADER`, and `PROTOCOL_HEADER` to match your proxy's forwarding headers; otherwise the app may reject requests as cross-origin
- **Password is optional** — without `PASSWORD` set, the dashboard is open to anyone who can reach the port
- **No multi-user support** — single shared dashboard instance; suitable for personal or household use

---

## Links

- GitHub: https://github.com/codewec/dashlit
- Documentation: https://dashlit.cwec.dev
- Container registry: ghcr.io/codewec/dashlit
