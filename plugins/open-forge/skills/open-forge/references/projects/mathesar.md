---
name: Mathesar
description: "Spreadsheet-like web UI for PostgreSQL — view, edit, query, and collaborate on Postgres data without SQL. Native Postgres roles/permissions, direct schema access (no abstraction layer), forms, data explorer. Self-hosted. 501(c)(3) nonprofit. GPLv3."
---

# Mathesar

Mathesar is **"spreadsheet UI over real Postgres"** — a self-hosted web app that lets non-technical users view, edit, query, and collaborate on existing PostgreSQL databases with a familiar spreadsheet feel, **without introducing a new abstraction layer** (unlike Airtable/Baserow/NocoDB which create their own data model). Mathesar works **directly with native Postgres schemas, tables, constraints, foreign keys, and data types**. A collaboration in Mathesar IS a real Postgres permission grant.

Stewarded by **Mathesar Foundation** — a **501(c)(3) US nonprofit** — an unusual and significant governance model for a data tool. Currently **public beta** (per upstream: stable enough for production; public/stable status aspirational).

Positioning vs alternatives:
- **Airtable / Baserow / NocoDB** — create their own data model; Postgres (if used) is storage
- **Mathesar** — **Postgres IS the data model**; Mathesar is a UI layer
- **Consequence**: Mathesar's data integrates natively with any other Postgres tool (BI, backup, migration, other apps)

Features:

- **Direct Postgres**: connect existing DB OR create new
- **Postgres-based access control** — uses native roles + privileges (not its own layer)
- **Spreadsheet-like table view** — view/edit/create/delete rows
- **Filter, sort, group** with instant feedback
- **Data Explorer** — visual query builder (no SQL required)
- **Forms** — build + share data-entry forms; submissions become rows
- **Schema migrations** — UI-driven column moves, type changes, etc.
- **Custom data types** — emails, URLs, validated at DB level
- **Foreign keys = "Relationships" in UI** — navigate related records
- **Import / export** CSV + more
- **Multi-user collaboration** — native Postgres roles

- Upstream repo: <https://github.com/mathesar-foundation/mathesar>
- Website: <https://mathesar.org>
- Docs: <https://docs.mathesar.org>
- Docs install: <https://docs.mathesar.org/?ref=github-readme-installing>
- Matrix: <https://wiki.mathesar.org/community/matrix/>
- Discord: <https://discord.gg/enaKqGn5xx>
- Contributor Wiki: <https://wiki.mathesar.org/>
- Roadmap: <https://github.com/orgs/mathesar-foundation/projects/2>
- Foundation: <https://mathesar.org> (nonprofit steward)

## Architecture in one minute

- **Django (Python)** backend + **Svelte** frontend
- **Runs alongside Postgres** — connects via libpq
- **Mathesar's own internal DB** (for user accounts + connections) — typically Postgres
- **User-data DBs** are YOUR Postgres instances (existing or new)
- **Access control: Postgres roles** — when user X is granted access to table Y in Mathesar, that's a real `GRANT` statement
- **Resource**: 500 MB - 1 GB RAM depending on workload

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Single VM          | **Docker Compose** (app + internal Postgres)                       | **Upstream-recommended**                                                           |
| Kubernetes         | Community manifests                                                        | Works                                                                                      |
| Docker + existing Postgres | Point Mathesar at your existing DB                                             | Common pattern                                                                                             |
| Python manual install | Poetry + Django; for dev                                                                               | Not typical for prod                                                                                                   |

## Inputs to collect

| Input                | Example                                                 | Phase        | Notes                                                                    |
| -------------------- | ------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `data.example.com`                                          | URL          | TLS via reverse proxy                                                            |
| Mathesar internal DB | Postgres instance                                                 | DB           | Recommended separate DB for user accounts                                                |
| User-data DBs        | your existing Postgres DBs                                                  | Data         | Can connect multiple                                                                                 |
| Admin                | first-run creates                                                                  | Bootstrap    | Strong password + MFA if possible                                                                                 |
| Secret key           | `SECRET_KEY` env (Django)                                                                     | Crypto       | Required; 50+ random chars                                                                                     |

## Install via Docker Compose

Follow <https://docs.mathesar.org/installation/docker-compose/> — concrete current instructions live there.

Key pieces:

```yaml
services:
  mathesar:
    image: mathesar/mathesar:latest                      # pin in prod
    ports:
      - "8000:8000"
    environment:
      SECRET_KEY: "50_plus_random_chars"
      ALLOWED_HOSTS: "data.example.com,localhost"
      DJANGO_DATABASE_URL: postgresql://mathesar:pw@mathesar-db:5432/mathesar_django
      DATABASES: "mathesar_django"
    volumes:
      - ./data:/code/mathesar_data
    depends_on:
      - mathesar-db

  mathesar-db:
    image: postgres:16
    environment:
      POSTGRES_USER: mathesar
      POSTGRES_PASSWORD: CHANGE_ME
      POSTGRES_DB: mathesar_django
    volumes:
      - ./internal-db:/var/lib/postgresql/data
```

Browse `https://data.example.com/` → first-run setup → admin creation.

## First boot

1. Complete first-run wizard → create admin + superuser
2. Connect a user-data Postgres DB → Mathesar introspects schemas
3. Create a test table via UI → verify real Postgres table appears
4. Add a collaborator → Mathesar creates a Postgres role → inspect via `\du` in psql
5. Test import of CSV → becomes a real table with proper types
6. Build a data explorer → verify SQL produced is what you expect
7. Configure TLS via reverse proxy
8. Back up BOTH the internal DB and any user-data DBs

## Data & config layout

- **Internal DB** (`mathesar_django`) — user accounts, permissions metadata, app state
- **User-data DBs** — your actual data; UNMODIFIED by Mathesar except via user actions
- Mathesar uses real Postgres features (schemas, FK, constraints, custom types) — no hidden "metadata tables" hijacking your schema
- `./data/` — uploaded files, temp CSVs

## Backup

```sh
# Internal DB
pg_dump -U mathesar mathesar_django > mathesar-internal-$(date +%F).sql
# User-data DB(s) — your existing backup strategy continues to work
pg_dump -U youruser yourdb > yourdb-$(date +%F).sql
```

**Key property**: your user-data DBs remain independently backup-able via standard Postgres tooling. Mathesar isn't a wrapper that must be backed up together. That's a major architectural win.

## Upgrade

1. Releases: <https://github.com/mathesar-foundation/mathesar/releases>. Public beta — expect cadence + breaking changes still possible.
2. **Back up internal DB before every major version.**
3. Follow migration docs: <https://docs.mathesar.org/>.
4. User-data DBs are untouched by app upgrades — but new features may install new Postgres extensions (review release notes).

## Gotchas

- **Public beta, not yet 1.0 Public.** Upstream explicitly states: currently **public beta** (stable enough for production) → public stage is future. Don't assume API/URL stability across versions until 1.0.
- **Postgres IS the data model.** This is Mathesar's differentiator AND constraint. Your data looks like real Postgres; other Postgres tools (psql, pgAdmin, BI tools, ORMs) all work natively. But **Mathesar doesn't abstract Postgres**: if Postgres can't do it, Mathesar can't do it.
- **Mathesar modifies your schema.** When users add columns / change types / add constraints through Mathesar, those are **real `ALTER TABLE` statements**. Great for transparency, scary for "don't let business users touch production." Use separate DB roles scope accordingly.
- **Permissions ARE Postgres roles.** Adding a collaborator creates a Postgres user. Database administrators: you'll see roles like `mathesar_user_alice` appearing via `\du`. Plan Postgres role naming conventions up front.
- **Postgres version compatibility**: check docs for supported Postgres versions. Some features depend on recent Postgres versions (custom types, generated columns, etc.).
- **Foundation-stewarded (501(c)(3) US nonprofit)**: unusual, positive governance signal. No single company owns this. Compare to Zammad Foundation (batch 71). Foundations mitigate corporate-acquisition-fork risk (OpenCloud pattern, batch 74).
- **No offline mode**: Mathesar is server-backed; not Excel-replacement-on-your-laptop.
- **Access to user-data DB**: Mathesar's Postgres connection for the user-data DB is a single credential; it performs operations AS itself, then grants to end-user roles. Means: Mathesar's connection user is highly privileged. Lock that down (network ACLs; not internet-reachable; etc.).
- **Forms = public data entry**: form URLs are often shared broadly. Rate-limit at reverse proxy; CAPTCHA if needed; validate carefully.
- **Import discipline**: CSV imports infer types. Inspect before committing. Large imports can time out.
- **Performance at scale**: Mathesar is tied to Postgres performance. Proper indexes on user-data DB matter. 10M-row tables work but need DB tuning.
- **No mobile app**: responsive web only.
- **Not a replacement for BI tools**: for heavy analytics use Metabase/Superset/Redash pointed at the same Postgres.
- **Not an OLTP app builder**: if you want to build a custom app with business logic, use a framework (Django/Rails/Supabase). Mathesar is data exploration + light CRUD.
- **License**: **GPLv3** (verify in LICENSE). Foundation governance + GPL combo = strong community-oriented stack.
- **Alternatives worth knowing:**
  - **Airtable** (commercial SaaS) — different data model; different philosophy
  - **Baserow / NocoDB** (self-hosted) — create their own data model with Postgres backend
  - **Supabase** (self-hostable) — Postgres-native BaaS; table editor + APIs + auth
  - **pgAdmin / DBeaver / phpPgAdmin** — DB admin tools; more technical; no forms/collab
  - **Metabase / Redash / Apache Superset** — BI/analytics over Postgres; read-mostly
  - **Retool / Appsmith / Budibase** — app builders over databases
  - **Postgres REST (PostgREST) + custom UI** — DIY
  - **Choose Mathesar if:** you want a Postgres-native spreadsheet UI for non-technical users + Postgres-integrated permissions + no new data model.
  - **Choose Baserow/NocoDB if:** you want a new Airtable-like DB + don't care about Postgres-native permissions.
  - **Choose Supabase if:** app-building-over-Postgres + auth + APIs.

## Links

- Repo: <https://github.com/mathesar-foundation/mathesar>
- Website: <https://mathesar.org>
- Docs: <https://docs.mathesar.org>
- Install docs: <https://docs.mathesar.org/installation/docker-compose/>
- Matrix: <https://wiki.mathesar.org/community/matrix/>
- Discord: <https://discord.gg/enaKqGn5xx>
- Wiki: <https://wiki.mathesar.org/>
- Roadmap: <https://github.com/orgs/mathesar-foundation/projects/2>
- Releases: <https://github.com/mathesar-foundation/mathesar/releases>
- Docker Hub: <https://hub.docker.com/r/mathesar/mathesar>
- Baserow (alt): <https://baserow.io>
- NocoDB (alt): <https://www.nocodb.com>
- Supabase (alt): <https://supabase.com>
- Metabase (BI alt): <https://www.metabase.com>
