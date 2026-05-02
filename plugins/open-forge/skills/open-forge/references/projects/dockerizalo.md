# Dockerizalo

**Simple self-hosted deployment platform for homelabs**
Official site: https://github.com/undernightcore/dockerizalo

Dockerizalo clones from any Git source, builds Docker images, and deploys them — all managed through a web UI. Supports secrets, volumes, ports, and real-time build/container logs. Designed to coexist with existing homelab apps; uses your host's Docker daemon (not Docker-in-Docker).

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Docker host | docker-compose | Three containers: proxy + API + UI + Postgres |
| Homelab server | docker-compose | Mounts host Docker socket |

## Inputs to Collect

### Phase: Pre-deployment (required)
- `APP_SECRET` — random secret for API auth (replace `hitthekeyboardwithyourheadhere`)
- `POSTGRES_PASSWORD` — PostgreSQL password (update in both `db` service and `DATABASE_URL`)

## Software-Layer Concerns

**Docker images:**
- `ghcr.io/undernightcore/dockerizalo:latest` — API backend
- `ghcr.io/undernightcore/dockerizalo-ui:latest` — Frontend
- `ghcr.io/undernightcore/dockerizalo-proxy:latest` — Reverse proxy routing UI + API

**Docker socket:** The API container mounts `/var/run/docker.sock` — this is how Dockerizalo manages deployments on the host without Docker-in-Docker.

**Volumes:**
- `./apps:/data/dockerizalo` — cloned repos and app data
- `./pg:/var/lib/postgresql` — Postgres data

**Port:** `8080` on the proxy container (web UI entry point)

**Key env vars (API service):**
| Variable | Purpose |
|----------|---------|
| `DATABASE_URL` | PostgreSQL connection string |
| `APP_SECRET` | Auth signing secret — change before deploy |

**Health check:** Postgres has a healthcheck; API waits for `service_healthy`.

## Upgrade Procedure

1. Pull latest images: `docker-compose pull`
2. Recreate: `docker-compose up -d`
3. App data in `./apps` and Postgres in `./pg` persist across upgrades
4. API runs migrations automatically on startup

## Gotchas

- **Docker socket exposure** — mounting `/var/run/docker.sock` gives the API container full Docker access on the host; trust the container and secure `APP_SECRET`
- **No built-in HTTPS** — Dockerizalo assumes you have an existing reverse proxy (Nginx Proxy Manager, Traefik, Caddy); it deploys apps to ports you specify, not HTTPS
- **No auto-redeploy by default** — webhook-triggered auto-redeploy requires additional setup; check the FAQ/docs
- **`APP_SECRET` default is a placeholder** — the default value is literally `hitthekeyboardwithyourheadhere`; replace it before exposing the UI
- **Builds happen on host** — images are built on your Docker host; large builds will consume host CPU/RAM

## References
- Upstream README: https://github.com/undernightcore/dockerizalo/blob/HEAD/README.md
