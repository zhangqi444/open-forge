---
name: pgAdmin 4
description: "Official administration and development web platform for PostgreSQL. Python (Flask) + React + PostgreSQL-side integration. Web application OR Electron desktop runtime. The canonical Postgres management GUI. PostgreSQL License."
---

# pgAdmin 4

pgAdmin 4 is **"the canonical Postgres management GUI"** — a rewrite of the legendary pgAdmin3 desktop tool as a modern Python/Flask + React web application. Runs either deployed as a web app (browse to pgAdmin, connect to multiple Postgres servers) or as a standalone desktop (Electron-wrapped Python process). Maintained by the PostgreSQL Global Development Group — official + authoritative. When you need SQL editor + schema browser + backup/restore dialogs + query plan visualizer + server-side dashboards for Postgres, pgAdmin is the default answer.

Built + maintained by the **PostgreSQL Global Development Group (PGDG)** via the pgadmin-org project. **License: PostgreSQL License** (very permissive — Postgres's own license; BSD/MIT-style). **Institutional-stewardship-tier** — part of the official Postgres ecosystem.

Use cases: (a) **DBA administration** — create users, grant roles, manage extensions, vacuum/analyze, monitor (b) **query / SQL editor** with syntax highlighting + EXPLAIN plan visualizer (c) **schema design + data editing** via grid-style UI (d) **backup / restore** wizard around `pg_dump` / `pg_restore` (e) **multi-server dashboard** — manage prod + staging + dev from one UI (f) **dev-onboarding tool** — visual introduction to Postgres for team members who prefer GUIs.

Features:

- **SQL editor** + query results grid + EXPLAIN + pgAdmin's graphical EXPLAIN
- **Object browser** — schemas, tables, indexes, functions, triggers, extensions
- **Data editor** — grid-view CRUD
- **Backup / restore** — wrappers around pg_dump / pg_restore
- **Import / export** — CSV / binary / SQL
- **Job scheduler** integration (pgAgent)
- **Server-side dashboards** — activity, locks, transactions
- **Multi-server** — connect to many PG instances from one pgAdmin
- **User-session sharing** (with care — see gotchas)
- **Query tool keyboard shortcuts** + macros
- **Cloud deployment** — Docker, Kubernetes, AWS RDS connection support
- **Desktop mode** — Electron runtime for single-user local use
- **Authentication**: password + LDAP + OAuth2/OIDC + AzureAD + Kerberos + header-based

- Upstream repo: <https://github.com/pgadmin-org/pgadmin4>
- Homepage: <https://www.pgadmin.org>
- Docs: <https://www.pgadmin.org/docs/>
- Download: <https://www.pgadmin.org/download/>
- Docker: <https://hub.docker.com/r/dpage/pgadmin4/>
- Issue tracker: <https://github.com/pgadmin-org/pgadmin4/issues>
- Mailing list: <https://www.postgresql.org/list/pgadmin-support/>

## Architecture in one minute

- **Python 3.9+** with **Flask**
- **ReactJS + HTML5/CSS** — frontend
- **Electron** — optional desktop runtime mode
- **Server-side**: web deployment uses WSGI (gunicorn / uwsgi); desktop uses bundled Python
- **SQLite or Postgres** — pgAdmin's own state (user accounts, saved queries, connection definitions)
- **Resource**: moderate — 200-500MB RAM; more with many concurrent users / large query results
- **Port 80/443** via web server

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker (web)**   | **`dpage/pgadmin4:latest`**                                     | **Easiest self-host**                                                              |
| Native packages    | Debian/Ubuntu/Fedora/RHEL via pgAdmin apt/yum repos                       | For bare-metal                                                                                   |
| Desktop (Electron) | macOS/Win/Linux downloads                                                          | Single-user local                                                                          |
| Python pip         | `pip install pgadmin4` (in venv)                                                                   | For embedded / CI                                                                                                 |
| Kubernetes         | Helm charts (community) + straightforward Docker deployment                                                                              | Production                                                                                                                |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `pgadmin.example.com`                                       | URL          | TLS MANDATORY                                                                                    |
| Initial admin        | `PGADMIN_DEFAULT_EMAIL` + `PGADMIN_DEFAULT_PASSWORD`                           | Bootstrap    | **Strong password**                                                                                    |
| Server definitions   | Hostname, port, DB, user for each Postgres you manage                   | Per-server   | Stored in pgAdmin's DB                                                                                    |
| Backend DB (opt)     | SQLite (default) or external Postgres for pgAdmin's state                                   | Storage      | Postgres recommended for team-use                                                                                                      |
| SSL certs for target PGs                       | CA + client cert + client key (if mutual TLS)                                                                                                    | Security     | Per-server                                                                                                                                              |
| Auth provider (opt)                       | LDAP / OIDC / OAuth2 for team SSO                                                                                                                                                      | Auth         | Team/production setups                                                                                                                                                                                    |

## Install via Docker

```yaml
services:
  pgadmin:
    image: dpage/pgadmin4:latest    # **pin version** in prod
    restart: unless-stopped
    environment:
      - PGADMIN_DEFAULT_EMAIL=admin@example.com
      - PGADMIN_DEFAULT_PASSWORD=${PGADMIN_ADMIN_PASSWORD}
      - PGADMIN_CONFIG_MASTER_PASSWORD_REQUIRED=True   # protects stored server passwords
    volumes:
      - ./pgadmin-data:/var/lib/pgadmin
    ports: ["8080:80"]
```

## First boot

1. Browse `https://pgadmin.example.com`
2. Log in with initial admin email/password
3. Set **Master Password** — protects stored server passwords (encryption-at-rest for saved connection secrets)
4. Add Server → Connection → hostname / port / maintenance DB / username / password
5. Save; verify connection opens Object Browser tree
6. Open Query Tool → run a test query
7. For team use: configure OIDC/LDAP SSO; create team accounts with scoped roles
8. Put behind TLS reverse proxy + optional SSO-gate
9. Back up `/var/lib/pgadmin`

## Data & config layout

- `/var/lib/pgadmin/pgadmin4.db` (SQLite, default) — pgAdmin's own state
- User accounts (email/password or SSO-linked)
- Saved server definitions (including ENCRYPTED server passwords IF master password set)
- Saved queries + macros
- Audit logs

## Backup

```sh
docker compose stop pgadmin
sudo tar czf pgadmin-$(date +%F).tgz pgadmin-data/
docker compose start pgadmin
```

Master password needed to decrypt stored server passwords on restore.

## Upgrade

1. Releases: <https://www.pgadmin.org/download/>. Regular cadence; aligned with Postgres major releases + feature development.
2. Docker: pull latest + restart.
3. DB schema migrations run on startup.
4. **Read release notes** — occasional breaking changes in Docker env var handling or configuration.

## Gotchas

- **pgAdmin = YOUR DATABASE ACCESS PANEL** → if compromised, attacker has direct access to every Postgres server you've configured in pgAdmin. **22nd tool in hub-of-credentials family, crown-jewel Tier 2**.
  - Defense:
    - **MASTER PASSWORD MANDATORY** — encrypts stored server passwords at rest (`PGADMIN_CONFIG_MASTER_PASSWORD_REQUIRED=True`)
    - TLS MANDATORY — never expose pgAdmin over HTTP on a network path where traffic could be intercepted
    - SSO (OIDC/LDAP) for team use; MFA at the IdP
    - **Not internet-exposed unless behind VPN / ZTNA** (Octelium, Tailscale, Cloudflare Access)
    - Audit log review if multi-user
- **MASTER PASSWORD IMMUTABILITY**: if you change it, previously-stored server passwords may need re-entry. Lose the master password = lose access to stored server passwords (must re-enter manually). **18th tool in immutability-of-secrets family.**
- **Postgres superuser access in pgAdmin = game over scope**: if you save Postgres superuser credentials in pgAdmin, pgAdmin effectively = superuser on that cluster. **Principle of least privilege**: save only specific role credentials (e.g., `readonly_dev`) per purpose; use separate pgAdmin accounts for admin vs dev-readonly.
- **Query-execution audit trail**: pgAdmin logs queries run via the Query Tool to pgAdmin's own log. For compliance/audit, ensure logs are forwarded to your SIEM + retained per policy.
- **Connection-pooling awareness**: each pgAdmin session opens connections to the target Postgres. For busy multi-user pgAdmin instances connected to a small Postgres, you can exhaust `max_connections` on the target. Budget connections on target Postgres accordingly. Consider PgBouncer in front of target Postgres.
- **Desktop mode vs server mode**: desktop is single-user on your workstation (Electron wrapper); server mode supports multi-user. **Don't try to run server-mode with desktop-install** — different deployment paths.
- **PGADMIN_DEFAULT_PASSWORD ENV VAR SECURITY**: initial password set via env var means it's in your Docker compose file + process args. **Remove it after first boot** + use in-app password changes. Or use Docker secrets / external secret manager.
- **Backup stored server passwords**: the encrypted server passwords in pgAdmin's SQLite are bound to the master password. If you lose master password = server passwords un-decryptable = you must re-enter them manually when restoring.
- **BROWSER-BASED SQL EXECUTION** means SQL injection risks apply to pgAdmin's query tool path itself. pgAdmin has had XSS advisories historically; keep current. The official pgadmin-org project is responsive to security reports.
- **pgAgent** (separate component) extends pgAdmin for scheduled-job execution. Adds privilege (pgAgent runs as a separate service on a DB server). Optional; add only if needed.
- **LARGE RESULT SETS**: pgAdmin's Query Tool can be slow when displaying huge result sets in the grid. For big exports, use pg_dump / COPY directly.
- **BACKUP-RESTORE wizards** in pgAdmin wrap pg_dump/pg_restore. For production backup workflows, **use pg_dump directly in cron** rather than via pgAdmin GUI click-through (reliability + automation + logging).
- **Kerberos / AD auth** supported — useful in enterprise environments; complex to configure correctly.
- **PostgreSQL License** = very permissive (BSD/MIT-style). **7th tool in permissive-license-ecosystem-asset family** (adds to Rustpad 85, IronCalc 86, yarr 87, Guacamole 87, Octelium 88 dual, Homarr 89). Great for ecosystem integration + commercial embedding.
- **Institutional-stewardship** — PGDG = Postgres Global Development Group, the same org behind Postgres itself. **11th tool in institutional-stewardship family** (ASF 87, NLnet 80, Deciso 80, TryGhost, Codeberg e.V., LinuxServer.io, Element, Deuxfleurs 90). Official-ecosystem signal = low bus-factor concern.
- **No commercial-tier**: pgAdmin is purely community-funded/PGDG-maintained. Optional corporate sponsorship via PGDG exists. **"services-around-OSS"** tier (per commercial-tier taxonomy batch 89) — paid commercial Postgres support vendors (EDB, Crunchy Data, etc.) offer paid pgAdmin assistance as part of Postgres packages.
- **Alternatives worth knowing** (Postgres-GUI space):
  - **DBeaver (Community)** — Java desktop + Apache-2; multi-DB (not Postgres-specific); excellent
  - **TablePlus** — commercial desktop
  - **DataGrip** (JetBrains) — commercial desktop; excellent
  - **Beekeeper Studio** — open-core Electron
  - **Postico** (Mac only) — commercial
  - **Adminer** (PHP, multi-DB) — single-file web admin tool
  - **phpPgAdmin** — legacy PHP-based
  - **psql** (CLI) — always available; fastest for DBAs
  - **PGcli** — modern CLI with auto-complete
  - **Choose pgAdmin if:** you want Postgres-specific + official + web or desktop + multi-user-capable + permissive-license + free.
  - **Choose DBeaver if:** you want multi-DB + desktop + excellent Postgres support.
  - **Choose DataGrip if:** you want best-in-class polished desktop + paid acceptable.
  - **Choose Adminer if:** you want minimal single-file PHP + multi-DB.
- **Project health**: part of Postgres ecosystem; multi-maintainer; regular releases aligned with Postgres; active issue tracker; mailing list support. Institutional-grade.

## Links

- Repo: <https://github.com/pgadmin-org/pgadmin4>
- Homepage: <https://www.pgadmin.org>
- Docs: <https://www.pgadmin.org/docs/>
- Downloads: <https://www.pgadmin.org/download/>
- Docker: <https://hub.docker.com/r/dpage/pgadmin4/>
- Mailing list: <https://www.postgresql.org/list/pgadmin-support/>
- DBeaver (alt): <https://dbeaver.io>
- Adminer (alt): <https://www.adminer.org>
- PGcli (alt, CLI): <https://www.pgcli.com>
- PostgreSQL License: <https://opensource.org/license/postgresql>
- PgBouncer (connection pooler): <https://www.pgbouncer.org>
