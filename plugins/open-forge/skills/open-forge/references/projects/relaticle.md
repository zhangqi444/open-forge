---
name: Relaticle
description: "Self-hosted open-source CRM with MCP server for AI agents. PHP/Laravel 12 + PostgreSQL. relaticle/relaticle. 30 MCP tools, 22 custom field types, multi-team, REST API, Filament 5 UI. AGPL-3.0."
---

# Relaticle

**Open-source self-hosted CRM built for AI agents.** Track contacts, companies, and opportunities in a modern Filament 5 interface — and connect any AI agent (Claude, GPT, or open-source) via a production-grade MCP server with 30 tools. 22 custom field types, per-field encryption, multi-team isolation, REST API.

Built + maintained by **Relaticle team**. AGPL-3.0 license.

- Upstream repo: <https://github.com/relaticle/relaticle>
- Website + docs: <https://relaticle.com/docs>
- MCP server docs: <https://relaticle.com/docs/mcp>
- Self-hosting guide: <https://relaticle.com/docs/self-hosting>
- Discord: <https://discord.gg/relaticle>

## Architecture in one minute

- **PHP 8.4 / Laravel 12** backend
- **Filament 5 + Livewire 4** web UI
- **PostgreSQL 17+** database
- **Redis** for queues (optional in dev; recommended in production)
- **Node.js 20+** + Vite for frontend asset compilation
- **MCP server** built-in — 30 tools for AI agent CRM operations
- **REST API** — full CRUD for all CRM entities
- Resource: **medium** — PHP-FPM + PostgreSQL + optional Redis

## Compatible install methods

| Infra               | Runtime                        | Notes                                                     |
| ------------------- | ------------------------------ | --------------------------------------------------------- |
| **Docker**          | see self-hosting docs          | Official Docker setup; see <https://relaticle.com/docs/self-hosting> |
| **Bare metal**      | PHP 8.4 + Composer + Node 20   | Clone + `composer app-install`                            |

## Inputs to collect

| Input                     | Example                         | Phase    | Notes                                               |
| ------------------------- | ------------------------------- | -------- | --------------------------------------------------- |
| `DB_*` PostgreSQL creds   | host, port, user, pass, db      | Storage  | PostgreSQL 17+                                      |
| `APP_KEY`                 | auto-generated                  | Security | Laravel application key (`php artisan key:generate`) |
| `APP_URL`                 | `https://crm.example.com`       | Network  | Public URL                                          |
| Redis URL (opt.)          | `redis://redis:6379`            | Queue    | For background job queues; recommended in production |

## Install (bare metal)

```bash
git clone https://github.com/relaticle/relaticle.git
cd relaticle

# Install PHP + Node dependencies; configure .env; run migrations; seed DB
composer app-install

# Start dev server (server + queue + Vite all in one)
composer dev
```

For production/Docker: see <https://relaticle.com/docs/self-hosting>

## First boot

1. Run `composer app-install` (creates `.env`, generates `APP_KEY`, runs migrations, seeds initial data).
2. Visit the UI → create your admin account.
3. Configure your workspace and invite team members.
4. Add contacts, companies, and opportunities.
5. (Optional) Connect an AI agent via MCP:
   - Get your MCP endpoint URL from Settings → MCP Server
   - Configure Claude Desktop / other agent to connect
   - Use 30 MCP tools for CRM operations via natural language

## CRM entities

| Entity | Description |
|--------|-------------|
| Contacts | People with 22 custom field types |
| Companies | Organizations; link contacts to companies |
| Opportunities | Sales pipeline items |
| Activities | Notes, calls, emails (linked to any entity) |
| Custom fields | Per-entity; 22 types including entity relationships, conditional visibility |

## MCP server (30 tools)

Relaticle's MCP server exposes 30 tools for AI agents to perform full CRM operations:
- List, create, update, delete contacts/companies/opportunities
- Search across entities
- Log activities
- Schema discovery (AI agents can discover available fields dynamically)

Compatible with Claude Desktop, GPT via tool calling, and any MCP-compatible AI framework.

## Custom field types (22)

Text, number, boolean, date, datetime, select, multi-select, URL, email, phone, currency, percentage, rating, color, JSON, entity relationship, and more. Per-field encryption supported.

## Multi-team isolation

5-layer authorization model: superadmin → team owner → team admin → team member → viewer. Data is team-scoped — members of one team cannot access another team's data. Workspaces support multiple teams.

## Gotchas

- **PHP 8.4 required.** Relaticle targets PHP 8.4 (latest stable). Most distro PHP packages lag behind — use `ondrej/php` PPA on Ubuntu or the official PHP Docker image.
- **PostgreSQL 17+ required.** Not compatible with older PostgreSQL versions. Use the official `postgres:17` Docker image.
- **`composer app-install` does everything.** This custom Composer script runs: `cp .env.example .env`, `composer install`, `npm install`, `php artisan key:generate`, `php artisan migrate --seed`, and `npm run build`. Run it once on fresh install.
- **Queue worker for background jobs.** Production deployments need a queue worker (`php artisan queue:work`) running continuously. In `composer dev`, this is included. In production, use a process supervisor (Supervisor, systemd).
- **MCP server requires authentication.** The MCP endpoint requires an API token. Generate tokens via Settings → API Tokens.
- **AGPL-3.0 license.** If you modify Relaticle and expose it as a network service, you must publish your modifications under AGPL-3.0.

## Backup

```sh
# PostgreSQL dump
pg_dump -U relaticle relaticle > relaticle-$(date +%F).sql
# .env + storage/ folder
tar czf relaticle-storage-$(date +%F).tgz storage/ .env
```

## Upgrade

```sh
git pull
composer install
npm install && npm run build
php artisan migrate
php artisan config:cache
```

## Project health

Active Laravel 12 + Filament 5 development, MCP server (30 tools), REST API, Discord, docs site, 1,100+ automated tests. AGPL-3.0.

## CRM-family comparison

- **Relaticle** — PHP+Laravel+Filament, MCP server (AI-native), 22 custom fields, multi-team, AGPL
- **Monica** — PHP+Laravel, personal CRM, simpler scope; no MCP
- **Twenty** — TypeScript, headless CRM, also AI-forward; different tech stack
- **SuiteCRM** — PHP, enterprise CRM, complex; no MCP
- **Krayin** — PHP+Laravel, CRM; no MCP
- **Salesforce** — SaaS; the commercial reference

**Choose Relaticle if:** you want a self-hosted CRM with first-class AI agent integration (MCP server), highly customizable fields, multi-team support, and a modern Filament 5 UI.

## Links

- Repo: <https://github.com/relaticle/relaticle>
- Docs: <https://relaticle.com/docs>
- Self-hosting: <https://relaticle.com/docs/self-hosting>
- MCP server: <https://relaticle.com/docs/mcp>
- Discord: <https://discord.gg/relaticle>
