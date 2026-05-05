---
name: thingsboard
description: ThingsBoard recipe for open-forge. Open-source IoT platform for device management, data collection, processing, and visualization. Covers Docker Compose (single-node CE) install with PostgreSQL. Upstream: https://thingsboard.io/docs/user-guide/install/docker/
---

# ThingsBoard

Open-source IoT platform for device management, data collection, processing, and real-time visualization. Built for connecting devices via MQTT, CoAP, HTTP, and LwM2M, storing time-series telemetry, building dashboards, and triggering rule-based actions.

21,631 stars · Apache-2.0

Upstream: https://github.com/thingsboard/thingsboard
Website: https://thingsboard.io/
Docs: https://thingsboard.io/docs/
Install guide (Docker): https://thingsboard.io/docs/user-guide/install/docker/

## Editions

| Edition | License | Notes |
|---|---|---|
| Community Edition (CE) | Apache-2.0 | Free, open-source, self-hosted — covered in this recipe |
| Professional Edition (PE) | Commercial | Additional features: white-labeling, advanced reporting, integrations |
| Cloud | Managed SaaS | Out of scope |

This recipe covers **Community Edition only**.

## What it is

ThingsBoard CE provides a complete IoT backend:

- **Device management** — Provision, monitor, and control IoT devices with rich server-side APIs
- **Telemetry collection** — Store time-series data in PostgreSQL or Cassandra (hybrid mode)
- **Rule engine** — Visual rule chains for data processing, transformation, and alerting
- **Dashboards** — Drag-and-drop widget dashboards with real-time data visualization
- **Multi-tenancy** — Tenant accounts and customer sub-accounts
- **Protocols** — MQTT, CoAP, HTTP, LwM2M, SNMP, Modbus (via integrations)
- **Notifications** — Email, SMS, Slack, PagerDuty, and more

## Compatible install methods

| Method | Upstream | When to use |
|---|---|---|
| Docker Compose (single-node CE) | https://thingsboard.io/docs/user-guide/install/docker/ | Recommended for most self-hosters — one node, PostgreSQL |
| Docker Compose (microservices) | https://github.com/thingsboard/thingsboard/tree/master/docker | Advanced — multi-node cluster with Kafka, ZooKeeper |
| Debian/Ubuntu package | https://thingsboard.io/docs/user-guide/install/ubuntu/ | Direct install on bare metal or VM |
| AWS Marketplace AMI | https://thingsboard.io/docs/user-guide/install/aws/ | AWS-hosted, out of scope here |

## Inputs to collect

| Phase | Prompt | Applicability |
|---|---|---|
| domain | "What domain/IP will ThingsBoard be accessed from?" | All |
| db_pass | "PostgreSQL password for ThingsBoard?" | All Docker deploys |
| port | "Host port for ThingsBoard HTTP UI? (default: 8080)" | Docker Compose single-node |
| mqtt_port | "Host port for MQTT? (default: 1883)" | If connecting IoT devices via MQTT |

## Docker Compose single-node install (Community Edition)

Upstream: https://thingsboard.io/docs/user-guide/install/docker/

### 1. Create docker-compose.yml

    mkdir -p /opt/thingsboard && cd /opt/thingsboard
    cat > docker-compose.yml << 'EOF'
    services:
      mytb:
        restart: always
        image: thingsboard/tb-postgres:latest
        depends_on:
          - postgres
        environment:
          TB_QUEUE_TYPE: in-memory
          SPRING_DATASOURCE_URL: jdbc:postgresql://postgres:5432/thingsboard
          SPRING_DATASOURCE_USERNAME: thingsboard
          SPRING_DATASOURCE_PASSWORD: ${PG_PASS}
        ports:
          - "8080:9090"
          - "1883:1883"
          - "7070:7070"
          - "5683-5688:5683-5688/udp"
        volumes:
          - ~/.mytb-data:/data
          - ~/.mytb-logs:/var/log/thingsboard

      postgres:
        restart: always
        image: postgres:16
        environment:
          POSTGRES_DB: thingsboard
          POSTGRES_USER: thingsboard
          POSTGRES_PASSWORD: ${PG_PASS}
        volumes:
          - ~/.mytb-postgres:/var/lib/postgresql/data
    EOF

### 2. Set the database password

    echo "PG_PASS=$(openssl rand -hex 16)" > .env

### 3. Create data directories

    mkdir -p ~/.mytb-data && sudo chown -R 799:799 ~/.mytb-data
    mkdir -p ~/.mytb-logs && sudo chown -R 799:799 ~/.mytb-logs
    mkdir -p ~/.mytb-postgres

### 4. Initialize the database

    docker compose run --rm -e INSTALL_TB=true -e LOAD_DEMO=true mytb

The `LOAD_DEMO=true` flag loads sample dashboards and devices for exploration. Omit for a clean install.

### 5. Start services

    docker compose up -d && docker compose logs -f mytb

Wait for `Starting ThingsBoard Application` in the logs. First startup takes 2–5 minutes.

### 6. Access the UI

Open http://your-server:8080

Default credentials:

| Role | Email | Password |
|---|---|---|
| System Administrator | sysadmin@thingsboard.org | sysadmin |
| Tenant Administrator (demo only) | tenant@thingsboard.org | tenant |
| Customer User (demo only) | customer@thingsboard.org | customer |

**Change all default passwords immediately after first login.**

## Port mapping

| Container port | Default host port | Protocol | Service |
|---|---|---|---|
| 9090 | 8080 | HTTP | Web UI and REST API |
| 1883 | 1883 | TCP | MQTT |
| 7070 | 7070 | TCP | Edge RPC |
| 5683–5688 | 5683–5688 | UDP | CoAP |

## Upgrade

    docker compose pull
    docker compose up -d

ThingsBoard includes automatic database migration on startup. Back up PostgreSQL before upgrading.

    # Backup before upgrade
    docker compose exec postgres pg_dump -U thingsboard thingsboard > tb-backup-$(date +%F).sql

## Backup

    # Database
    docker compose exec postgres pg_dump -U thingsboard thingsboard > thingsboard-$(date +%F).sql

    # Data directory
    tar -czf mytb-data-$(date +%F).tar.gz ~/.mytb-data

## Gotchas

- **uid 799** — The ThingsBoard container runs as uid 799. Data and log directories on the host must be owned by this uid (`chown 799:799`), or the container will fail to start with permission errors.
- **First startup is slow** — Database initialization takes 2–5 minutes. Monitor logs with `docker compose logs -f mytb`.
- **Change default passwords** — The default sysadmin password is publicly known. Change it immediately at Settings → Account.
- **`tb-postgres` image** — The single-node `thingsboard/tb-postgres` image bundles both the application and PostgreSQL in one container. The docker-compose.yml in this recipe separates them for better manageability; the upstream quick-start uses the bundled image.
- **Memory** — ThingsBoard is a Java application with substantial startup memory. Allocate at least 2 GB RAM; 4 GB recommended.
- **`in-memory` queue** — `TB_QUEUE_TYPE=in-memory` is suitable for single-node deploys. For clustering, switch to Kafka.
- **MQTT port 1883** — Unencrypted by default. For production, configure TLS certificates or put MQTT behind a reverse proxy/TLS terminator.

## Links

- GitHub: https://github.com/thingsboard/thingsboard
- Website: https://thingsboard.io/
- Install guide (Docker): https://thingsboard.io/docs/user-guide/install/docker/
- Full docs: https://thingsboard.io/docs/
- Getting started: https://thingsboard.io/docs/getting-started-guides/helloworld/
- Rule engine docs: https://thingsboard.io/docs/user-guide/rule-engine-2-0/re-getting-started/
