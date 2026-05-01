---
name: Atomic CRM
description: "Self-hosted open source CRM built with React and Supabase. Docker (local Supabase). marmelab/atomic-crm. Contacts, tasks, reminders, notes, email capture, deal pipeline (Kanban), import/export, OAuth (Google/Azure/Keycloak/Auth0), custom fields. MIT."
---

# Atomic CRM

**Self-hosted open source CRM with Supabase backend.** React frontend backed by a local Supabase instance (PostgreSQL + Auth + Storage). Manage contacts, tasks, reminders, notes, deal pipeline (Kanban board), and email capture. Full API, OAuth login, custom fields, and extensive customisation. Free live demo available.

Built + maintained by **marmelab**. MIT license.

- Upstream repo: <https://github.com/marmelab/atomic-crm>
- Demo: <https://marmelab.com/atomic-crm-demo>
- Docs: <https://marmelab.com/atomic-crm/doc/>

## Architecture in one minute

- **React** frontend (Vite, shadcn-admin-kit)
- **Supabase** local instance — PostgreSQL + Auth + Storage + REST API + Edge Functions
- Supabase runs locally via **Docker** (Supabase CLI manages it)
- Dev server: port **5173**; Supabase dashboard: port **54323**; REST API: **54321**
- **Node 22 LTS** + **Make** required on the host
- Resource: **medium** — Supabase stack (Postgres + several helper containers)

## Compatible install methods

| Infra      | Runtime                 | Notes                                            |
| ---------- | ----------------------- | ------------------------------------------------ |
| **Docker** | Supabase local stack    | **Primary** — Supabase CLI spins up Postgres etc |

> Atomic CRM uses `supabase` CLI to manage a local Supabase stack (several Docker containers). This is different from a single-container deploy.

## Prerequisites

```sh
# Required
node --version    # v22 LTS
docker --version  # any recent version
make --version    # GNU make

# Install Supabase CLI
npm install -g supabase
```

## Install

```sh
# 1. Fork then clone
git clone https://github.com/[username]/atomic-crm.git
cd atomic-crm

# 2. Install all dependencies (frontend + backend + local Supabase)
make install

# 3. Start
make start
```

- App: <http://localhost:5173/>
- Supabase dashboard: <http://localhost:54323/>
- REST API: <http://127.0.0.1:54321>
- Email testing (Inbucket): <http://localhost:54324/>

On first visit you'll be prompted to create the first user.

## Features overview

| Feature | Details |
|---------|---------|
| Contact management | Store contacts with full details; search and filter |
| Tasks & reminders | Create tasks, set due dates, get reminders |
| Notes | Capture notes on contacts and deals |
| Email capture | CC Atomic CRM to save emails as notes automatically |
| Deal pipeline | Kanban board for visualising and tracking sales pipeline |
| Import & export | Import/export contacts via CSV |
| OAuth authentication | Google, Azure AD, Keycloak, Auth0 |
| Access control | Role-based access for team members |
| Activity history | Aggregated activity log per contact/deal |
| API | Full REST API via Supabase |
| Custom fields | Add custom fields to contacts and records |
| Customisable | Change theme, replace components, extend data model |
| Attachments storage | File attachments via Supabase Storage |

## Supabase services used

| Service | Purpose |
|---------|---------|
| PostgreSQL | All CRM data |
| Supabase Auth | User authentication + OAuth providers |
| Supabase Storage | File attachments |
| REST API (PostgREST) | Auto-generated CRUD API from PostgreSQL schema |
| Edge Functions | Server-side logic (email capture, etc.) |
| Inbucket | Local email testing during development |

## Gotchas

- **Not a single Docker container.** Atomic CRM uses the Supabase local stack, which starts several Docker containers (Postgres, Auth, Storage, API gateway, etc.) managed by the Supabase CLI. This is more complex than a typical `docker compose up`.
- **Node 22 LTS required on host.** The Supabase CLI and build tools run on the host, not inside a container. Node version matters — use nvm or similar if needed.
- **Production deployment.** For production, you can either keep the local Supabase stack (and reverse-proxy the Vite build) or migrate to a hosted Supabase project. See the [docs](https://marmelab.com/atomic-crm/doc/) for deployment guides.
- **Fork before cloning.** The README instructs to fork first — this is intentional so you can push customisations to your own repo.
- **Email capture requires setup.** The CC-to-CRM email capture feature requires configuring Supabase Edge Functions and an email relay. See docs.
- **MIT license.** Free to use, modify, redistribute.

## Backup

```sh
# Dump Supabase Postgres
supabase db dump -f atomic-crm-$(date +%F).sql
```

## Upgrade

```sh
git pull
make install
make start
```

## Testing

```sh
make test       # unit tests
make test-e2e   # Playwright e2e tests
```

## Project health

Active React/Supabase development, MIT license, live demo, marmelab maintained.

## CRM-family comparison

- **Atomic CRM** — React/Supabase, contacts/deals/pipeline/email capture, OAuth, custom fields, MIT
- **Twenty** — TypeScript/Postgres, highly customisable CRM platform, MIT
- **Monica** — PHP/MySQL, personal CRM (contacts/relationships/reminders), AGPL-3.0
- **SuiteCRM** — PHP, full enterprise CRM suite, AGPL-3.0

**Choose Atomic CRM if:** you want a clean, open source CRM with a React UI, Supabase backend, deal pipeline, email capture, and full customisability — without the weight of an enterprise CRM.

## Links

- Repo: <https://github.com/marmelab/atomic-crm>
- Docs: <https://marmelab.com/atomic-crm/doc/>
- Demo: <https://marmelab.com/atomic-crm-demo>
