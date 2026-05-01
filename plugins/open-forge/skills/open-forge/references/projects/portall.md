# Portall

**Web UI for generating, tracking, and organizing ports and services across multiple hosts — with Docker integration and 360+ pre-defined service definitions.**
GitHub: https://github.com/need4swede/Portall

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose (build) | Build from source |
| Any Linux | Docker Compose (pull) | Pull pre-built image |

---

## Inputs to Collect

### All phases
- `SECRET_KEY` — Flask session secret key
- `HOST_IP` — IP of the host machine (defaults to 127.0.0.1 if unset)
- `DOCKER_HOST` — Docker API endpoint (for Docker integration)
- `DOCKER_ENABLED` — true/false to enable Docker integration

---

## Software-Layer Concerns

### Quick start (pull image)
```bash
docker-compose -f docker-compose.pull.yml up -d
```

### Quick start (build)
```bash
docker-compose up -d
```

### Stack
- Backend: Flask 3.0.3 (Python 3.11)
- Database: SQLAlchemy + SQLite
- Migrations: Flask-Migrate + Alembic
- Docker socket access: via socket-proxy (read-only, based on 11notes/socket-proxy:stable)

### Features
- 360+ pre-defined service definitions for port assignment
- Port scanning across hosts
- Import from Caddyfile and docker-compose stacks
- JSON export/import for backup
- Docker integration: query running containers for ports
- Portainer and Komodo compatible
- Drag-and-drop block UI with Light/Dark themes and custom CSS

---

## Upgrade Procedure

1. docker-compose pull
2. docker-compose up -d

---

## Gotchas

- Set HOST_IP explicitly if your server is not at 127.0.0.1 — port entries will otherwise show the wrong address
- Docker integration uses a read-only socket proxy for security — the Docker socket is not mounted directly
- SQLite database; for multi-host setups ensure the data volume is persisted

---

## References
- GitHub: https://github.com/need4swede/Portall#readme
