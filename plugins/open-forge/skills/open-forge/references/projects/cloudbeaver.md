---
name: CloudBeaver
description: "Web-based DB manager — the web cousin of DBeaver. Multi-database SQL editor, data grid, navigator, import/export, access to 80+ DB types through JDBC. Java + TypeScript/React. Apache-2.0 (Community Edition). Commercial Team/Enterprise editions available."
---

# CloudBeaver

CloudBeaver is **DBeaver Community Edition, reimagined for the browser** — a full-featured web-based database manager. Connect to 80+ databases (PostgreSQL/MySQL/MariaDB/Oracle/SQL Server/ClickHouse/DuckDB/H2/MongoDB/Cassandra/Redis/SQLite/...) via the battle-tested DBeaver/JDBC engine, with modern web UI: **SQL editor** (with autocompletion + syntax highlighting), **data grid** (spreadsheet-like view + edit), **navigator tree** (schemas + tables + objects), **data import/export**, **ER diagrams**, **access control**.

Built + maintained by **DBeaver Corp.** (the commercial entity behind DBeaver). **Community Edition is Apache-2.0**; commercial **CloudBeaver Team / Enterprise** editions add advanced features (federated access, audit, SSO, more drivers).

Positioning: **the go-to "phpMyAdmin but modern, multi-DB, web-hosted"** — covers the DBeaver desktop use case centrally.

Features (Community):

- **80+ DB connectors** via JDBC
- **SQL editor** with autocompletion, variable bindings, formatting, history
- **Data grid** — view/edit rows, find/replace, regex search, multi-cell paste + NULL
- **Navigator tree** — schemas/tables/views/procedures/functions
- **Data import/export** — CSV, SQL insert, XLSX, more
- **ER diagrams** — visualize schema
- **Connection sharing** with team members
- **SSH tunneling** for DB access
- **Role-based access** (Community — basic; Team/Enterprise — richer)

- Upstream repo: <https://github.com/dbeaver/cloudbeaver>
- Docker Hub: <https://hub.docker.com/r/dbeaver/cloudbeaver>
- Deployment wiki: <https://github.com/dbeaver/cloudbeaver/wiki/CloudBeaver-Deployment>
- Demo server: <https://demo.cloudbeaver.io>
- DBeaver (desktop): <https://dbeaver.io>
- Company: <https://dbeaver.com>

## Architecture in one minute

- **Java backend** (GraphQL API over WebSocket) + **TypeScript/React frontend**
- **Embedded H2** for CloudBeaver's own metadata (users, connections, sessions)
- **Connects to any JDBC-reachable DB** — drivers bundled for common DBs, pluggable for more
- **Resource**: 500 MB - 1 GB RAM; JVM-bound
- **Runs as single container** in typical deploy

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Single VM          | **Docker (`dbeaver/cloudbeaver:latest`)**                          | **Upstream-recommended**                                                           |
| Kubernetes         | Community manifests                                                        | Works                                                                                      |
| Bare-metal         | JDK 11+ + distributable ZIP                                                           | Possible                                                                                    |
| Managed            | **CloudBeaver Team / Enterprise hosted** (commercial)                                              | Commercial tier                                                                                            |

## Inputs to collect

| Input                | Example                                           | Phase        | Notes                                                                    |
| -------------------- | ------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `db.example.com`                                      | URL          | TLS via reverse proxy                                                            |
| Admin user           | first-run wizard (or `cbadmin` initial)                        | Bootstrap    | Strong password + MFA if possible                                                            |
| DB connections       | per-DB: host/port/user/password (or SSH tunnel config)              | Connections  | Entered per user or shared                                                                        |
| TLS cert             | Let's Encrypt / internal CA                                                | TLS          | Via reverse proxy                                                                                 |
| SSO (paid)           | SAML / OIDC                                                                 | Auth         | Commercial tier only                                                                                              |

## Install via Docker

```yaml
services:
  cloudbeaver:
    image: dbeaver/cloudbeaver:latest                    # pin specific version in prod
    container_name: cloudbeaver
    restart: unless-stopped
    ports:
      - "8978:8978"
    volumes:
      - ./workspace:/opt/cloudbeaver/workspace
```

Browse `http://<host>:8978/` → complete first-run setup → admin creation.

## First boot

1. Complete setup wizard: product name, admin username/password (**strong password mandatory**)
2. Define initial DB connections (connection wizard → test → save)
3. Consider connection security:
   - Use **SSH tunnels** instead of exposing DB ports to CloudBeaver directly
   - Use **read-only DB users** for exploratory access
   - Use **role-specific DB users** for different CloudBeaver users
4. Put behind TLS reverse proxy
5. Restrict network access to CloudBeaver itself (VPN / IP allowlist / forward-auth)
6. Create user accounts; assign connections per user
7. Back up `workspace/`

## Data & config layout

- `workspace/` — H2 metadata DB + config + session state + logs
- H2 holds CloudBeaver users, connections, preferences (NOT your actual data — that's on the target DBs)
- **H2 metadata contains saved credentials for target DBs** (encrypted) — treat as sensitive

## Backup

```sh
sudo tar czf cloudbeaver-$(date +%F).tgz workspace/
```

Back up target DBs via their native tools (pg_dump/mysqldump/etc.), independent of CloudBeaver.

## Upgrade

1. Releases: <https://github.com/dbeaver/cloudbeaver/releases>. Active — releases often; recent changelogs show weekly patch cadence.
2. Docker: bump tag → restart → H2 migrations auto.
3. **Back up `workspace/` first.**
4. Recent versions regularly bump library CVEs (recent changelogs patch axios, lodash, vite, picomatch CVEs). Upgrading is part of security hygiene.

## Gotchas

- **CloudBeaver stores DB credentials.** When users save a connection, credentials are encrypted in H2 metadata. Losing `workspace/` = users re-enter all connections. Leaking `workspace/` = attacker gets encrypted creds (still a concern — attacker with H2 file + knowledge of encryption scheme can sometimes recover). Backup encryption + access control on backup files.
- **Access to CloudBeaver = access to every DB it's connected to.** Treat CloudBeaver UI auth like an SSH jumpbox: strong password + MFA (if available) + network restrict (VPN/bastion only, ideally).
- **Community vs Team/Enterprise**: Community is fully functional + Apache-2.0 for individual + small-team use. Advanced features (SAML SSO, fine-grained access, audit logs, more drivers) are in paid editions. For serious enterprise use, evaluate commercial tier.
- **SSH tunnels preferred for DB access**: don't expose production DB ports directly to CloudBeaver network. Use SSH tunnels defined per-connection — CloudBeaver supports this natively.
- **Read-only DB users for exploration**: create a `readonly` DB user + give CloudBeaver users only that connection for read queries. Prevents accidental `DELETE FROM users` moments.
- **Security patch cadence matters**: recent changelogs (2026-04 and earlier) show library CVEs being fixed frequently (axios, lodash, vite, happy-dom, picomatch, flatted). Pin to current version + upgrade regularly.
- **Docker image size**: JVM + drivers = large. ~1 GB image. Expected.
- **Session management**: web UI, sessions on H2. Timeout behavior configurable; check current defaults.
- **Export = data leak risk**: users can export entire tables. If you're worried about data exfiltration, restrict export or audit via commercial edition.
- **Data editor saves to DB**: unlike DBeaver Desktop where you control commit explicitly, CloudBeaver's data editor behavior is more immediate. Check current UX — train users + use read-only users to avoid accidents.
- **Not a replacement for pgAdmin/phpMyAdmin for admin tasks**: CloudBeaver focuses on data access + SQL editing. Deep admin tasks (tablespace management, replication setup) are DB-specific tools' territory.
- **License**: **Apache-2.0** (Community Edition). Commercial editions are proprietary.
- **Project health**: DBeaver Corp — commercial company; funded + stable; active CE development.
- **Alternatives worth knowing:**
  - **DBeaver Desktop** — same team; desktop app (Eclipse-based)
  - **phpMyAdmin** — MySQL/MariaDB-only; PHP; extremely widespread
  - **pgAdmin** — PostgreSQL-only; official Postgres tool
  - **Adminer** — single-file PHP DB admin; minimalist
  - **Sqlpad** — multi-DB SQL notebook
  - **Redash / Metabase / Superset** — BI/visualization; read-mostly
  - **Mathesar** (batch 75) — Postgres-native spreadsheet UI; non-technical users
  - **Beekeeper Studio** — desktop; commercial + FOSS editions
  - **TablePlus** — desktop; commercial
  - **Choose CloudBeaver if:** web-hosted multi-DB admin + SQL editor + team access.
  - **Choose DBeaver Desktop if:** one developer + don't want to host a server.
  - **Choose Mathesar if:** non-technical users + Postgres-only.

## Links

- Repo: <https://github.com/dbeaver/cloudbeaver>
- Wiki: <https://github.com/dbeaver/cloudbeaver/wiki>
- Deployment: <https://github.com/dbeaver/cloudbeaver/wiki/CloudBeaver-Deployment>
- Docker Hub: <https://hub.docker.com/r/dbeaver/cloudbeaver>
- Demo: <https://demo.cloudbeaver.io>
- Releases: <https://github.com/dbeaver/cloudbeaver/releases>
- DBeaver Desktop: <https://dbeaver.io>
- DBeaver Corp: <https://dbeaver.com>
- CloudBeaver Team/Enterprise: <https://dbeaver.com/cloudbeaver>
- Mathesar (alt, batch 75): <https://github.com/mathesar-foundation/mathesar>
- phpMyAdmin (alt): <https://www.phpmyadmin.net>
- pgAdmin (alt): <https://www.pgadmin.org>
