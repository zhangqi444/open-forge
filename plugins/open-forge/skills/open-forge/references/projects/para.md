---
name: para
description: Recipe for Para — a scalable, multitenant backend server/framework for object persistence, API development, and authentication. Java + Docker.
---

# Para

Scalable, multitenant backend server/framework for object persistence, API development, and authentication. Provides a RESTful JSON API secured with Amazon Signature V4, full-text search, distributed caching, webhooks, JWT-based authentication, LDAP/SAML/social login, and role-based access control. Database-agnostic (H2 embedded, MongoDB, DynamoDB, Cassandra, SQL). Useful as a backend-as-a-service for web/mobile apps. Upstream: <https://github.com/erudika/para>. Docs: <https://paraio.org/docs/>.

License: Apache-2.0. Platform: Java 17+, Docker. Port: `8080`.

## Compatible install methods

| Method | When to use |
|---|---|
| Docker (erudikaltd/para) | Recommended — use `:latest_stable` tag |
| Executable JAR | For native Java server installs |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| config | "Root application access keys (app.accessKey / app.secretKey)?" | Set in `application.conf`; used for root app API access |
| db | "Database backend: H2 (embedded), MongoDB, PostgreSQL, or other?" | Default H2 embedded is fine for dev; use external DB for production |
| search | "Search backend: Lucene (default), Elasticsearch, or OpenSearch?" | Default Lucene embedded; use external search for large datasets |
| auth | "Authentication: local users, LDAP, SAML, OAuth (Google/GitHub/etc.)?" | Configure social login providers if needed |

## Docker (recommended)

**Important**: Use the `:latest_stable` tag, NOT `:latest`. The `:latest` tag can be unstable or broken.

```bash
mkdir para && cd para
touch application.conf
mkdir -p data
```

Minimal `application.conf`:
```hocon
para.app.accessKey = "app:myapp"
para.app.secretKey = "changeme-secret-key-at-least-32-chars"
para.env = "production"
# Embedded H2 database (for production use an external DB)
para.dao = "H2DAO"
# Embedded Lucene search
para.search = "LuceneSearch"
```

`docker-compose.yml`:
```yaml
services:
  para:
    image: erudikaltd/para:latest_stable
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      - JAVA_OPTS=-Dconfig.file=/para/application.conf
    volumes:
      - ./data:/para/data
      - ./application.conf:/para/application.conf
```

```bash
docker compose up -d
```

API available at `http://your-host:8080/v1/`. Admin console at <https://console.paraio.org> (connects to your local instance).

## CLI setup (optional)

```bash
npm install -g para-cli
# Connect to your local instance
para-cli setup
# Create a dedicated app (separate from root app)
para-cli new-app "myapp" --name "My App"
```

## Software-layer concerns

| Concern | Detail |
|---|---|
| Config | `application.conf` (HOCON format) |
| Data dir | `/para/data/` — contains H2 DB files and Lucene indexes |
| Default port | `8080` |
| API prefix | `/v1/` |
| Root app | The `app:para` root app owns all other apps; protect its keys |
| Auth | JWT tokens returned by `/v1/jwt_auth`; client apps call API with these |
| Plugins | Additional DAO/search backends installed as JAR plugins in `lib/` |
| Admin console | Web-based at <https://console.paraio.org> — connects to any Para endpoint |

## Upgrade procedure

```bash
# Change `:latest_stable` tag to specific version (e.g. :1.51.0)
docker compose pull
docker compose up -d
```

Check release notes for migration scripts: <https://github.com/erudika/para/releases>

## Gotchas

- **Never use `:latest` in production**: The `:latest` Docker tag tracks the development branch and may be unstable. Always use `:latest_stable` or a pinned version like `:1.51.0`.
- **Root app keys must be set before first run**: Set `para.app.accessKey` and `para.app.secretKey` in `application.conf` before starting. These are the root credentials — if left at defaults, the instance is insecure.
- **Embedded H2 is not for production**: The default H2 embedded database is fine for development but not recommended for production. Use PostgreSQL, MongoDB, or another supported DAO with the appropriate plugin.
- **Plugins are JARs, not packages**: To use an external database or search engine, download the matching plugin JAR and add it to the `lib/` directory (or use the multi-stage Docker build described in the README).
- **Port 25 is MCP context**: Para v1.51+ includes an MCP server endpoint, allowing AI agents to interact with Para APIs directly.

## Upstream links

- Source: <https://github.com/erudika/para>
- Docs: <https://paraio.org/docs/>
- Docker Hub: <https://hub.docker.com/r/erudikaltd/para>
- Admin console: <https://console.paraio.org>
- Para CLI: <https://github.com/Erudika/para-cli>
