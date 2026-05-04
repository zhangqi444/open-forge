---
name: datahub
description: DataHub recipe for open-forge. Covers Docker Compose quickstart and production deployment. Open-source AI data catalog for metadata management, data discovery, lineage, and governance across databases, data warehouses, data lakes, dashboards, and ML models. Sourced from https://github.com/datahub-project/datahub and https://docs.datahub.com/docs/quickstart.
---

# DataHub

Open-source AI data catalog and metadata platform for data discovery, lineage, governance, and observability. Originally built at LinkedIn; now developed by Acryl Data. Supports ingestion from 50+ sources including Snowflake, BigQuery, dbt, Airflow, Kafka, Postgres, S3, and Looker. Upstream: https://github.com/datahub-project/datahub. Docs: https://docs.datahub.com/.

DataHub exposes a GraphQL API, REST API, and a Python SDK (acryl-datahub) for programmatic metadata management.

## Compatible install methods

| Method | Upstream | When to use |
|---|---|---|
| Docker Compose (datahub-cli quickstart) | https://docs.datahub.com/docs/quickstart | Local dev / small teams |
| Helm (Kubernetes) | https://docs.datahub.com/docs/deploy/kubernetes | Production; scalable |
| DataHub Cloud (managed) | https://datahub.com | Managed SaaS; out of scope for open-forge |

## Architecture components

| Component | Purpose | Default image |
|---|---|---|
| GMS (Generalized Metadata Store) | Core metadata API backend | linkedin/datahub-gms |
| Frontend | React web UI | linkedin/datahub-frontend-react |
| MCE Consumer | Metadata Change Event consumer | linkedin/datahub-mce-consumer |
| MAE Consumer | Metadata Audit Event consumer | linkedin/datahub-mae-consumer |
| Elasticsearch | Full-text search index | elasticsearch:7.x |
| Kafka + ZooKeeper | Event streaming backbone | confluentinc/cp-kafka |
| MySQL | Primary metadata store | mysql:8.0 |
| Neo4j (optional) | Graph lineage store | neo4j:4.x |

## Prerequisites

- Docker and Docker Compose
- `datahub` CLI: `pip install acryl-datahub`
- Minimum: 8 GB RAM, 4 CPU cores (Elasticsearch + Kafka are memory-hungry)

## Inputs to collect

| Phase | Prompt | Applicability |
|---|---|---|
| preflight | "Deploy locally (quickstart) or to Kubernetes (Helm)?" | Drives method |
| auth | "Set a custom admin password?" | Default: datahub / datahub |
| sources | "Which data sources to ingest from?" | Drives which ingestion recipes to configure |
| storage | "Use Neo4j for graph lineage, or Elasticsearch-only?" | Neo4j adds richer lineage graph but more RAM |

## Quickstart (Docker Compose via CLI)

```sh
# Install CLI
pip install acryl-datahub

# Launch DataHub (pulls and starts all containers)
datahub docker quickstart

# Open http://localhost:9002
# Default credentials: datahub / datahub
```

The quickstart command downloads a managed docker-compose.yml from the DataHub releases and starts all services.

To stop:
```sh
datahub docker quickstart --stop
```

## Key ports

| Port | Service |
|---|---|
| 9002 | DataHub frontend (web UI) |
| 8080 | GMS REST API |
| 9092 | Kafka broker |
| 9200 | Elasticsearch |
| 3306 | MySQL |

## Ingestion example (Postgres)

```yaml
# postgres-recipe.yml
source:
  type: postgres
  config:
    host_port: "localhost:5432"
    database: mydb
    username: myuser
    password: mypassword

sink:
  type: datahub-rest
  config:
    server: http://localhost:8080
```

```sh
datahub ingest -c postgres-recipe.yml
```

## Upgrade procedure

```sh
datahub docker quickstart --quickstart-compose-file docker-compose.yml
# Or pull the latest and re-run quickstart
pip install acryl-datahub --upgrade
datahub docker quickstart
```

For Helm upgrades: `helm upgrade datahub datahub/datahub -f values.yaml`

## Gotchas

- **Default credentials are public** — change datahub / datahub before exposing to a network.
- **Elasticsearch memory** — requires at least 2 GB heap; set `ES_JAVA_OPTS=-Xms2g -Xmx2g` or the container will OOM-kill.
- **Kafka startup order** — GMS depends on Kafka topics being created; the quickstart script handles retries but manual Compose deploys may need health-check dependencies.
- **Neo4j optional** — lineage works without Neo4j using Elasticsearch graph mode; Neo4j adds richer traversal but doubles RAM requirements.
- **Ingestion from behind firewalls** — the ingestion CLI runs wherever you run it (laptop, CI, Airflow); it does not need to run inside the DataHub containers.
- **dbt integration** — run `datahub ingest -c dbt-recipe.yml` after each dbt run to push column-level lineage and model metadata.

## Links

- GitHub: https://github.com/datahub-project/datahub
- Quickstart docs: https://docs.datahub.com/docs/quickstart
- Ingestion sources: https://docs.datahub.com/docs/metadata-ingestion/
- Helm chart: https://docs.datahub.com/docs/deploy/kubernetes
- Docker Hub (GMS): https://hub.docker.com/r/linkedin/datahub-gms
