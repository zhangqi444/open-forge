---
name: nimtable-project
description: Nimtable recipe for open-forge. Lightweight web platform for exploring and managing Apache Iceberg catalogs and tables. REST API + browser UI; connects to Hive Metastore, AWS Glue, S3 Tables, Apache Polaris, Lakekeeper, Unity Catalog. Three containers (web, backend, PostgreSQL). Upstream: https://github.com/nimtable/nimtable
---

# Nimtable

A lightweight web platform for exploring and managing Apache Iceberg catalogs and tables. Browse table schemas, partitions, snapshots, and manifests; run SQL queries from the browser; visualize file and snapshot distribution; and trigger compaction/maintenance via Spark or RisingWave.

Upstream: <https://github.com/nimtable/nimtable> | Docs: <https://docs.risingwave.com/iceberg/nimtable/get-started>

Three containers: a Next.js web frontend, a Java backend, and PostgreSQL.

> ⚠️ **Nightly images** — the upstream Docker Compose uses `nightly` tags. These are updated frequently and may include breaking changes. Pin to a specific digest or release tag for stable deployments.

## Compatible combos

| Infra | Catalog | Notes |
|---|---|---|
| Any Linux host | REST catalog | Default; no external catalog needed to start |
| Any Linux host | AWS Glue | Configure in web UI after first run |
| Any Linux host | Hive Metastore | Configure in web UI after first run |
| Any Linux host | Apache Polaris / Lakekeeper / Unity Catalog | Configure in web UI after first run |
| Any Linux host | S3 Tables | Configure in web UI after first run |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Host port for web UI?" | Default: `3000` |
| security | "Change default admin password?" | Default `admin`/`admin` — **must change after first login** |
| security | "Set a JWT_SECRET?" | Replace `your-super-secret-jwt-key-change-this-in-production` |
| security | "PostgreSQL password?" | Default `password` — change in production |
| config | "Iceberg catalog type and connection details?" | Configured in web UI after first run |

## Software-layer concerns

### Images

```
ghcr.io/nimtable/nimtable-web:nightly
ghcr.io/nimtable/nimtable:nightly
postgres:17
```

### Compose

```yaml
services:
  nimtable-web:
    image: ghcr.io/nimtable/nimtable-web:nightly
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - JAVA_API_URL=http://nimtable:8182
      - DATABASE_URL=postgresql://nimtable_user:password@database:5432/nimtable
      - JWT_SECRET=change-this-secret-in-production
      - ADMIN_USERNAME=admin
      - ADMIN_PASSWORD=admin      # CHANGE AFTER FIRST LOGIN
    depends_on:
      - nimtable
    networks:
      - nimtable-network

  nimtable:
    image: ghcr.io/nimtable/nimtable:nightly
    restart: unless-stopped
    depends_on:
      database:
        condition: service_healthy
    ports:
      - "8182:8182"
    configs:
      - source: config.yaml
        target: /nimtable/config.yaml
    environment:
      JAVA_OPTS: -Xmx32g -Xms512m
    networks:
      - nimtable-network

  database:
    image: postgres:17
    restart: unless-stopped
    volumes:
      - nimtable-data-postgres:/var/lib/postgresql/data
    environment:
      POSTGRES_USER: nimtable_user
      POSTGRES_PASSWORD: password    # CHANGE IN PRODUCTION
      POSTGRES_DB: nimtable
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U nimtable_user -d nimtable"]
      interval: 5s
      timeout: 5s
      retries: 5
    networks:
      - nimtable-network

configs:
  config.yaml:
    file: ./config.yaml

networks:
  nimtable-network:
    driver: bridge

volumes:
  nimtable-data-postgres:
```

> Source: upstream docker/docker-compose.yml — <https://github.com/nimtable/nimtable/tree/HEAD/docker>

### config.yaml

Nimtable requires a `config.yaml` file (mounted as a Docker config). Get the example from upstream:

```bash
curl -O https://raw.githubusercontent.com/nimtable/nimtable/HEAD/docker/config.yaml.example
cp config.yaml.example config.yaml
# Edit config.yaml to add your Iceberg catalog connection details
```

The config file defines catalog connections (REST, Glue, Hive, etc.) and compute engine integrations (Spark, RisingWave).

### Default credentials

| Field | Default |
|---|---|
| Username | `admin` |
| Password | `admin` |

> **Change the admin password immediately after first login** — the env vars (`ADMIN_USERNAME` / `ADMIN_PASSWORD`) are only used for initial setup. After first login and password change, credentials are stored in PostgreSQL and env vars are no longer used.

### Java backend memory

The `JAVA_OPTS: -Xmx32g -Xms512m` sets a 32 GB JVM heap maximum. Adjust `-Xmx` to match available host memory (e.g., `-Xmx4g` for a 4 GB machine).

### Supported catalogs

| Catalog | Notes |
|---|---|
| REST catalog | Built-in; also serves as a standard Iceberg REST Catalog API endpoint |
| AWS Glue | Via AWS credentials in config.yaml |
| Hive Metastore | Via Hive Metastore URI in config.yaml |
| Apache Polaris | REST-compatible |
| Lakekeeper | REST-compatible |
| Unity Catalog | Via config.yaml |
| S3 Tables | AWS S3 Tables (managed Iceberg) |

### Compute engine integration

Nimtable can trigger compaction and maintenance jobs on connected compute engines:
- **Apache Spark** — submit compaction jobs via Spark REST API
- **RisingWave** — native integration (Nimtable is a RisingWave Labs project)

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

PostgreSQL data persists in the `nimtable-data-postgres` named volume.

> With `nightly` images, check the upstream changelog before upgrading — nightly builds may include breaking config changes.

## Gotchas

- **Change default admin password immediately** — `admin`/`admin` ships as the default. After changing via the UI, env vars are ignored.
- **`JWT_SECRET` must be changed in production** — the placeholder value is insecure.
- **PostgreSQL password in plain text** — change `POSTGRES_PASSWORD` and update `DATABASE_URL` to match.
- **`config.yaml` is required** — the Java backend won't start without it. Copy and edit `config.yaml.example` from the upstream `docker/` directory.
- **`-Xmx32g` is a ceiling, not a reservation** — the JVM won't actually use 32 GB unless catalog/query workloads demand it. Lower it to fit your host's actual RAM.
- **Nightly images may break** — `nightly` tags are updated on every commit. Pin to a specific release or digest for production use.
- **All three containers must be on the same Docker network** — the web frontend calls the Java API at `http://nimtable:8182` by container name; they must share `nimtable-network`.

## Links

- Upstream README: <https://github.com/nimtable/nimtable>
- Documentation: <https://docs.risingwave.com/iceberg/nimtable/get-started>
- Docker setup directory: <https://github.com/nimtable/nimtable/tree/HEAD/docker>
- Roadmap: <https://github.com/nimtable/nimtable/issues/50>
- Slack community: <https://go.risingwave.com/slack>
