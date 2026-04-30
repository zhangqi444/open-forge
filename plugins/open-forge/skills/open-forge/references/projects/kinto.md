---
name: Kinto
description: "Minimalist JSON storage service with sync + sharing — Python + PostgreSQL. REST API for storing schemaless JSON documents, per-user permissions, Kinto-as-a-Service pattern. Originally from Mozilla; ongoing community stewardship. Apache-2.0."
---

# Kinto

Kinto is **"a tiny self-hostable Parse / Firebase Firestore / CouchDB-style JSON API"** — a minimalist REST service for storing JSON documents organized into **buckets → collections → records**, with **per-record permissions + shared access + last-modified sync + change log + paginated queries**. Originally designed + maintained by **Mozilla** for projects like Firefox Sync, Firefox Accounts, Firefox Remote Settings (used to deliver config to millions of Firefox browsers). Now **stewarded by a community of active contributors**; still Apache-2.0; still actively maintained on GitHub.

Use cases: **"I need a fast JSON API for my app and don't want to wire a framework"** — remote-settings distribution, lightweight sync backend for mobile/JS apps, configuration service, feature-flag storage, form-data persistence.

Features:

- **JSON documents** — schemaless (or optional JSON Schema validation per collection)
- **REST API** with HTTP caching (ETag / If-Match / conditional updates)
- **Per-record permissions** — owner + shared-with + roles
- **Groups** — grant permissions to groups of users
- **Sync** — `_since` parameter returns changes since timestamp; consistent offline-first
- **Pluggable auth** — basic-auth / OpenID Connect / Mozilla FxA / LDAP / custom
- **Backends**: in-memory (dev), **PostgreSQL 9.5+** (production), pluggable
- **Plugins** — history, quotas, schema validation, signing, default_bucket, etc.
- **Python API client** (`kinto-http`) + JS client
- **Python 3.10+**
- **Kinto-Admin UI** — separate web UI for exploring data

- Upstream repo: <https://github.com/Kinto/kinto>
- Documentation: <https://kinto.readthedocs.io/>
- Tutorial: <https://kinto.readthedocs.io/en/latest/tutorials/first-steps.html>
- Docker Hub: <https://hub.docker.com/r/kinto/kinto-server>
- PyPI: <https://pypi.python.org/pypi/kinto>
- Kinto-Admin: <https://github.com/Kinto/kinto-admin>
- Gitter: <https://gitter.im/Kinto/kinto>
- Code of Conduct: <https://github.com/Kinto/kinto/blob/main/.github/CODE_OF_CONDUCT.md>

## Architecture in one minute

- **Python 3.10+** Pyramid web app
- **PostgreSQL** (prod) or in-memory (dev) backend
- **Pluggable auth + cache + storage + permissions backends**
- **Data model**: Server → Bucket → Collection → Record (4-level hierarchy)
- **Resource**: small — 100-300 MB RAM per worker

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Docker             | **`kinto/kinto-server`** + Postgres                                | **Upstream-primary**                                                               |
| pip                | `pip install kinto` + gunicorn/uwsgi                                          | Traditional Python deploy                                                                  |
| PostgreSQL         | Mandatory for prod — in-memory is dev-only                                          | No SQLite support                                                                                      |
| Kubernetes         | Standard Python deploy + PG                                                                        | Works                                                                                                  |

## Inputs to collect

| Input                | Example                                                        | Phase        | Notes                                                                    |
| -------------------- | -------------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `kinto.example.com`                                                | URL          | TLS via reverse proxy                                                            |
| PostgreSQL           | PG 9.5+                                                                   | DB           | Production backend                                                                          |
| Auth backend         | basic-auth (dev) / OIDC (prod) / FxA / LDAP                                       | Auth         | **Default is open access + basic auth — LOCK DOWN**                                                |
| Admin user           | `kinto.permissions.authenticated_account_create_bucket = True` is default — anyone can create buckets                       | Bootstrap    | Configure permissions explicitly before exposing                                                                                   |
| Plugins              | history, quotas, default_bucket, signing — pick per use case                                           | Config       | Enable via `kinto.includes`                                                                                                        |
| SMTP (opt)           | for user signup                                                                           | Email        | If using accounts backend                                                                                                            |

## Install via Docker Compose

```yaml
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_USER: kinto
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: kinto
    volumes: [pg_data:/var/lib/postgresql/data]

  kinto:
    image: kinto/kinto-server:latest                   # pin version in prod
    depends_on: [postgres]
    ports: ["8888:8888"]
    environment:
      KINTO_INI: /etc/kinto/kinto.ini
    volumes:
      - ./kinto.ini:/etc/kinto/kinto.ini:ro

volumes:
  pg_data:
```

`kinto.ini` from upstream template → customize backend, permissions, plugins.

## First boot

1. Create DB schema: `kinto migrate`
2. Create first admin account (varies per auth backend)
3. Test: `curl -u alice:pass http://<host>:8888/v1/buckets/my-bucket/collections/items/records`
4. Explore via Kinto-Admin UI: <https://github.com/Kinto/kinto-admin>
5. Lock down permissions: who can create buckets? default `Everybody`? — typically restrict.
6. Enable `history` plugin if you want change tracking; `quotas` for limits
7. Put behind TLS

## Data & config layout

- PostgreSQL — buckets, collections, records, permissions, history (if plugin enabled)
- `kinto.ini` — config (secrets, plugins, auth, backend URIs)
- No file storage by Kinto itself (records are JSON in PG)

## Backup

```sh
pg_dump -Fc -U kinto kinto > kinto-$(date +%F).dump
sudo tar czf kinto-config-$(date +%F).tgz /etc/kinto/
```

## Upgrade

1. Releases: <https://github.com/Kinto/kinto/releases>. Sustained cadence.
2. Read CHANGELOG for schema migrations.
3. `kinto migrate` applies pending schema changes.
4. **Back up PG first.**

## Gotchas

- **Mozilla-origin project; now community-stewarded.** Kinto was born at Mozilla (used to deliver Firefox Remote Settings — config for millions of browsers). Mozilla has reduced direct investment; the project is actively maintained by a community of contributors. Production-ready, but know the provenance history.
- **Default permissions can be permissive.** Depending on config, unauthenticated users may be able to create buckets OR authenticated users may be over-permissioned. Review `kinto.ini` permissions before exposing. Specifically: `kinto.bucket_create_principals`, `kinto.account_create_principals`.
- **PostgreSQL is the ONLY production backend.** In-memory backend is dev-only (loses data on restart). No SQLite production option.
- **Data model hierarchy** (Bucket → Collection → Record) is deliberate — buckets isolate tenants/apps; collections group records; records are documents. Plan your hierarchy intentionally; migrating data across buckets after initial use is awkward.
- **Kinto-Admin is a separate app** — you need to deploy + configure it for the web UI. Default Kinto install is API-only.
- **ETag + If-Match** are first-class — use them to avoid lost-update races. Kinto's doc covers this well; follow the conventions.
- **Sync semantics**: `_since` gives you all changes since a cursor. Great for offline-first apps. But: caveat about tombstones (deleted records) — enable history/sync patterns carefully to avoid missing deletions.
- **Plugins-as-features**: history, quotas, schema-validation are opt-in plugins. Don't assume they're enabled by default. Explicitly include what you need.
- **Signing plugin** allows cryptographic signing of collections (e.g., for Firefox Remote Settings). Niche but powerful.
- **JSON Schema validation per collection** — optional; adds guardrails against bad client writes. Consider for production.
- **Not a full BaaS**: Kinto is storage + sync + permissions. No server-side code execution (no Cloud Functions / Lambda). For logic, pair with your own backend that calls Kinto.
- **Comparison to CouchDB**: CouchDB = full-featured multi-master replication + MapReduce views; heavier. Kinto = simpler API, Postgres-backed, no replication story beyond PG's.
- **Comparison to PocketBase**: PocketBase = realtime (websocket) + admin UI built-in + SQLite. Kinto = no realtime (polling), separate admin UI, Postgres. PocketBase simpler for single-developer; Kinto more deployable at scale.
- **Comparison to Supabase / Appwrite / Hasura / Directus**: modern BaaS with auth + UI + more features. Heavier but cover more surface. Kinto is the minimalist alternative.
- **Comparison to Firebase / Firestore**: commercial BaaS. Kinto is the self-hosted equivalent of pre-Firebase Parse.
- **License**: **Apache-2.0** — maximally permissive.
- **Project health**: community-stewardship post-Mozilla; sustained releases; mature API stability. Production-ready; niche positioning (minimalist JSON store).
- **Alternatives worth knowing:**
  - **PocketBase** — Go single-binary BaaS; SQLite; realtime; admin UI; great DX
  - **Supabase** — PG + realtime + auth + storage + functions; heavy
  - **Appwrite** — similar scope to Supabase
  - **CouchDB** — multi-master replication
  - **PouchDB + CouchDB** — offline-first JS story
  - **Directus** — PG-first headless CMS + API
  - **Hasura** — GraphQL over PG
  - **Parse Server** — OSS Parse continuation
  - **Choose Kinto if:** you want a minimalist JSON-store with Mozilla-grade history + per-record ACLs + sync-friendly API + Python stack.
  - **Choose PocketBase if:** solo dev + admin UI + SQLite + realtime matters.
  - **Choose Supabase if:** you want BaaS with SQL + realtime + storage.

## Links

- Repo: <https://github.com/Kinto/kinto>
- Docs: <https://kinto.readthedocs.io/>
- Tutorial: <https://kinto.readthedocs.io/en/latest/tutorials/first-steps.html>
- API reference: <https://docs.kinto-storage.org/en/stable/api/1.x/>
- Docker Hub: <https://hub.docker.com/r/kinto/kinto-server>
- PyPI: <https://pypi.python.org/pypi/kinto>
- Kinto-Admin UI: <https://github.com/Kinto/kinto-admin>
- Gitter: <https://gitter.im/Kinto/kinto>
- Code of Conduct: <https://github.com/Kinto/kinto/blob/main/.github/CODE_OF_CONDUCT.md>
- Releases: <https://github.com/Kinto/kinto/releases>
- PocketBase (alt): <https://pocketbase.io>
- Supabase (alt): <https://supabase.com>
- Appwrite (alt): <https://appwrite.io>
- CouchDB (alt): <https://couchdb.apache.org>
