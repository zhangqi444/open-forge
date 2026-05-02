# Dockwatch

**What it is:** UI-driven Docker container update manager and notification hub. Monitors running containers for available image updates, surfaces container health status, and sends notifications via Notifiarr or other configured channels. Also integrates Trivy for vulnerability scanning of container images.

**Official URL:** https://github.com/Notifiarr/dockwatch  
**Wiki / full docs:** https://dockwatch.wiki

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux Docker host | Docker Compose | Recommended; needs Docker socket access |
| Any Linux Docker host | Docker run | Single container |

---

## Inputs to Collect

| Phase | Input | Notes |
|-------|-------|-------|
| Deploy | Host port | Web UI port (check dockwatch.wiki for current default) |
| Deploy | Docker socket path | Usually `/var/run/docker.sock` |
| Deploy | Data/config directory | Persistent storage for Dockwatch database and settings |
| Optional | Notifiarr API key | For push notifications on updates/health events |
| Optional | Other notification webhooks | Discord, Slack, etc. — configured in UI |

---

## Software-Layer Concerns

### Docker image
```
ghcr.io/notifiarr/dockwatch:latest
```
(Check dockwatch.wiki for the canonical image reference and any `lscr.io` mirrors.)

### Minimal docker-compose.yml
```yaml
services:
  dockwatch:
    image: ghcr.io/notifiarr/dockwatch:latest
    container_name: dockwatch
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./config:/config
    ports:
      - "8080:8080"
    restart: unless-stopped
```
> **Note:** Port and volume paths may differ — consult https://dockwatch.wiki for the authoritative compose example; the project README links there exclusively.

### Docker socket access
- Dockwatch **requires** access to the Docker socket to list/inspect containers and pull updated images
- Mount as read-only (`:ro`) for monitoring-only mode; read-write is required if Dockwatch handles pulling/updating

### Trivy integration
- Vulnerability database is downloaded on first use and can be updated manually via Settings › Development
- Database files are stored in the config volume

---

## Upgrade Procedure

```bash
docker compose pull
docker compose up -d
```

Configuration and state are stored in the mounted config volume. No manual migration step required.

---

## Gotchas

- **Docker socket security** — mounting `/var/run/docker.sock` gives the container significant host access; run behind authentication and restrict network exposure
- **Wiki is the primary docs source** — the README contains only a brief description and redirects to https://dockwatch.wiki for all configuration and usage instructions
- **Trivy security breach advisory** — Dockwatch is not affected by the 2024 Trivy upstream security incident (confirmed in release notes)
- **Active development branch** — the default API branch is `develop`; the `main` branch may lag behind; use `ghcr.io/notifiarr/dockwatch:latest` for current releases

---

## Links

- GitHub: https://github.com/Notifiarr/dockwatch
- Full documentation wiki: https://dockwatch.wiki
