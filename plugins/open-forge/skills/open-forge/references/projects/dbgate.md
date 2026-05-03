---
name: DbGate
description: "Cross-platform database admin UI — MySQL, Postgres, SQL Server, Oracle, MongoDB, Redis, SQLite, Cassandra, ClickHouse, DuckDB, and more. Runs as desktop (Electron) or web (Docker) app. Community GPL-3.0; Premium commercial for some advanced features."
---

# DbGate

DbGate is **a single database admin UI for every database you run** — MySQL, PostgreSQL, SQL Server, Oracle, MongoDB, Redis, SQLite, MariaDB, CockroachDB, ClickHouse, Apache Cassandra, DuckDB, Firebird, and (Premium) Amazon Redshift, CosmosDB, libSQL/Turso, Firestore. Browse tables, run queries, visual query designer, schema compare, ER diagram, import/export, chart visualization — all from one tool.

Comparable to DBeaver, HeidiSQL, phpMyAdmin/Adminer, DataGrip, or SQLTools — DbGate's differentiator is the **mix of multi-DB coverage + web-browser-accessible mode + strong MongoDB support in the same tool**.

Available as:

- **Desktop app** (Electron) — Windows, macOS, Linux
- **Web application** (Docker or npm) — browse from any browser; ops-team-friendly shared instance

Features:

- Browse data with Excel-like filters, multi-value filters
- Inline editing with SQL change-script preview (no "apply blindly")
- Edit schema, indexes, PK/FK
- **Schema compare + synchronize**
- **ER diagram**
- **Visual query designer** (no SQL knowledge required for common queries)
- SQL editor with completion + formatter
- **MongoDB** — JS script editor, JSON view, query perspectives (nested tables)
- **Redis** — tree view, script generation
- Archives — backup data to NDJSON locally
- Import/export CSV, Excel, JSON, NDJSON, XML, DBF
- **AI-powered database chat** (optional)
- Charts + GEO map export
- Plugin architecture (npm-distributed)

- Upstream repo: <https://github.com/dbgate/dbgate>
- Website: <https://dbgate.io>
- Docs: <https://docs.dbgate.io>
- Online demo: <https://demo.dbgate.org>
- Docker Hub: <https://hub.docker.com/r/dbgate/dbgate>
- NPM: <https://www.npmjs.com/package/dbgate-serve>
- Premium (commercial): <https://www.dbgate.io/purchase/premium/>

## Architecture in one minute

- **Frontend**: Svelte
- **Backend**: Node.js + Express + database connection drivers
- **Desktop**: Electron wrapping the same
- **Plugins**: npm packages with the `dbgateplugin` keyword
- **State**: saved connections + settings stored locally (desktop) or in the mounted volume (Docker)
- **Stateless against DBs**: DbGate just connects; it doesn't cache your target DB contents

## Compatible install methods

| Infra         | Runtime                                    | Notes                                                                      |
| ------------- | ------------------------------------------ | -------------------------------------------------------------------------- |
| Desktop       | **Electron app** (`.exe`/`.dmg`/`.AppImage`/`.deb`/snap) | **Simplest personal use**                                                      |
| Single VM     | **Docker (`dbgate/dbgate`)**                                 | Web UI for a team / bastion host                                                   |
| Node          | `dbgate-serve` npm package                                          | Run as a Node process behind a reverse proxy                                                 |
| Kubernetes    | Deploy Docker image; one replica recommended                              | Avoid horizontal scale; connection state is per-pod                                                          |
| Raspberry Pi  | arm64 Docker image works                                                          | Fine for home admin panel                                                                                            |

## Inputs to collect

| Input             | Example                        | Phase     | Notes                                                                |
| ----------------- | ------------------------------ | --------- | -------------------------------------------------------------------- |
| DB credentials    | per target DB                       | Config    | DbGate stores them (encrypted or plain depending on option)                    |
| Listen port       | `3000`                                 | Network   | For web/Docker                                                                           |
| Login password    | set via env var in Docker                    | Auth      | Don't expose DbGate publicly without login; has single-user password mode                       |
| User list         | multi-user mode                                      | Auth      | Premium feature; team deployments                                                                         |
| Connection file   | mounted volume                                             | Config    | Persists across container restarts                                                                                       |

## Install (Docker, web mode)

```yaml
services:
  dbgate:
    image: dbgate/dbgate:7                       # pin major
    container_name: dbgate
    restart: unless-stopped
    environment:
      # Optional: pre-define one connection
      CONNECTIONS: con1
      LABEL_con1: "Prod MySQL"
      SERVER_con1: mysql.example.internal
      USER_con1: dbgate
      PASSWORD_con1: <strong>
      PORT_con1: "3306"
      ENGINE_con1: mysql@dbgate-plugin-mysql
      # Enforce login
      LOGINS: admin
      LOGIN_PASSWORD_admin: <strong>
    volumes:
      - ./root.config:/root/.dbgate
    ports:
      - "3000:3000"
```

Front with Caddy/Traefik/Nginx for TLS. **Don't expose DbGate to the public internet without strong auth** — it's a direct pipe to your databases.

## Install (desktop)

Download from <https://dbgate.io/download/>. Double-click to install/run. Connections save to:
- Windows: `%AppData%\DbGate`
- macOS: `~/Library/Application Support/DbGate`
- Linux: `~/.config/dbgate` (or `~/.dbgate/` depending on packaging)

## First boot

1. Open DbGate → "New Connection"
2. Pick engine (MySQL / Postgres / MongoDB / ...), fill host/port/creds
3. Test → Save → connect
4. Left pane: schema tree. Right pane: tabs for queries / table views / designer / ER diagram
5. Try: open a table → inline edit a row → see "SQL script preview" before apply

## Data & config layout

- **Desktop**: `~/.dbgate/` (or OS-specific) holds saved connections, open-tab state, archives
- **Docker**: `/root/.dbgate/` — same content; persist via volume
- **Archives** (`.ndjson` backups) stored in the same data dir by default; can export elsewhere

## Backup (DbGate's own state)

```sh
# Connections + open tabs + archives
tar czf dbgate-config-$(date +%F).tgz -C ~/.dbgate .
```

Nothing critical (DbGate doesn't hold user data — it's a UI). Main loss = need to re-add connections.

## Upgrade

1. Releases: <https://github.com/dbgate/dbgate/releases>. Frequent.
2. Desktop: in-app auto-update (check "Help → Check for updates") or reinstall latest.
3. Docker: bump tag; `docker compose pull && up -d`.
4. Major-version bumps rarely break connection file compat; back up if worried.

## Community vs Premium

- **DbGate Community** (GPL-3.0): open source, most features including connecting to MySQL/Postgres/MSSQL/Oracle/MongoDB/Redis/SQLite/MariaDB/ClickHouse/Cassandra/DuckDB/Firebird.
- **DbGate Premium** (commercial): adds Amazon Redshift, CosmosDB, libSQL/Turso, Firestore; some advanced features.
- Both have same GPL UI codebase; Premium is a license key that unlocks Premium engines/features.
- **Most self-hosters are fine with Community.**

## Gotchas

- **Don't expose public without auth.** DbGate over the internet with default settings = credentialed DB access for anyone who finds the URL. Enforce LOGIN via env vars; put behind SSO / VPN / Tailscale for team use.
- **Connections stored on disk** — if it's the `CONNECTIONS` env-var auto-provisioning, passwords are in the env/config (encrypt at rest). If user-added via UI, they're in the data volume.
- **Web UI state is per-user** in desktop mode; in Docker web mode, state is shared across all users unless you use multi-user mode (Premium).
- **Long-running queries** — browser tab + DbGate backend hold the query; closing the tab may cancel or not depending on engine. Test before relying on "start query + close laptop."
- **Edit-table safety** — the "SQL change script preview" is the killer feature; always review it before applying. DbGate won't run destructive edits silently.
- **MongoDB + large collections** — tree view is paginated; for sharded / massive clusters, DbGate can be slower than Compass.
- **Redis** browsing — works well for KV exploration; not a replacement for dedicated Redis tooling for cluster ops.
- **Query designer** can't express every SQL construct — good for common joins + filters; fall back to SQL editor for CTEs, window functions, complex conditions.
- **AI chat feature** — requires OpenAI API key (or compatible); queries go to the LLM provider. Disable if sensitive schemas.
- **Snap package** (Linux) — DbGate on snap sometimes has FS-access quirks; native `.deb` or AppImage avoids.
- **Electron disk footprint** — ~200 MB per desktop install; acceptable for a power-user tool.
- **Plugin installs from npm** — internet access required to fetch new plugins at runtime.
- **Archives feature** — great for "dump a table to local NDJSON"; but not a replacement for real DB backup tooling (`pg_dump`, `mysqldump`, `mongodump`).
- **Multi-tab + multi-connection** — DbGate handles many concurrent connections well; watch RAM on workstation with 10+ heavy queries open.
- **License (Community)**: GPL-3.0 — distribute modifications under the same license.
- **Alternatives worth knowing:**
  - **DBeaver Community** — Java; arguably more features; heavier install; no first-class web mode (separate recipe)
  - **phpMyAdmin** — MySQL/MariaDB-only; PHP-based; ancient but ubiquitous (separate recipe — batch 57)
  - **Adminer** — single-PHP-file multi-DB admin; lighter than phpMyAdmin
  - **CloudBeaver** — DBeaver web edition; commercial + community
  - **pgAdmin** — Postgres-focused; official
  - **phpMyAdmin / phpPgAdmin / MongoExpress / RedisInsight** — per-DB tools
  - **HeidiSQL** (Windows) — MySQL + Postgres + MSSQL
  - **DataGrip** (JetBrains) — commercial; very polished
  - **TablePlus** — commercial; excellent UX
  - **Beekeeper Studio** — Electron; modern; MySQL/Postgres/SQLite/MSSQL/Redshift/SQL Anywhere/BigQuery
  - **Choose DbGate if:** you want one tool for many engines, web + desktop mode, and an inline editor with change-script preview.
  - **Choose DBeaver if:** you want the deepest feature set and don't mind Java.
  - **Choose Adminer if:** you want a single-file PHP drop-in.
  - **Choose Beekeeper if:** you want a polished modern Electron UX and engines DbGate doesn't cover.

## Links

- Repo: <https://github.com/dbgate/dbgate>
- Website: <https://dbgate.io>
- Docs: <https://docs.dbgate.io>
- Online demo: <https://demo.dbgate.org>
- Docker Hub: <https://hub.docker.com/r/dbgate/dbgate>
- Downloads: <https://dbgate.io/download/>
- Releases: <https://github.com/dbgate/dbgate/releases>
- NPM package: <https://www.npmjs.com/package/dbgate-serve>
- Scripting docs: <https://docs.dbgate.io/scripting>
- Plugin development: <https://docs.dbgate.io/plugin-development>
- Existing plugins on npm: <https://www.npmjs.com/search?q=keywords:dbgateplugin>
- Knowledge base: <https://github.com/dbgate/dbgate-knowledge-base>
- GitHub sponsors: <https://github.com/sponsors/dbgate>
- Premium purchase: <https://www.dbgate.io/purchase/premium/>
