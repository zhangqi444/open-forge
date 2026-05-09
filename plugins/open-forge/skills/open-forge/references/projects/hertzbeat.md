---
name: hertzbeat
description: Apache HertzBeat recipe for open-forge. AI-powered real-time observability system — unified metrics, logs, alerting, and status pages. Agentless, Prometheus-compatible. Covers Docker single-container quickstart and Docker Compose with MySQL + IoTDB. Derived from https://github.com/apache/hertzbeat and https://hertzbeat.apache.org/docs/.
---

# Apache HertzBeat

AI-powered open-source real-time observability system. Agentless monitoring for websites, services, databases, operating systems, cloud-native, networks, and more — unified into a single platform with metrics, logs, alerting, and built-in status pages.

- Upstream repo: <https://github.com/apache/hertzbeat>
- Docs: <https://hertzbeat.apache.org/docs/>
- Docker Hub: <https://hub.docker.com/r/apache/hertzbeat>
- License: Apache 2.0

## What it does

HertzBeat collects metrics by polling targets over HTTP, JMX, SSH, SNMP, JDBC, Prometheus scrape, and OTLP — all driven by YAML templates. No agent needed on the target. It ships 100+ pre-built monitoring templates (MySQL, PostgreSQL, Redis, Kafka, Kubernetes, Linux, Nginx, etc.) and lets you add new ones by editing YAML in the UI. Alerts fire in real time and fan out to Email, Slack, Telegram, DingTalk, WeChat, Webhook, SMS, and more. The built-in status page builder lets you publish uptime info to external users.

## Compatible install methods

| Method | Upstream URL | First-party? | When to use |
|---|---|---|---|
| Docker single-container (built-in H2 DB) | <https://hertzbeat.apache.org/docs/start/docker-deploy> | yes | Quick evaluation. Data lives in /opt/hertzbeat/data. |
| Docker Compose + MySQL + IoTDB | <https://github.com/apache/hertzbeat/tree/master/script/docker-compose/hertzbeat-mysql-iotdb> | yes | Recommended for production. MySQL stores metadata; IoTDB stores time-series metrics. |
| Docker Compose + MySQL + Victoria Metrics | <https://github.com/apache/hertzbeat/tree/master/script/docker-compose/hertzbeat-mysql-victoria-metrics> | yes | Alternative to IoTDB; VictoriaMetrics as the TSDB. |
| Docker Compose + PostgreSQL + GrepTimeDB | <https://github.com/apache/hertzbeat/tree/master/script/docker-compose/hertzbeat-postgresql-greptimedb> | yes | PostgreSQL metadata + GrepTimeDB as TSDB. |
| Binary package | <https://hertzbeat.apache.org/docs/start/package-deploy> | yes | Bare-metal. Requires Java 17. |
| Kubernetes (Helm) | <https://artifacthub.io/packages/search?repo=hertzbeat> | yes | Cluster deploy via Artifact Hub Helm chart. |
| Collector cluster (horizontal scale) | <https://hertzbeat.apache.org/docs/start/cluster-deploy> | yes | Add hertzbeat-collector sidecars that report to a single manager. |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | Which install method? | Options from table above | Drives which section applies. |
| preflight | Web UI port? | Integer, default 1157 | Maps to 1157:1157 in Compose / Docker run. |
| preflight | Internal gRPC/collector port? | Integer, default 1158 | Used by collector cluster registration. |
| preflight | Where should HertzBeat data be stored? | Path, default ./hertzbeat-data | Mounted to /opt/hertzbeat/data (single-container mode). |
| db (MySQL) | MySQL root password? | String | Generate with openssl rand -hex 16. Write to compose file. |
| smtp (optional) | SMTP host + port + user + pass? | Free-text | Configured in application.yml; needed for email alerts. |
| tz | Server timezone? | IANA tz string, default UTC | All containers should share the same TZ. |

## Install — Docker single-container (quickstart)

Source: https://hertzbeat.apache.org/docs/start/docker-deploy

```bash
docker run -d \
  -p 1157:1157 \
  -p 1158:1158 \
  --name hertzbeat \
  -v ./hertzbeat-data:/opt/hertzbeat/data \
  apache/hertzbeat:1.8.0
```

Access http://localhost:1157. Default credentials: admin / hertzbeat.

This mode stores everything (metadata + time-series) in an embedded H2 database under /opt/hertzbeat/data. Not recommended for production — H2 is single-writer and has no HA path.

## Install — Docker Compose + MySQL + IoTDB (recommended)

Source: https://github.com/apache/hertzbeat/tree/master/script/docker-compose/hertzbeat-mysql-iotdb

```bash
# 1. Clone the repo
git clone --depth 1 https://github.com/apache/hertzbeat.git
cd hertzbeat/script/docker-compose/hertzbeat-mysql-iotdb

# 2. Edit docker-compose.yaml:
#    - Replace MARIADB_ROOT_PASSWORD (default: 123456) with a strong password
#    - Update TZ on all services if not Asia/Shanghai
#    - Optionally pin the hertzbeat image tag

# 3. Start
docker compose up -d
```

docker-compose.yaml (abbreviated):

```yaml
services:
  mysql:
    image: mariadb:11.7
    environment:
      TZ: Asia/Shanghai
      MARIADB_ROOT_PASSWORD: CHANGE_ME
    volumes:
      - ./dbdata/mysqldata:/var/lib/mysql/
      - ./conf/sql:/docker-entrypoint-initdb.d/

  iotdb:
    image: apache/iotdb:1.2.2-standalone
    environment:
      TZ: Asia/Shanghai
    volumes:
      - ./dbdata/iotdbdata:/iotdb/data

  hertzbeat:
    image: apache/hertzbeat:1.8.0
    environment:
      TZ: Asia/Shanghai
      LANG: zh_CN.UTF-8
      HERTZBEAT_COLLECTOR_MYSQL_QUERY_ENGINE: auto
    ports:
      - "1157:1157"
      - "1158:1158"
    volumes:
      - ./conf/application.yml:/opt/hertzbeat/config/application.yml
      - ./conf/sureness.yml:/opt/hertzbeat/config/sureness.yml
      - ./ext-lib:/opt/hertzbeat/ext-lib
      - ./logs:/opt/hertzbeat/logs
    depends_on:
      mysql:
        condition: service_healthy
      iotdb:
        condition: service_healthy
```

Access http://localhost:1157. Default credentials: admin / hertzbeat.

## Software-layer concerns

### Ports

| Port | Use |
|---|---|
| 1157 | Web UI and REST API (HTTP) |
| 1158 | Collector cluster gRPC endpoint |

### Config files (Docker Compose layout)

| File | Purpose |
|---|---|
| conf/application.yml | Main HertzBeat config: datasource URLs, SMTP, AI settings, storage backend |
| conf/sureness.yml | Authentication: users, roles, and protected paths (sureness RBAC framework) |

### Key env vars (hertzbeat container)

| Variable | Default | Notes |
|---|---|---|
| TZ | Asia/Shanghai | Change to your timezone; set the same on all containers |
| LANG | zh_CN.UTF-8 | UI locale hint; use en_US.UTF-8 for English |
| HERTZBEAT_COLLECTOR_MYSQL_QUERY_ENGINE | auto | jdbc forces JDBC; auto uses built-in engine for MySQL/MariaDB |

### Data directories (inside container)

| Path | Contents |
|---|---|
| /opt/hertzbeat/data | Embedded H2 DB (single-container mode only) |
| /opt/hertzbeat/config/application.yml | Main config |
| /opt/hertzbeat/config/sureness.yml | Auth config |
| /opt/hertzbeat/logs | Application logs |
| /opt/hertzbeat/ext-lib | External JDBC drivers (Oracle, DB2) |

### Adding JDBC drivers for Oracle / DB2

Oracle and DB2 JDBC drivers are proprietary and not bundled. Place the JAR(s) in ./ext-lib (mapped to /opt/hertzbeat/ext-lib), then restart:

```bash
cp ojdbc8.jar ./ext-lib/
docker compose restart hertzbeat
```

MySQL, MariaDB, and PostgreSQL use HertzBeat's built-in query engine by default — no extra JARs needed.

## Upgrade procedure

1. Check release notes: https://github.com/apache/hertzbeat/releases
2. Back up data:
   ```bash
   docker compose stop hertzbeat
   docker compose exec mysql mysqldump -uroot -pCHANGE_ME hertzbeat > hertzbeat-$(date +%F).sql
   tar czf iotdb-$(date +%F).tgz dbdata/iotdbdata/
   ```
3. Update the image tag in docker-compose.yaml, then:
   ```bash
   docker compose pull hertzbeat
   docker compose up -d hertzbeat
   ```
4. Schema migrations run on startup automatically — check docker compose logs -f hertzbeat for errors.
5. Only upgrade IoTDB together with HertzBeat per the release notes — never update IoTDB independently.

## Collector cluster (optional horizontal scaling)

To add a remote collector (monitors targets the manager cannot reach directly):

```bash
docker run -d \
  --name hertzbeat-collector-1 \
  -e IDENTITY=remote-collector-1 \
  -e MODE=public \
  -e MANAGER_HOST=<hertzbeat-manager-ip> \
  -e MANAGER_PORT=1158 \
  apache/hertzbeat-collector:1.8.0
```

The new collector appears in the HertzBeat UI under Collectors. Assign monitoring tasks to it from the monitor edit page.

## Gotchas

- **Default password is well-known.** Change admin/hertzbeat immediately after first login. Also update sureness.yml if you rely on the default user list.
- **MariaDB password default is 123456.** Replace before first docker compose up; changing it after init requires a MySQL password reset — the Docker volume contains the already-initialised DB.
- **Timezone mismatch causes metric time skew.** Set TZ to the same value across all containers. Default is Asia/Shanghai — override to match your server timezone.
- **H2 embedded mode is dev-only.** The single-container quickstart uses H2. It has no HA, no concurrent-writer support, and schema migration can silently corrupt on unclean shutdown.
- **IoTDB 1.2.2-standalone is pinned.** Upgrading IoTDB independently of HertzBeat can break the storage schema. Only upgrade both together per the HertzBeat release notes.
- **Status pages need a reverse proxy for TLS.** HertzBeat's web server on port 1157 is plain HTTP. Place Caddy or nginx in front for HTTPS.
- **ext-lib must be a directory, not a file.** Confirm ./ext-lib is a bind-mount directory containing any needed JARs — Docker will auto-create it as an empty directory if missing.
- **Collector identity must be unique.** If two collectors register with the same IDENTITY, the second one silently overrides the first in the manager.

## Links

- Repo: https://github.com/apache/hertzbeat
- Docs: https://hertzbeat.apache.org/docs/
- Docker deploy guide: https://hertzbeat.apache.org/docs/start/docker-deploy
- Docker Compose scripts: https://github.com/apache/hertzbeat/tree/master/script/docker-compose
- Releases: https://github.com/apache/hertzbeat/releases
- Docker Hub: https://hub.docker.com/r/apache/hertzbeat
