---
name: WhoDB
description: "Lightweight, fast, AI-powered DB manager (<50MB) — Go + React. Supports Postgres/MySQL/SQLite/MongoDB/Redis/MariaDB/ElasticSearch (CE) + Oracle/SQL Server/Snowflake/... (EE). Natural-language-to-SQL via Ollama/OpenAI/Anthropic. Apache-2.0."
---

# WhoDB

WhoDB is **"DBeaver, but tiny + fast + AI-powered"** — a modern database management tool built in **Go + TypeScript/React**, weighing in at **<50MB** with sub-second startup, a beautiful spreadsheet-like grid, interactive schema topology graph, Jupyter-like Scratchpad query editor, and **natural-language-to-SQL** via **Ollama / OpenAI / Anthropic / any OpenAI-compatible endpoint**.

Built by **Clidey** (commercial entity); **Community Edition** is Apache-2.0 (free); **Enterprise Edition** adds Oracle / SQL Server / DynamoDB / Snowflake / Cassandra / etc. Available as **Docker / Windows Store / macOS App Store / Snap / CLI (with MCP server)**.

Positioning vs CloudBeaver (batch 76): WhoDB = **much lighter, AI-first, simpler UX**. CloudBeaver = heavier, more driver coverage via JDBC, more enterprise-features via Team/Enterprise.

Features (CE):

- **<50MB** image + **<1s startup**
- **Spreadsheet data grid** — view, edit, sort, filter, inline edit, bulk ops
- **Interactive schema graph** — tables + foreign keys + pan/zoom
- **Scratchpad** (Jupyter-like) — syntax highlight, history, multi-cell
- **AI-powered** — natural-language queries via Ollama/OpenAI/Anthropic/OpenAI-compat
- **Mock data generation** — realistic test data
- **Flexible export** — CSV / Excel / JSON / SQL
- **Advanced filtering** — visual WHERE builder
- **Community Edition DBs**: Postgres, MySQL, MariaDB, SQLite3, MongoDB, Redis, ElasticSearch
- **CLI + TUI + MCP** — `whodb-cli` with Model Context Protocol server for AI assistants (Claude, Cursor, etc.)

Enterprise Edition adds: Oracle, SQL Server, DynamoDB, Athena, Snowflake, Cassandra, and more.

- Upstream repo: <https://github.com/clidey/whodb>
- Docs: <https://docs.whodb.com>
- Homepage: <https://whodb.com>
- Live demo: <https://demo.whodb.com>
- Discussions: <https://github.com/clidey/whodb/discussions>
- Docker Hub: <https://hub.docker.com/r/clidey/whodb>
- Microsoft Store: <https://apps.microsoft.com/detail/9pftx5bv4ds6>
- Mac App Store: <https://apps.apple.com/app/whodb/id6754566536>
- Snapcraft: <http://snapcraft.io/whodb>
- CLI: <https://github.com/clidey/whodb/tree/main/cli>
- Clidey: <https://clidey.com>

## Architecture in one minute

- **Go backend** + **React frontend** in single binary/image
- **No external DB required** for WhoDB itself — it's a client, stores minimal state
- **Connects to any supported DB** per user login (credentials in session)
- **AI integration** via HTTP to Ollama/OpenAI/Anthropic endpoints
- **CLI separate binary** with TUI + MCP server
- **Resource**: tiny — 50-150 MB RAM

## Compatible install methods

| Infra              | Runtime                                                       | Notes                                                                          |
| ------------------ | ------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Single VM          | **Docker (`clidey/whodb`)**                                       | **Upstream-primary**                                                               |
| Desktop            | Microsoft Store / Mac App Store / Snap                                    | Store-distributed desktop apps                                                             |
| CLI / TUI          | `whodb-cli` install script / npm                                                     | For terminal users + MCP server                                                                             |
| Kubernetes         | Standard Go-app deploy                                                                      | Works                                                                                                       |
| Managed demo       | <https://demo.whodb.com>                                                                                  | Read-only demo DB                                                                                                    |

## Inputs to collect

| Input                        | Example                                                    | Phase        | Notes                                                                    |
| ---------------------------- | ---------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain                       | `whodb.example.com`                                            | URL          | TLS via reverse proxy                                                            |
| DB connections               | per-user: host/port/user/password                                        | Connections  | Entered at login; not server-stored (stateless-per-session model)                                        |
| AI provider (opt)            | Ollama / OpenAI / Anthropic / OpenAI-compat                                        | AI           | Set via `WHODB_*` env vars                                                                           |
| Ollama host (opt)            | `localhost:11434` or `host.docker.internal:11434`                                           | AI           | Local models; privacy-preserving                                                                                        |
| OpenAI / Anthropic key (opt) | API key                                                                            | AI (paid)    | **Billing account — queries cost money**                                                                                             |

## Install via Docker

```sh
docker run -d --name whodb -p 8080:8080 clidey/whodb:0.110.0      # pin specific version in prod
# → browse http://localhost:8080
```

Compose variant with Ollama:
```yaml
services:
  whodb:
    image: clidey/whodb:0.110.0
    ports: ["8080:8080"]
    environment:
      WHODB_OLLAMA_HOST: host.docker.internal
      WHODB_OLLAMA_PORT: "11434"
```

## First boot

1. Browse `http://<host>:8080/`
2. Login page = DB connection form — provide target DB credentials (NOT WhoDB-user-creds; there are no WhoDB users in CE)
3. Test connection → land in navigator
4. Explore schema in graph view; run test query in Scratchpad
5. If AI configured: try natural-language-to-SQL ("show me users created last week")
6. Before production use: put WhoDB behind TLS + authentication layer (Authelia / Authentik / forward-auth / Cloudflare Zero Trust / VPN). **WhoDB CE has no built-in user-auth.**

## Data & config layout

- WhoDB itself stores almost nothing persistently (CE): session state, optional local config
- **No internal credentials store** in CE — you re-enter DB creds per session (by design — privacy-preserving)
- Logs per container
- Mount `./sample.db:/db/sample.db` for local SQLite demos

## Backup

Almost nothing to back up for WhoDB itself. Back up the TARGET DBs via their native tools.

## Upgrade

1. Releases: <https://github.com/clidey/whodb/releases>. Active — commits per month badge shown.
2. Docker: bump tag → restart. No migrations (stateless).
3. Read changelog for UI + AI feature changes.

## Gotchas

- **WhoDB CE has NO built-in user authentication.** Anyone who can reach WhoDB's port can enter any DB creds + connect. Deploy WhoDB behind **forward-auth** (Authelia/Authentik/Cloudflare Access), **VPN**, or **private network only**. Do NOT expose to internet without an auth layer. Enterprise Edition may add user auth — check current EE feature list.
- **Access to WhoDB = attempt-any-DB access.** Like CloudBeaver (batch 76): treat as SSH-jumpbox threat model. Restrict network, require MFA at forward-auth layer, monitor logs.
- **DB credentials live in user session** — refresh session = re-enter. **Privacy-preserving vs productivity-annoying**. For shared team use, this may feel friction-heavy; CloudBeaver's saved-connections UX is closer to team-use. WhoDB's stateless-auth matches "one developer / one laptop" ergonomics.
- **AI = data sent to third party (unless Ollama).** When NL→SQL is enabled with OpenAI/Anthropic, **your schema + query text is sent to their servers**. For regulated data (healthcare / finance / PII) → **use Ollama locally** (privacy-preserving, free, model-quality-variable). Read provider data-use policies. Don't send prod DB schemas to OpenAI without legal signoff.
- **AI API keys = billable credentials.** `WHODB_ANTHROPIC_API_KEY` / `WHODB_OPENAI_API_KEY` → budget alert on provider dashboard. Rogue/curious users can rack up thousands of dollars of query cost. Consider Ollama even for cost reasons.
- **MCP server in CLI** — `whodb-cli mcp serve` exposes WhoDB as Model Context Protocol server for AI agents (Claude/Cursor). **This means an AI agent can query your DB.** Great for workflow; threat-model-impacting. Audit what the agent has access to; use read-only DB users; never point MCP at prod with write access from an untrusted agent.
- **Read-only DB users strongly recommended** for exploration. Accidentally running `DELETE FROM users` is easy in any grid-UI. Give WhoDB users a readonly role + switch to RW only for explicit edits.
- **Export = data exfil vector.** WhoDB exports to CSV/Excel/JSON/SQL. If worried about exfiltration, wrap in forward-auth with audit logging; EE may add audit.
- **EE features vs CE**: CE is fully functional for typical DBs (Postgres/MySQL/Mongo/Redis). Enterprise drivers (Oracle/SQL-Server/Snowflake/DynamoDB) gated behind EE. Check licensing for commercial use.
- **Desktop-app variants** (MS Store / Mac App Store / Snap) = sandboxed single-user alternatives to hosting. For "one developer one laptop" use, desktop is often better than self-hosting a web instance.
- **Startup time + resource footprint genuine differentiators** — under 1s + under 50 MB = order-of-magnitude better than JVM-based DBeaver/CloudBeaver. On resource-constrained infra this matters.
- **Schema-graph view genuinely useful** — visualizing foreign keys helps onboard new team members to existing DBs. A teaching tool.
- **License**: **Apache-2.0** (CE). EE is commercial.
- **Governance**: Clidey commercial company; active development; consistent cadence badges. Healthy commercial-OSS pattern.
- **Alternatives worth knowing:**
  - **CloudBeaver** (batch 76) — heavier, more DBs via JDBC, Team/Enterprise tiers
  - **DBeaver Desktop** — JVM desktop; same team as CloudBeaver
  - **Adminer** — single-PHP-file; tiny + MySQL/Postgres-focused
  - **phpMyAdmin / pgAdmin** — DB-specific; classic
  - **TablePlus / Beekeeper Studio** — commercial desktop apps
  - **Metabase / Redash** — BI-oriented (read-mostly; dashboards)
  - **Choose WhoDB if:** you want tiny + fast + AI-augmented + multi-DB + modern UI.
  - **Choose CloudBeaver if:** you want more DB drivers + enterprise features + team connection sharing.
  - **Choose DBeaver Desktop if:** one-user + rich feature set + don't want to self-host.

## Links

- Repo: <https://github.com/clidey/whodb>
- Docs: <https://docs.whodb.com>
- Homepage: <https://whodb.com>
- Live demo: <https://demo.whodb.com>
- Discussions: <https://github.com/clidey/whodb/discussions>
- Docker Hub: <https://hub.docker.com/r/clidey/whodb>
- Microsoft Store: <https://apps.microsoft.com/detail/9pftx5bv4ds6>
- Mac App Store: <https://apps.apple.com/app/whodb/id6754566536>
- Snap: <http://snapcraft.io/whodb>
- CLI: <https://github.com/clidey/whodb/tree/main/cli>
- Releases: <https://github.com/clidey/whodb/releases>
- Architecture doc: <https://github.com/clidey/whodb/blob/main/ARCHITECTURE.md>
- Clidey: <https://clidey.com>
- CloudBeaver (alt, batch 76): <https://github.com/dbeaver/cloudbeaver>
- DBeaver Desktop (alt): <https://dbeaver.io>
- Adminer (alt): <https://www.adminer.org>
- Ollama (recommended AI backend): <https://ollama.ai>
- Model Context Protocol: <https://modelcontextprotocol.io>
