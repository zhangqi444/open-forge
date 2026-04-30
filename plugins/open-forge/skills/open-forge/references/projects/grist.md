---
name: Grist
description: Self-hosted spreadsheet-database hybrid (Airtable/Excel alternative). Relational formulas + typed columns + Python in cells + charts + forms + access controls per column. Grist Community Edition = OSS core. Node.js + Python sandbox + SQLite. Apache-2.0.
---

# Grist

Grist is the rare "Airtable-alternative" that's actually good. It blends a spreadsheet's cell-level freedom with a relational database's integrity, then adds **Python in formulas** (yes, real Python), ACL at the column/row level, embeddable forms, and charts — all in one self-hostable Node.js app.

`grist-core` (this repo = **Grist Community Edition**) has everything you need to run a powerful server for hosting spreadsheets. Grist Inc. also runs a hosted commercial version (`getgrist.com`) with some additional enterprise features.

Features in the OSS:

- **Relational tables** — foreign keys, record references, joined views
- **Typed columns** — text, numeric, date, reference, attachment, choice, choice-list, etc.
- **Python formulas** — `$column` syntax; can call any pure Python function; full pandas-lite data model
- **Charts** — bar, line, pie, scatter, directly from table data
- **Forms** — publish a form → fills a table (like Google Forms but stored in your Grist)
- **Cards / dashboards** — multi-widget views
- **Row/column-level ACL** — per-user/per-group/conditional visibility
- **Granular share links** — share one table read-only, another read-write
- **Import** — CSV, XLSX, JSON, Google Sheets
- **Export** — CSV, XLSX, JSON, Grist's own format
- **API** — REST
- **Webhooks** — on record changes
- **gVisor sandbox** for Python formula execution (per-document isolation)
- **Templates** — pre-built docs: CRM, inventory, project tracker, D&D encounter tracker

Grist Inc.'s **commercial-only features** (not in `grist-core`):

- GristConnect (advanced external-data integration)
- Enterprise admin panel
- Azure back-end storage
- Audit log streaming
- Email notifications (for self-managed core there are workarounds)
- "Sign in with Grist" hosted SSO
- SCIM provisioning, OIDC, SAML (some OIDC/SAML is in core but labeled "experimental")

See "[Features not in grist-core](https://github.com/gristlabs/grist-core#features-not-in-grist-core)" for the current list.

- Upstream repo: <https://github.com/gristlabs/grist-core>
- Website: <https://getgrist.com>
- Docs: <https://support.getgrist.com>
- Self-managed guide: <https://support.getgrist.com/self-managed/>
- Docker Hub: <https://hub.docker.com/r/gristlabs/grist>
- Templates: <https://templates.getgrist.com>
- Online demo: <https://docs.getgrist.com>
- Desktop app: <https://github.com/gristlabs/grist-desktop>

## Architecture in one minute

- **`gristlabs/grist`** Docker image — Node.js HTTP server + Python formula sandbox + SQLite per-document storage
- Each **Grist "document"** = one SQLite file on disk (in `/persist`)
- **Sandbox options**:
  - Default: `unsandboxed` (runs Python in a subprocess, no isolation)
  - `gvisor` (recommended for multi-tenant) — kernel-level sandbox per document
  - `pyodide` (browser-side Python; some limitations)
- **Port 8484** inside container; map to whatever
- **Auth**: cookie-based, optional OIDC/SAML, optional "Sign in with Grist" hosted

## Compatible install methods

| Infra       | Runtime                                         | Notes                                                             |
| ----------- | ----------------------------------------------- | ----------------------------------------------------------------- |
| Single VM   | Docker (`gristlabs/grist`)                        | **Upstream-documented**                                             |
| Single VM   | Docker Compose with reverse proxy + Postgres     | For prod; SQLite is fine for small teams                             |
| Kubernetes  | Helm chart (community)                            | Stateless-ish; mount persistent volume for `/persist`                  |
| Desktop     | grist-desktop (Electron)                          | Single-user; good for testing                                          |
| Managed     | <https://getgrist.com>                             | Free tier for up to 2 docs + trial of paid features                      |

## Inputs to collect

| Input                    | Example                                 | Phase     | Notes                                                              |
| ------------------------ | --------------------------------------- | --------- | ------------------------------------------------------------------ |
| Persist volume           | `/persist`                               | Filesystem | All docs + user DB live here                                          |
| `PORT`                   | `8484`                                   | Network   | Listen port; set both container + `PORT` env if changing                 |
| `GRIST_SANDBOX_FLAVOR`   | `gvisor` (recommended)                    | Security  | `unsandboxed` (default), `gvisor`, `pyodide`                             |
| `GRIST_DEFAULT_EMAIL`    | admin@example.com                        | Bootstrap | First user set as admin                                                 |
| SSO (optional)           | OIDC / SAML client creds                  | Auth      | `GRIST_OIDC_IDP_ISSUER_URL` etc. — see docs                              |
| External DB (optional)   | Postgres for Grist's "home" DB             | DB        | Separate from per-doc SQLite files; manages users + orgs                  |
| `APP_HOME_URL`           | `https://grist.example.com`              | URL       | Base URL used for links + OIDC redirect                                   |
| SMTP (optional)          | host/port/user/pw                         | Email     | For invitations + notifications                                            |
| AI Assistant (optional)  | OpenAI or OpenRouter API key              | AI        | `ASSISTANT_API_KEY` — for formula generation help                           |

## Install via Docker (minimum)

```sh
docker pull gristlabs/grist:1.x.x   # pin; check tags
docker run -d --name grist \
  --restart unless-stopped \
  -p 8484:8484 \
  -v $(pwd)/persist:/persist \
  gristlabs/grist:1.x.x
```

Visit `http://<host>:8484`. First account to register becomes admin (if `GRIST_DEFAULT_EMAIL` unset).

## Install via Docker Compose

```yaml
services:
  grist:
    image: gristlabs/grist:1.x.x
    container_name: grist
    restart: unless-stopped
    ports:
      - "8484:8484"
    volumes:
      - ./persist:/persist
    environment:
      GRIST_SANDBOX_FLAVOR: gvisor     # safer multi-tenant
      GRIST_DEFAULT_EMAIL: admin@example.com
      APP_HOME_URL: https://grist.example.com
      # SMTP (optional):
      # GRIST_SMTP_HOST: smtp.example.com
      # GRIST_SMTP_USER: ...
      # GRIST_SMTP_PASSWORD: ...
      # AI formula assistant (optional):
      # ASSISTANT_CHAT_COMPLETION_ENDPOINT: https://openrouter.ai/api/v1/chat/completions
      # ASSISTANT_API_KEY: sk-or-...
      # ASSISTANT_MODEL: anthropic/claude-3.7-sonnet
```

## Change port

Important: **set `PORT` env var, don't just change the mapping**:

```yaml
    environment:
      PORT: 9999
    ports:
      - "9999:9999"
```

## First boot

1. Browse `https://grist.example.com`
2. First user registers → becomes admin
3. Create a workspace → create a document (blank, or from template)
4. Add columns, formulas, relations — use AI assistant for formula generation if configured
5. Invite others via workspace → user → share

## gVisor sandbox (recommended for multi-tenant)

Grist runs untrusted Python in formulas. For multi-user installs, enable gVisor:

```yaml
    environment:
      GRIST_SANDBOX_FLAVOR: gvisor
```

Note: gVisor works inside most Linux Docker hosts with default settings but may not work in:

- Docker-on-Docker setups (nested)
- Some Kubernetes configurations (CRI-O, certain seccomp profiles)
- macOS/Windows Docker Desktop (Linux VM is fine but not all kernel features exposed)

Test: create a doc, add a formula `=1+1` → if it evaluates, sandbox is working. Logs will confirm gVisor init.

## Data & config layout

Inside `/persist/`:

- `docs/` — one `.grist` (SQLite) file per document
- `home.sqlite3` (or connected Postgres) — user/org/workspace metadata
- `grist-sessions/`
- `samples/`
- `plugins/` (if enabled)

## Backup

```sh
# Full backup
docker run --rm -v "$(pwd)/persist:/src" -v "$(pwd):/backup" alpine \
  tar czf /backup/grist-$(date +%F).tgz -C /src .
```

Per-doc backup: each `.grist` file is a standalone SQLite DB. Download via the UI's Export → "Save a copy" for single-doc backup.

## Upgrade

1. Releases: <https://github.com/gristlabs/grist-core/releases>. Monthly-ish.
2. `docker compose pull && docker compose up -d`. Grist handles schema migrations on doc open.
3. **Back up before major version bumps** — per-doc schema migrations are forward-only.
4. `:stable` tag tracks the latest stable; `:latest` tracks main branch. **Use a pinned version tag in prod.**

## Gotchas

- **Python in formulas** is real Python — and by default, **NOT sandboxed**. Any user who can edit formulas can run arbitrary Python code in your container. For untrusted users, enable `GRIST_SANDBOX_FLAVOR=gvisor`.
- **`GRIST_SANDBOX_FLAVOR=unsandboxed`** (default) is fine for single-user or trusted teams, but catastrophic for public/multi-tenant installs.
- **Features not in `grist-core`**: see upstream README. Notable: audit log streaming, enterprise admin, SCIM, email notifications (in core but limited), GristConnect, Azure storage. For most self-hosters, core has everything they need.
- **OIDC/SAML in core is "experimental"** per docs — works but some edge cases (specifically around logout, group mapping) may need per-IdP tuning.
- **Each document is a SQLite file** — so you can `sqlite3 /persist/docs/<id>.grist` to inspect raw data (read carefully; Grist's schema is non-obvious).
- **`home.sqlite3`** is the single-point-of-failure for users/orgs/workspaces. Back up separately if using external DBs (Postgres) for the home DB.
- **Sharing model**: per-document ACL, per-workspace roles (owner/editor/viewer), share links with scoped permissions. Granular but takes time to understand.
- **AI formula assistant** — OpenAI or OpenRouter (per README). Sends column schemas + partial formulas to the LLM provider. Privacy: don't enable if your data is sensitive + you don't trust the provider.
- **Importing from Airtable** — `grist-tool` CLI and community scripts exist; not a one-click process.
- **Desktop app** (`grist-desktop`) is an Electron wrapper for single-user local use; good for "I want a smart spreadsheet on my laptop." Uses the same core.
- **Forms** are great — publish a public form URL that writes to a Grist table, no additional tooling needed.
- **Apache 2.0 license** — permissive; commercial use fine.
- **Commercial vs CE** is transparent — no crippled core, no "calls home" phone-home. Self-host with zero licensing cost unless you need the enterprise extras.
- **Alternatives worth knowing:**
  - **NocoDB** — Airtable-alike on top of your existing database (MySQL/Postgres/SQLite); more DB-centric
  - **Baserow** — Airtable-alike, Python/Django, similar positioning
  - **Rowy** — Airtable-like on top of Firebase
  - **Airtable** — commercial SaaS (Grist's main inspiration + competitor)
  - **Datasette** — for **publishing** read-only data, not editing (separate recipe)
  - **Appsmith / ToolJet / Retool** — internal-tool builders; can sit on top of Grist's API
  - **Spreadsheet-first alternatives**: OnlyOffice, Collabora, Nextcloud's collaborative spreadsheet
  - **Grist** wins on: relational integrity + real Python formulas + ACL granularity + forms

## Links

- Repo: <https://github.com/gristlabs/grist-core>
- Website: <https://getgrist.com>
- Docs: <https://support.getgrist.com>
- Self-managed install: <https://support.getgrist.com/self-managed/>
- Docker Hub: <https://hub.docker.com/r/gristlabs/grist>
- Templates: <https://templates.getgrist.com>
- Formula reference: <https://support.getgrist.com/functions/>
- Python formulas: <https://support.getgrist.com/formulas/>
- Desktop app: <https://github.com/gristlabs/grist-desktop>
- Builder Edition (cloud packaging): <https://support.getgrist.com/install/grist-builder-edition/>
- Releases: <https://github.com/gristlabs/grist-core/releases>
- Discord/Forum: <https://community.getgrist.com/>
- YouTube: <https://www.youtube.com/@gristlabs>
