---
name: onlyoffice-docs-project
description: ONLYOFFICE Docs (Document Server) recipe for open-forge. Open-source collaborative office suite for documents, spreadsheets, and presentations. Covers Docker deployment with PostgreSQL and RabbitMQ, HTTPS configuration, JWT security, and integration with other apps. Derived from https://github.com/ONLYOFFICE/Docker-DocumentServer and https://helpcenter.onlyoffice.com/installation/docs-community-docker.aspx.
---

# ONLYOFFICE Docs (Document Server)

Open-source collaborative office suite. Upstream: <https://github.com/ONLYOFFICE/DocumentServer>. Docker deployment repo: <https://github.com/ONLYOFFICE/Docker-DocumentServer>. Documentation: <https://helpcenter.onlyoffice.com/installation/docs-community-docker.aspx>. License: AGPL v3.

ONLYOFFICE Docs provides browser-based collaborative editing for DOCX, ODT, XLSX, ODS, PPTX, ODP, PDF, and other formats. It is used as an editing backend for Nextcloud, ownCloud, Seafile, Odoo, Moodle, and other platforms via connectors.

## Compatible install methods

| Method | Upstream URL | First-party? | When to use |
|---|---|---|---|
| Docker (single container) | <https://github.com/ONLYOFFICE/Docker-DocumentServer> | yes | Simplest self-contained deployment. Internal PostgreSQL + RabbitMQ. |
| Docker Compose (split services) | <https://github.com/ONLYOFFICE/Docker-DocumentServer> | yes | Production. External PostgreSQL + RabbitMQ for better resource management. |
| Debian/Ubuntu package | <https://helpcenter.onlyoffice.com/installation/docs-community-install-ubuntu.aspx> | yes | Bare-metal install on Ubuntu/Debian. |
| ONLYOFFICE DocSpace | <https://www.onlyoffice.com/docspace.aspx> | yes | Full workspace product (includes Docs). Separate deployment. |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "What port should ONLYOFFICE Docs listen on?" | Integer default 80 | Or 443 for HTTPS. |
| config | "Enable JWT authentication?" | Yes / No | Strongly recommended for production. Prevents unauthorized access. |
| config | "JWT secret?" | String sensitive | Required if JWT enabled. |
| config | "Connect to external PostgreSQL?" | Yes / No | Default: uses bundled internal PostgreSQL. |
| config | "PostgreSQL host/user/pass/db?" | Connection details | Only if external PostgreSQL selected. |
| tls | "Enable HTTPS?" | Yes / No | Can use Let's Encrypt auto-cert or supply own cert. |
| tls | "Domain for Let's Encrypt cert?" | FQDN | Required if using automatic Let's Encrypt. |

## Docker single-container install

Upstream: <https://github.com/ONLYOFFICE/Docker-DocumentServer>

Simplest deployment — all services (PostgreSQL, RabbitMQ, Redis) run inside a single container.

```bash
sudo docker run -i -t -d -p 80:80 \
    -v /app/onlyoffice/DocumentServer/logs:/var/log/onlyoffice \
    -v /app/onlyoffice/DocumentServer/data:/var/www/onlyoffice/Data \
    -v /app/onlyoffice/DocumentServer/lib:/var/lib/onlyoffice \
    -v /app/onlyoffice/DocumentServer/db:/var/lib/postgresql \
    onlyoffice/documentserver
```

## Docker Compose install (split services)

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
      - AMQP_URI=amqp://guest:guest@onlyoffice-rabbitmq
      # Enable JWT (recommended for production):
      # - JWT_ENABLED=true
      # - JWT_SECRET=your-secret-here
      # - JWT_HEADER=Authorization
    ports:
      - '80:80'
      - '443:443'
    stdin_open: true
    restart: always
    stop_grace_period: 60s
    volumes:
      - /var/www/onlyoffice/Data
      - /var/log/onlyoffice
      - /var/lib/onlyoffice/documentserver/App_Data/cache/files
      - /var/www/onlyoffice/documentserver-example/public/files
      - /usr/share/fonts

  onlyoffice-rabbitmq:
    container_name: onlyoffice-rabbitmq
    image: rabbitmq:3
    restart: always
    expose:
      - '5672'

  onlyoffice-postgresql:
    container_name: onlyoffice-postgresql
    image: postgres:12
    environment:
      - POSTGRES_DB=onlyoffice
      - POSTGRES_USER=onlyoffice
      - POSTGRES_HOST_AUTH_METHOD=trust
    restart: always
    expose:
      - '5432'
    volumes:
      - postgresql_data:/var/lib/postgresql

volumes:
  postgresql_data:
```

### Deploy steps

```bash
docker compose up -d
```

Access at http://your-server/. The Document Server welcome page confirms it is running.

## HTTPS configuration

### Using Let's Encrypt (automatic)

Set the domain in the container environment and mount the cert directory:

```bash
docker run -i -t -d -p 443:443 \
    -e LETS_ENCRYPT_DOMAIN=docs.example.com \
    -e LETS_ENCRYPT_MAIL=admin@example.com \
    -v /app/onlyoffice/DocumentServer/data:/var/www/onlyoffice/Data \
    onlyoffice/documentserver
```

### Manual certificate

Mount certs to /var/www/onlyoffice/Data:

```
/var/www/onlyoffice/Data/certs/onlyoffice.crt
/var/www/onlyoffice/Data/certs/onlyoffice.key
```

The container detects the cert files and switches to HTTPS automatically.

## JWT security (strongly recommended)

Without JWT, any client that can reach your Document Server can use it. Enable JWT to require a signed token:

```yaml
environment:
  - JWT_ENABLED=true
  - JWT_SECRET=your-long-random-secret
  - JWT_HEADER=Authorization
  - JWT_IN_BODY=true
```

Configure the same secret in your integration connector (Nextcloud, ownCloud, etc.).

## Software-layer concerns

### System requirements

| Resource | Minimum |
|---|---|
| RAM | 4 GB |
| CPU | 2-core 2 GHz+ |
| Swap | 2 GB |
| Disk | 2 GB free (plus document cache) |

### Ports

| Port | Use |
|---|---|
| 80 | HTTP |
| 443 | HTTPS |

### Data directories (volumes)

| Path | Contents |
|---|---|
| /var/log/onlyoffice | Application logs |
| /var/www/onlyoffice/Data | TLS certificates, configuration |
| /var/lib/onlyoffice | File cache |
| /var/lib/postgresql | PostgreSQL data (single-container mode) |

### Docker engine version

Upstream requires Docker 20.10.21+ due to ubuntu:24.04 base image.

## Upgrade procedure

```bash
docker compose pull
docker compose down
docker compose up -d
```

Or for single-container:

```bash
docker pull onlyoffice/documentserver
docker stop <container-name>
docker rm <container-name>
# Re-run with same -v volume flags
```

## Gotchas

- **JWT required for production**: Without JWT any machine that can reach port 80/443 can use your Document Server as an open editing proxy.
- **Integration connector must match JWT secret**: The Nextcloud/ownCloud ONLYOFFICE connector must be configured with the same JWT_SECRET.
- **docker-engine version**: Ubuntu 24.04-based images require Docker 20.10.21+. Update Docker before deploying.
- **Startup time**: ONLYOFFICE Docs takes 30-60 seconds to fully start. The healthcheck interval is set to 60s accordingly.
- **High RAM usage**: 4 GB minimum RAM is real. The service will OOM on smaller instances under any load.
- **Editions**: The `onlyoffice/documentserver` image is the free Community edition. `-de` and `-ee` tags are Developer/Enterprise editions.
- **Port 80 conflict**: If NGINX or Apache is already running on port 80, change the host port mapping (e.g. `8080:80`).

## Links

- GitHub: <https://github.com/ONLYOFFICE/DocumentServer>
- Docker deployment repo: <https://github.com/ONLYOFFICE/Docker-DocumentServer>
- Docker Hub: <https://hub.docker.com/r/onlyoffice/documentserver>
- Docker install docs: <https://helpcenter.onlyoffice.com/installation/docs-community-docker.aspx>
- Connectors (Nextcloud, ownCloud, etc.): <https://www.onlyoffice.com/all-connectors.aspx>
