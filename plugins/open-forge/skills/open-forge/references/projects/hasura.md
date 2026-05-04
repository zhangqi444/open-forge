# Hasura GraphQL Engine

Instantly build GraphQL and REST APIs on your data sources. Hasura connects to your databases and microservices and automatically generates a production-ready, composable API with authorization, subscriptions, and event triggers. Upstream: <https://github.com/hasura/graphql-engine>. Docs: <https://hasura.io/docs>.

Hasura v2 is the current stable self-hosted version. Hasura v3 (DDN) is the next generation, primarily a cloud/managed product. This recipe covers **Hasura v2 self-hosted**.

Hasura runs on port `8080` (GraphQL/REST API + console). It requires a PostgreSQL database for metadata storage. The admin console is enabled at `/console`.

## Compatible install methods

Verified against upstream docs at <https://hasura.io/docs/latest/deployment/deployment-guides/>.

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | <https://hasura.io/docs/latest/deployment/deployment-guides/docker/> | ✅ | Self-hosted development and production on a single host. |
| Kubernetes / Helm | <https://hasura.io/docs/latest/deployment/deployment-guides/kubernetes/> | ✅ | Production Kubernetes deployments. |
| Digital Ocean / Cloud marketplaces | <https://hasura.io/docs/latest/deployment/deployment-guides/> | ✅ | Managed one-click deploys. |
| Hasura Cloud | <https://cloud.hasura.io> | ✅ | Managed SaaS — out of scope for open-forge. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| db | "PostgreSQL metadata DB connection string?" | Free-text (sensitive) — e.g. `postgres://user:pass@host:5432/dbname` | All |
| db | "Database(s) to expose via Hasura GraphQL?" | Free-text | All |
| secrets | "HASURA_GRAPHQL_ADMIN_SECRET?" | Free-text (generate random string) | All production deploys |
| auth | "HASURA_GRAPHQL_JWT_SECRET (JWT auth config JSON)?" | Free-text — see JWT docs | Optional — for JWT auth |
| network | "Domain for the Hasura API?" | Free-text | Production/reverse-proxy |

## Software-layer concerns

### Key environment variables

| Variable | Purpose | Notes |
|---|---|---|
| `HASURA_GRAPHQL_METADATA_DATABASE_URL` | PostgreSQL connection for Hasura metadata | Required. Format: `postgres://user:pass@host:port/db` |
| `PG_DATABASE_URL` | PostgreSQL data source to expose via GraphQL | Can be same as metadata DB or a separate DB |
| `HASURA_GRAPHQL_ENABLE_CONSOLE` | Enable the web console | Set to `"true"` for self-hosted; `"false"` if using Hasura CLI console |
| `HASURA_GRAPHQL_ADMIN_SECRET` | Admin API key | **Required in production.** Enables admin access and secures metadata API. |
| `HASURA_GRAPHQL_DEV_MODE` | Enable dev mode (detailed errors) | Set to `"false"` in production. |
| `HASURA_GRAPHQL_JWT_SECRET` | JWT auth configuration (JSON) | Optional. For JWT-based user auth. See docs. |
| `HASURA_GRAPHQL_UNAUTHORIZED_ROLE` | Default role for unauthenticated requests | Optional. e.g. `"anonymous"` |
| `HASURA_GRAPHQL_ENABLED_LOG_TYPES` | Which log types to emit | `startup, http-log, webhook-log, websocket-log, query-log` |

### Docker Compose (official install-manifest)

Based on <https://github.com/hasura/graphql-engine/blob/master/install-manifests/docker-compose/docker-compose.yaml>:

```yaml
services:
  postgres:
    image: postgres:15
    restart: always
    volumes:
      - db_data:/var/lib/postgresql/data
    environment:
      POSTGRES_PASSWORD: postgrespassword

  graphql-engine:
    image: hasura/graphql-engine:v2.48.16  # pin to a specific release
    ports:
      - "8080:8080"
    restart: always
    environment:
      HASURA_GRAPHQL_METADATA_DATABASE_URL: postgres://postgres:postgrespassword@postgres:5432/postgres
      PG_DATABASE_URL: postgres://postgres:postgrespassword@postgres:5432/postgres
      HASURA_GRAPHQL_ENABLE_CONSOLE: "true"
      HASURA_GRAPHQL_DEV_MODE: "false"
      HASURA_GRAPHQL_ADMIN_SECRET: "${HASURA_GRAPHQL_ADMIN_SECRET}"
      HASURA_GRAPHQL_ENABLED_LOG_TYPES: startup, http-log, webhook-log, websocket-log, query-log
    depends_on:
      - postgres

  data-connector-agent:
    image: hasura/graphql-data-connector:v2.48.16
    restart: always
    ports:
      - "8081:8081"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8081/api/v1/athena/health"]
      interval: 5s
      timeout: 10s
      retries: 5
      start_period: 5s

volumes:
  db_data:
```

Store `HASURA_GRAPHQL_ADMIN_SECRET` in `.env`. Access the console at `http://localhost:8080/console`.

### Data directories

| Path | Contents |
|---|---|
| `db_data` volume | PostgreSQL data (metadata + data sources) |

Hasura itself is stateless. All state lives in the PostgreSQL metadata database (tables under `hdb_catalog` schema).

### Adding data sources

After deploy, connect additional databases via the console at `/console` → Data → Connect Database, or via the metadata API:

```bash
curl -H "X-Hasura-Admin-Secret: $HASURA_GRAPHQL_ADMIN_SECRET" \
  http://localhost:8080/v1/metadata \
  -d '{"type": "pg_add_source", "args": {"name": "mydb", "configuration": {"connection_info": {"database_url": "postgres://..."}}}}'
```

## Upgrade procedure

Based on <https://hasura.io/docs/latest/deployment/upgrades/>:

1. Read the changelog/migration notes for the target version.
2. Back up the PostgreSQL metadata database.
3. Update the image tag in `docker-compose.yaml` to the new version.
4. `docker compose up -d` — Hasura runs metadata migrations automatically on startup.
5. Check the console and run a test query to confirm the upgrade was successful.
6. For major versions (e.g. v2.x → v2.y), check for any catalog version migration steps.

## Gotchas

- **Set HASURA_GRAPHQL_ADMIN_SECRET in production.** Without it, the metadata API and console are publicly accessible with no authentication.
- **Console vs CLI console.** `HASURA_GRAPHQL_ENABLE_CONSOLE=true` serves the console from the server. For migrations-as-code workflow, use `HASURA_GRAPHQL_ENABLE_CONSOLE=false` and run `hasura console` via the CLI instead.
- **Data connector agent is required for non-Postgres sources.** The `data-connector-agent` sidecar is needed to connect to MySQL, MariaDB, Snowflake, Athena, etc. It is not required for PostgreSQL-only deployments.
- **Hasura v2 vs v3.** v3/DDN is the next-gen product, primarily cloud-hosted. Self-hosted deployments should use v2 stable releases.
- **Metadata is in PostgreSQL.** If the metadata DB is lost, Hasura loses all table tracking, relationships, and permission rules. Back it up.
- **Subscriptions require a persistent connection.** WebSocket subscriptions need a reverse proxy that supports WebSocket passthrough.

## Links

- Upstream: <https://github.com/hasura/graphql-engine>
- Docs (v2): <https://hasura.io/docs/latest/>
- Docker Compose install: <https://hasura.io/docs/latest/deployment/deployment-guides/docker/>
- Official docker-compose manifest: <https://github.com/hasura/graphql-engine/tree/master/install-manifests/docker-compose>
- Upgrade guides: <https://hasura.io/docs/latest/deployment/upgrades/>
- JWT auth docs: <https://hasura.io/docs/latest/auth/authentication/jwt/>
