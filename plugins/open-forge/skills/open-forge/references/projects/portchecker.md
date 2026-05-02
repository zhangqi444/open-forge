# PortChecker (portchecker.io)

**What it is:** A self-hosted open-source utility to check port availability (open/closed/filtered) on any hostname or IP address from outside your network. Consists of a static Nginx frontend and a Python API backend.

**Official URL:** https://github.com/dsgnr/portchecker.io
**Public instance:** https://portchecker.io
**License:** MIT
**Stack:** Python (Litestar/Gunicorn) + Nginx frontend; multi-arch Docker

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS / bare metal | Docker Compose | Recommended; includes both frontend and API |
| Any Linux VPS / bare metal | Standalone (Python + Node) | Manual install without Docker |
| Homelab | Docker Compose | Lightweight; low resource use |

---

## Inputs to Collect

### Pre-deployment
- `ALLOW_PRIVATE` — set to `True` to allow checking private/RFC1918 IP ranges (default: `False` for security)
- `DEFAULT_HOST` — optionally pre-fill the UI with a default hostname/IP
- `DEFAULT_PORT` — optionally pre-fill the UI with a default port (default: `443`)
- `API_URL` — override if API is not at default `http://api:8000`

### Runtime
- Hostname or IP address to check
- Port number to test

---

## Software-Layer Concerns

**Docker Compose (production):**
```bash
git clone https://github.com/dsgnr/portchecker.io.git
cd portchecker.io
docker compose up -d
```

Images:
- Frontend: `ghcr.io/dsgnr/portcheckerio-web:latest`
- API: `ghcr.io/dsgnr/portcheckerio-api:latest`

**Default ports:**
- Frontend: `8080`
- API: `8000`

**Architecture:** Two-container setup — static HTML/JS frontend behind Nginx, Python Litestar API backend. Production uses Gunicorn with Uvicorn workers.

**Prometheus metrics:** `/metrics` endpoint on the API for Grafana/Prometheus monitoring. Example Grafana dashboard included at `grafana/README.md`.

**Upgrade procedure:**
1. `docker compose pull`
2. `docker compose up -d`

---

## Gotchas

- **Checks are performed from your server's perspective** — if your server can't reach an IP, the check will show closed even if the port is actually open
- **Private IPs blocked by default** — `ALLOW_PRIVATE=False` prevents checking RFC1918 addresses; set to `True` only if you need internal network checks
- **Outbound connectivity required** — the API container must be able to make TCP connections to external hosts
- **Two containers** — both must be running; if only the API is exposed without the frontend you can use the REST API directly
- API docs available at `/docs` when running (Litestar auto-generated OpenAPI)

---

## Links
- GitHub: https://github.com/dsgnr/portchecker.io
- Public instance: https://portchecker.io
- API docs: https://portchecker.io/docs
- Grafana dashboard: https://github.com/dsgnr/portchecker.io/tree/main/grafana
