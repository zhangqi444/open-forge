---
name: Saltcorn
description: "Extensible open-source no-code database app builder. PostgreSQL + Node.js + Express. Live plugin manager + Blockly + Craft.js + CodeMirror. Multitenant-capable. saltcorn org. Open Collective. Commercial hosted."
---

# Saltcorn

Saltcorn is **"Retool / Budibase — but OSS + no-code-friendly + Postgres-backed"** — an extensible open-source no-code database app builder. Build web + mobile database apps with flexible views, datatypes, layouts, actions. Single-instance OR multitenant. Online instance at saltcorn.com for trying.

Built + maintained by **saltcorn** org. **Open Collective** funding. License: check (typically permissive). Active CI.

Use cases: (a) **internal CRUD apps** — no-code (b) **small-biz line-of-business apps** (c) **rapid prototype for DB apps** (d) **Retool-replacement** — OSS (e) **citizen-developer tools** (f) **form + list + dashboard** builder (g) **multi-tenant SaaS-builder** (h) **departmental apps without IT backlog**.

Features (per README):

- **Flexible views** + **datatypes** + **layouts** + **actions**
- **Live plugin manager** — install plugins at runtime
- **Blockly** for visual logic
- **Craft.js** for drag-drop design
- **CodeMirror** for code edits
- **Multitenant** — tenant-per-subdomain
- **Postgres or SQLite** backend
- **Desktop + server + Docker**

- Upstream repo: <https://github.com/saltcorn/saltcorn>
- Website: <https://saltcorn.com>
- OpenCollective: <https://opencollective.com/saltcorn>
- Try hosted: <https://saltcorn.com/tenant/create>

## Architecture in one minute

- **Node.js + Express**
- **PostgreSQL** (multitenant) or **SQLite** (single-tenant)
- **live-plugin-manager** — runtime plugin loading
- **Craft.js + Blockly** in the UI
- **Resource**: moderate; grows with apps built
- **Port**: 3000 default

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker Compose** | App + Postgres                                                 | Primary for multi-tenant                                                                                    |
| **npm-install**    | `npm i -g @saltcorn/cli` + SQLite                                                                                      | Easy single-tenant                                                                                    |
| **Install script** | `npx saltcorn-install -y` on VM                                                                                        | Alt                                                                                   |
| **Desktop**        | CLI + SQLite                                                                                                           | Dev/try                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `*.saltcorn.example.com` (for multitenant)                  | URL          | Wildcard TLS                                                                                    |
| Admin creds          | First-boot                                                  | Bootstrap    |                                                                                    |
| PostgreSQL           | Multi-tenant                                                | DB           |                                                                                    |
| Plugin installs      | At runtime                                                  | Runtime      | Supply-chain risk                                                                                    |

## Install via CLI + SQLite (single-tenant)

```sh
npm config set prefix ~/.local
npm install -g @saltcorn/cli
export SQLITE_FILEPATH=~/saltcorn.sqlite
~/.local/bin/saltcorn reset-schema -f
~/.local/bin/saltcorn serve
```

Visit <http://localhost:3000>.

## Install via Docker (multi-tenant)

```yaml
services:
  db:
    image: postgres:17
    environment:
      POSTGRES_USER: saltcorn
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: saltcorn
    volumes: [pgdata:/var/lib/postgresql/data]

  saltcorn:
    image: saltcorn/saltcorn:latest        # **pin version**
    environment:
      SALTCORN_SESSION_SECRET: ${SESSION_SECRET}
      SALTCORN_MULTI_TENANT: "true"
      PGUSER: saltcorn
      PGPASSWORD: ${DB_PASSWORD}
      PGDATABASE: saltcorn
      PGHOST: db
    ports: ["3000:3000"]
    depends_on: [db]
    volumes:
      - ./saltcorn-data:/data

volumes:
  pgdata: {}
```

## First boot

1. Start
2. Create admin
3. Define first table + view
4. Try a plugin
5. For multi-tenant: verify subdomain routing works
6. Put behind TLS (wildcard cert for multi-tenant)

## Data & config layout

- PostgreSQL (or SQLite) — everything
- `/data/` — uploaded files, plugin cache

## Backup

```sh
# PG:
docker compose exec db pg_dump -U saltcorn saltcorn > saltcorn-$(date +%F).sql
# Uploads:
sudo tar czf saltcorn-uploads-$(date +%F).tgz saltcorn-data/
```

## Upgrade

1. Releases: <https://github.com/saltcorn/saltcorn/releases>
2. DB migrations auto on start
3. Breaking: review plugin compatibility

## Gotchas

- **147th HUB-OF-CREDENTIALS CROWN-JEWEL TIER 1 — APP-BUILDER + USER-DATA + PLUGIN-SUPPLY-CHAIN**:
  - Holds: all apps you built + all tenants' data + plugin code loaded at runtime
  - Multi-tenant = if compromised, ALL tenants' data exposed
  - Plugin runtime-loader = supply-chain risk
  - **147th tool in hub-of-credentials family — Tier 1 CROWN-JEWEL**
  - **NEW CROWN-JEWEL Tier 1 sub-category: "no-code-builder + runtime-plugin-loader + multi-tenant"** (1st — Saltcorn)
  - **CROWN-JEWEL Tier 1: 46 tools / 43 sub-categories**
- **LIVE-PLUGIN-MANAGER**:
  - Loads plugins at runtime
  - Supply-chain risk (install malicious plugin = RCE)
  - **Recipe convention: "runtime-plugin-loader-supply-chain-risk callout"**
  - **NEW recipe convention** (Saltcorn 1st formally) — HIGH-severity
  - **Plugin-API-architecture: 3 tools** (Wireflow+Reiverr+Saltcorn) 🎯 **3-TOOL MILESTONE**
- **MULTI-TENANT-ARCHITECTURE**:
  - Single instance serves many tenants
  - Tenant-isolation is CRITICAL
  - SQL-injection could cross tenants
  - **Recipe convention: "multi-tenant-isolation-discipline callout"**
  - **NEW recipe convention** (Saltcorn 1st formally)
  - **Multi-tenant-architecture: 2 tools** (Keila+Saltcorn) 🎯 **2-TOOL MILESTONE**
- **NO-CODE-MEANS-CITIZEN-DEVELOPERS**:
  - Users write apps with permissions implications
  - Bad app = data-leak, cross-tenant access
  - **Recipe convention: "citizen-developer-permission-review callout"**
  - **NEW recipe convention** (Saltcorn 1st formally)
- **WILDCARD-TLS-FOR-MULTI-TENANT**:
  - Subdomain-per-tenant = wildcard cert needed
  - **Recipe convention: "wildcard-TLS-for-tenant-subdomains callout"**
  - **NEW recipe convention** (Saltcorn 1st formally)
- **OPEN-COLLECTIVE-FUNDING**:
  - **Open-Collective-transparent-finances: 4 tools** (+Saltcorn) 🎯 **4-TOOL MILESTONE**
- **COMMERCIAL-HOSTED (saltcorn.com)**:
  - **Commercial-parallel-with-OSS-core: 12 tools** 🎯 **12-TOOL MILESTONE**
- **CRAFT.JS + BLOCKLY + CODEMIRROR**:
  - Substantial JS UI stack
  - **Recipe convention: "heavy-JS-UI-toolkit-stack neutral-signal"**
  - **NEW neutral-signal convention** (Saltcorn 1st formally)
- **INSTITUTIONAL-STEWARDSHIP**: saltcorn org + OpenCollective + commercial-parallel + active CI + website + multiple-install-methods. **133rd tool — OpenCollective-funded-commercial-parallel sub-tier**.
- **TRANSPARENT-MAINTENANCE**: active + CI + OpenCollective + website + multiple-install-methods + hosted-option. **139th tool in transparent-maintenance family.**
- **NO-CODE-CATEGORY:**
  - **Saltcorn** — PG + plugins; multi-tenant-capable
  - **Budibase** — modern-UI; more-polished
  - **NocoDB** — Airtable-clone; simpler
  - **Appsmith** — drag-drop internal apps
  - **ToolJet** — similar to Appsmith
- **ALTERNATIVES WORTH KNOWING:**
  - **Budibase** — if you want modern-UI + more-polished
  - **NocoDB** — if you want Airtable-feel
  - **Appsmith** — if you want internal-tools
  - **Choose Saltcorn if:** you want multi-tenant + live-plugins + PG-backed.
- **PROJECT HEALTH**: active + OpenCollective + commercial-parallel + multiple-install-options. Strong.

## Links

- Repo: <https://github.com/saltcorn/saltcorn>
- Website: <https://saltcorn.com>
- OpenCollective: <https://opencollective.com/saltcorn>
- Budibase (alt): <https://github.com/Budibase/budibase>
- NocoDB (alt): <https://github.com/nocodb/nocodb>
