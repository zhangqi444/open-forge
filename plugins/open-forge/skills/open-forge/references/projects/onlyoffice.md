---
name: onlyoffice
description: ONLYOFFICE recipe for open-forge. Open-source office suite (Document Server) for collaborative editing of DOCX/XLSX/PPTX/PDF documents. Self-hosted via Docker Compose with PostgreSQL + RabbitMQ. Source: https://github.com/ONLYOFFICE/DocumentServer. Docs: https://helpcenter.onlyoffice.com.
---

# ONLYOFFICE Docs (Document Server)

Open-source collaborative office suite supporting DOCX, XLSX, PPTX, ODT, ODS, ODP, PDF, and PDF Forms. Can run standalone or integrate with Nextcloud, ownCloud, Seafile, Odoo, Mattermost, and many others via connectors. Upstream: <https://github.com/ONLYOFFICE/DocumentServer>. Help center: <https://helpcenter.onlyoffice.com>.

> **Editions:** Community (free, this recipe), Enterprise, and Developer editions exist. The `onlyoffice/documentserver` Docker image is the free Community edition.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| VPS / bare metal | Docker Compose + PostgreSQL + RabbitMQ | Upstream-recommended production path |
| VPS / bare metal | Docker single container (no external DB) | Simple; uses internal SQLite + RabbitMQ. OK for low-concurrency. |
| Nextcloud server | Nextcloud ONLYOFFICE app + Document Server | Most common integration pattern |
| Linux server | .deb/.rpm package | Upstream provides APT/YUM repos |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Standalone or integrated with Nextcloud/other?" | Drives connector setup |
| db | "PostgreSQL password?" | For onlyoffice DB user |
| jwt | "Enable JWT secret? (recommended)" | JWT_SECRET value; prevents unauthorised use of the Document Server API |
| tls | "TLS: terminate at ONLYOFFICE container or behind reverse proxy?" | ONLYOFFICE can handle Let's Encrypt directly; or use NGINX/Caddy in front |
| domain | "Public domain for Document Server?" | Required for HTTPS + integration with Nextcloud etc. |

## Software-layer concerns

- Config path (container): /etc/onlyoffice/documentserver/local.json
- Default ports: 80 (HTTP), 443 (HTTPS if TLS enabled in container)
- Data volumes (mount these for persistence):
  - /var/log/onlyoffice — logs
  - /var/www/onlyoffice/Data — TLS certificates
  - /var/lib/onlyoffice — file cache
  - /var/lib/postgresql — database (if using bundled PostgreSQL)
  - /usr/share/fonts — custom fonts
- System requirements: 4 GB RAM minimum (8 GB recommended), dual-core 2 GHz+ CPU
- JWT: strongly recommended to set JWT_ENABLED=true + JWT_SECRET to prevent open document editing by anyone who can reach the server

### Docker Compose (PostgreSQL + RabbitMQ — production)

```yaml
services:
  onlyoffice-documentserver:
    image: onlyoffice/documentserver:latest
    container_name: onlyoffice-documentserver
    depends_on:
      - onlyoffice-postgresql
      - onlyoffice-rabbitmq
    environment:
      - DB_TYPE=postgres
      - DB_HOST=onlyoffice-postgresql
      - DB_PORT=5432
      - DB_NAME=onlyoffice
      - DB_USER=onlyoffice
      - AMQP_URI=amqp://guest:guest@onlyoffice-rabbitmq
      - JWT_ENABLED=true
      - JWT_SECRET=<your-jwt-secret>
      - JWT_HEADER=Authorization
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - onlyoffice-logs:/var/log/onlyoffice
      - onlyoffice-data:/var/www/onlyoffice/Data
      - onlyoffice-lib:/var/lib/onlyoffice
      - onlyoffice-fonts:/usr/share/fonts
    restart: always
    stop_grace_period: 60s

  onlyoffice-rabbitmq:
    image: rabbitmq:3
    restart: always

  onlyoffice-postgresql:
    image: postgres:15
    environment:
      POSTGRES_DB: onlyoffice
      POSTGRES_USER: onlyoffice
      POSTGRES_HOST_AUTH_METHOD: trust
    volumes:
      - postgresql-data:/var/lib/postgresql/data
    restart: always

volumes:
  onlyoffice-logs:
  onlyoffice-data:
  onlyoffice-lib:
  onlyoffice-fonts:
  postgresql-data:
```

Pin the image tag in production (e.g. onlyoffice/documentserver:9.3.1). Check https://hub.docker.com/r/onlyoffice/documentserver/tags.

### Simple single-container run (low traffic)

```bash
docker run -d -p 8080:80 \
  -e JWT_ENABLED=true -e JWT_SECRET=<secret> \
  onlyoffice/documentserver
```

## Upgrade procedure

1. Review release notes: https://github.com/ONLYOFFICE/DocumentServer/releases
2. Backup data volumes (logs, data, lib directories)
3. Pull new image: docker compose pull
4. docker compose down && docker compose up -d
5. Check container health: curl http://localhost:8000/info/info.json

## Gotchas

- **JWT is off by default** — any service that can reach your Document Server can open/edit any document. Always set JWT_ENABLED=true and JWT_SECRET in production.
- **RAM requirements** are real: startup may fail or become unstable under 4 GB RAM. The container bundles Node.js, multiple microservices, and a PostgreSQL connection pool.
- **First startup** is slow: Document Server initialises fonts, DB schema, and internal services on first boot (~1-2 min).
- **Nextcloud integration**: Use the ONLYOFFICE Nextcloud app; set the Document Server URL + JWT secret in Nextcloud admin settings. HTTPS required for cross-origin embedding.
- **Custom fonts**: Mount fonts into /usr/share/fonts and restart; Document Server will re-index them.
- **docker-engine version**: Use docker-engine 20.10.21+ (upstream requirement; older versions have compatibility issues with the ubuntu:24.04 base image).
- **PostgreSQL POSTGRES_HOST_AUTH_METHOD=trust**: Acceptable inside a compose network (not exposed externally). For hardened setups, use a proper password and set DB_PWD env var.

## Links

- Upstream repo: https://github.com/ONLYOFFICE/DocumentServer
- Docker Hub: https://hub.docker.com/r/onlyoffice/documentserver
- Help center: https://helpcenter.onlyoffice.com
- Connectors (Nextcloud, ownCloud, etc.): https://www.onlyoffice.com/all-connectors.aspx
- Release notes: https://github.com/ONLYOFFICE/DocumentServer/releases
- API docs: https://api.onlyoffice.com/docs/docs-api/get-started/overview/
