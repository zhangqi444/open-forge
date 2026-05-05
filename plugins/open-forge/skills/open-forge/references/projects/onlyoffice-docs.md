---
name: onlyoffice-docs-project
description: ONLYOFFICE Docs (Document Server) recipe for open-forge. Open-source office suite for collaborative editing of DOCX, XLSX, PPTX, PDF, and other formats. Covers Docker (single-node), Docker Compose with PostgreSQL + RabbitMQ, JWT token security, HTTPS/TLS configuration, and upgrade procedure. Derived from https://github.com/ONLYOFFICE/Docker-DocumentServer and https://hub.docker.com/r/onlyoffice/documentserver.
---

# ONLYOFFICE Docs (Document Server)

Open-source online office suite for collaborative document editing. Upstream: <https://github.com/ONLYOFFICE/DocumentServer>. Docker deployment: <https://github.com/ONLYOFFICE/Docker-DocumentServer>. License: AGPLv3 (Community Edition).

ONLYOFFICE Docs supports collaborative editing of DOCX, ODT, XLSX, ODS, PPTX, ODP, PDF, and more. It integrates with Nextcloud, ownCloud, Seafile, and other platforms via connectors. Three editions exist: Community (free), Enterprise, and Developer.

## Compatible install methods

| Method | Upstream URL | First-party? | When to use |
|---|---|---|---|
| Docker single-node | <https://github.com/ONLYOFFICE/Docker-DocumentServer> | yes | Simple deployment. Built-in PostgreSQL and RabbitMQ. |
| Docker Compose (external DB) | <https://github.com/ONLYOFFICE/Docker-DocumentServer> | yes | Production. Separates PostgreSQL and RabbitMQ into own containers. |
| ONLYOFFICE Workspace (full suite) | <https://helpcenter.onlyoffice.com/installation/docs-community-install-ubuntu.aspx> | yes | Bundled with Community Server, Mail Server. Complex multi-service deploy. |
| Kubernetes (Helm chart) | <https://github.com/ONLYOFFICE/Kubernetes-DocSpace> | yes | High-availability cluster deployments. |
| Snap / DEB package | <https://helpcenter.onlyoffice.com/installation/docs-community-install-ubuntu.aspx> | yes | Bare-metal Ubuntu install without Docker. |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "Which deployment method?" | Docker single-node / Docker Compose | Drives config below. |
| preflight | "What port should ONLYOFFICE listen on?" | Integer default 80 | External HTTP port. |
| config | "PostgreSQL database password?" | String sensitive | Used as DB_PASSWORD. |
| config | "JWT secret for API token validation?" | String sensitive | JWT_SECRET. Protects the editor API from unauthorized use. Generate with: openssl rand -hex 32 |
| config | "Enable JWT token validation?" | Yes default Yes | JWT_ENABLED. Should be enabled for any public-facing instance. |
| tls | "Use HTTPS?" | Yes / No | If yes: mount TLS cert and key into /var/www/onlyoffice/Data/certs/. |

## Docker single-node install

Upstream: <https://github.com/ONLYOFFICE/Docker-DocumentServer>

Quickest way to get Document Server running. All dependencies (PostgreSQL, RabbitMQ, Redis, nginx) are bundled inside the container.

```bash
sudo docker run -i -t -d -p 80:80 \
    -e JWT_ENABLED=true \
    -e JWT_SECRET=your-secret-here \
    -v /app/onlyoffice/DocumentServer/logs:/var/log/onlyoffice \
    -v /app/onlyoffice/DocumentServer/data:/var/www/onlyoffice/Data \
    -v /app/onlyoffice/DocumentServer/lib:/var/lib/onlyoffice \
    -v /app/onlyoffice/DocumentServer/db:/var/lib/postgresql \
    onlyoffice/documentserver
```

Access at http://localhost/. The welcome page confirms the server is running.

## Docker Compose install (production, external DB)

Upstream: <https://github.com/ONLYOFFICE/Docker-DocumentServer>

```yaml
services:
  onlyoffice-documentserver:
    image: onlyoffice/documentserver
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
      - DB_PWD=your-db-password
      - AMQP_URI=amqp://guest:guest@onlyoffice-rabbitmq
      - JWT_ENABLED=true
      - JWT_SECRET=your-jwt-secret
    ports:
      - '80:80'
      - '443:443'
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/info/info.json"]
      interval: 30s
      retries: 5
      start_period: 60s
      timeout: 10s
    stdin_open: true
    restart: always
    stop_grace_period: 60s
    volumes:
       - onlyoffice-data:/var/www/onlyoffice/Data
       - onlyoffice-logs:/var/log/onlyoffice
       - onlyoffice-cache:/var/lib/onlyoffice/documentserver/App_Data/cache/files
       - onlyoffice-fonts:/usr/share/fonts

  onlyoffice-rabbitmq:
    container_name: onlyoffice-rabbitmq
    image: rabbitmq:3
    restart: always
    expose:
      - '5672'

  onlyoffice-postgresql:
    container_name: onlyoffice-postgresql
    image: postgres:12
    restart: always
    environment:
      POSTGRES_DB: onlyoffice
      POSTGRES_USER: onlyoffice
      POSTGRES_PASSWORD: your-db-password
    expose:
      - '5432'
    volumes:
      - postgresql-data:/var/lib/postgresql/data

volumes:
  onlyoffice-data:
  onlyoffice-logs:
  onlyoffice-cache:
  onlyoffice-fonts:
  postgresql-data:
```

## Software-layer concerns

### JWT token security

JWT validation is enabled by default (JWT_ENABLED=true). This protects the Document Server API from unauthorized use. The JWT_SECRET must be configured in both ONLYOFFICE Docs AND in the connecting application (Nextcloud connector, etc.) — they must match.

```bash
# Generate a secure JWT secret
openssl rand -hex 32
```

### HTTPS / TLS

For HTTPS, mount certificates into /var/www/onlyoffice/Data/certs/:

```
/var/www/onlyoffice/Data/certs/tls.crt  # SSL certificate
/var/www/onlyoffice/Data/certs/tls.key  # Private key
```

Or use environment variables to specify paths:
- SSL_CERTIFICATE_PATH (default: /var/www/onlyoffice/Data/certs/tls.crt)
- SSL_KEY_PATH (default: /var/www/onlyoffice/Data/certs/tls.key)

### Key environment variables

| Variable | Default | Description |
|---|---|---|
| DB_TYPE | postgres | Database type: postgres, mariadb, mysql, mssql, oracle |
| DB_HOST | (required) | Database hostname |
| DB_PORT | 5432 | Database port |
| DB_NAME | onlyoffice | Database name |
| DB_USER | onlyoffice | Database user |
| DB_PWD | (required) | Database password |
| AMQP_URI | (required) | RabbitMQ connection URI |
| JWT_ENABLED | true | Enable JWT token validation |
| JWT_SECRET | (random) | JWT shared secret — must match connecting apps |
| JWT_HEADER | Authorization | HTTP header for JWT |
| WOPI_ENABLED | false | Enable WOPI protocol support |
| ALLOW_PRIVATE_IP_ADDRESS | false | Allow connections from private IP ranges |

### Ports

| Port | Use |
|---|---|
| 80 | HTTP Web interface and API |
| 443 | HTTPS (when TLS configured) |

### Data directories (inside container)

| Path | Contents |
|---|---|
| /var/log/onlyoffice | Application logs |
| /var/www/onlyoffice/Data | Certificates and app data |
| /var/lib/onlyoffice | File conversion cache |
| /var/lib/postgresql | PostgreSQL data (single-node only) |

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

For single-node docker run, stop the container, pull the new image, and re-run with the same volume mounts.

## Gotchas

- **Docker version**: Upstream recommends Docker 20.10.21+. Older Docker has compatibility issues with the ubuntu:24.04 base image used by newer ONLYOFFICE releases.
- **JWT mismatch**: If JWT_SECRET in ONLYOFFICE does not match the secret configured in the connecting app (Nextcloud, etc.), document editing will fail with 403 errors. Always set JWT_SECRET explicitly.
- **Memory**: The recommendation is 4 GB RAM minimum. Document conversion is memory-intensive.
- **First-run warmup**: The container takes 30-60 seconds to start fully. The healthcheck uses /info/info.json — wait for it to pass before testing.
- **Editions**: The Docker Hub image onlyoffice/documentserver is the Community Edition (AGPLv3). Enterprise (-ee) and Developer (-de) editions require a license key.
- **Reverse proxy**: For production, place behind NGINX or Caddy. ONLYOFFICE's internal nginx handles proxying to the document conversion engine on port 8000.

## Links

- GitHub (Document Server): <https://github.com/ONLYOFFICE/DocumentServer>
- GitHub (Docker): <https://github.com/ONLYOFFICE/Docker-DocumentServer>
- Docker Hub: <https://hub.docker.com/r/onlyoffice/documentserver>
- Connectors (Nextcloud, etc.): <https://www.onlyoffice.com/all-connectors.aspx>
