# seelf

A lightweight, painless self-hosted deployment platform. Point it at your Docker engine, upload your existing `compose.yml`, and seelf deploys your app with automatic subdomain routing and TLS certificates via Traefik. Think self-hosted Heroku/Dokku/Caprover — but simpler. Manages targets (Docker hosts), applications, and deployments with a clean web UI. Written in Go; single container.

- **GitHub:** https://github.com/YuukanOO/seelf
- **Docs:** https://yuukanoo.github.io/seelf/
- **Docker image:** `yuukanoo/seelf`
- **License:** MIT

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Docker host | docker run / Docker Compose | Single container; mounts Docker socket |
| Remote VPS | Docker Compose | Deploy seelf on a remote server to manage deployments to that host |

---

## Inputs to Collect

### Deploy Phase (environment variables)
| Variable | Required | Description |
|----------|----------|-------------|
| ADMIN_EMAIL | Yes | Email for the initial admin account |
| ADMIN_PASSWORD | Yes | Password for the initial admin account (only used if no users exist yet) |
| HTTP_SECURE | No | Set true to serve seelf over HTTPS |
| SEELF_SECRET | No | Secret key for JWT tokens — generate with: openssl rand -hex 32 |

### Volumes (required for persistence)
| Host path | Container path | Purpose |
|-----------|---------------|---------|
| /var/run/docker.sock | /var/run/docker.sock | Docker socket access |
| ./seelf-data | /app/data | seelf database + config |
| ./seelf-certs | /app/certs | TLS certificates (optional) |

---

## Software-Layer Concerns

### Architecture
- Single Go binary in a single container
- Mounts Docker socket to orchestrate deployments
- Deploys Traefik as a reverse proxy on the target Docker engine for routing

### Config
- All configuration via environment variables
- Application state stored in SQLite in /app/data

### Ports
- 8080 — Web UI and API

---

## Minimal docker-compose.yml

```yaml
services:
  seelf:
    image: yuukanoo/seelf:latest
    container_name: seelf
    environment:
      ADMIN_EMAIL: admin@example.com
      ADMIN_PASSWORD: changeme
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./data:/app/data
    ports:
      - "8080:8080"
    restart: unless-stopped
```

Quick test (no persistence):
```bash
docker run -d \
  -e "ADMIN_EMAIL=admin@example.com" \
  -e "ADMIN_PASSWORD=admin" \
  -v "/var/run/docker.sock:/var/run/docker.sock" \
  -p "8080:8080" \
  yuukanoo/seelf
```

---

## How Deployments Work

1. Create a **target** (defines a Docker engine + root URL, e.g. `https://apps.example.com`)
2. seelf installs Traefik on that target to handle routing
3. Create an **application** — name determines its subdomain
4. Submit a **deployment** (upload a compose archive, provide git repo, or use CI/CD API)
5. seelf reads `compose.yml`, deploys services, assigns `appname.apps.example.com` URLs
6. If root URL uses HTTPS, TLS certificates are issued automatically

---

## Upgrade Procedure

```bash
docker compose pull seelf
docker compose up -d seelf
# Check migration guide for major version upgrades:
# https://yuukanoo.github.io/seelf/guide/migration.html
```

---

## Gotchas

- **Docker socket required:** seelf must mount the Docker socket to manage containers; ensure the seelf container has appropriate permissions
- **Container path must match host path for compose stacks:** When seelf deploys to the same host it's running on, the paths in compose files must resolve the same way inside and outside the container
- **Root URL determines TLS:** If the target root URL starts with `https://`, seelf issues certificates automatically via Traefik; use `http://docker.localhost` for local testing
- **Traefik is installed per target:** seelf automatically deploys a Traefik reverse proxy on each configured target — you don't need to set this up manually
- **Subdomain routing requires a wildcard DNS or *.localhost:** For remote deployments, create a wildcard DNS record (`*.apps.example.com → your-server-ip`) so all app subdomains resolve automatically
- **ADMIN_PASSWORD only sets on first run:** If a user already exists, the env var is ignored — useful for upgrades
- **CI/CD integration:** seelf exposes a REST API for triggering deployments from CI pipelines (GitHub Actions, GitLab CI, etc.) — see API docs

---

## References
- GitHub: https://github.com/YuukanOO/seelf
- Quickstart: https://yuukanoo.github.io/seelf/guide/quickstart.html
- Installation: https://yuukanoo.github.io/seelf/guide/installation.html
- Configuration reference: https://yuukanoo.github.io/seelf/guide/configuration.html
- Migration guide: https://yuukanoo.github.io/seelf/guide/migration.html
