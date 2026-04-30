---
name: Vikunja
description: "Open-source todo + project + task management — self-hosted Trello/Todoist/Asana alternative. Kanban, lists, Gantt, filters, labels, sharing, CalDAV sync, iOS + Android apps. Go + Vue. AGPL-3.0+."
---

# Vikunja

Vikunja is **"the todo-app to organize your life"** — an open-source self-hosted task + project manager that covers a broad feature set: **simple todo lists, kanban boards, Gantt charts, hierarchical projects, filters, labels, assignees, due dates, subtasks, attachments, sharing, CalDAV sync (phone calendars), REST API, and native iOS + Android apps**. A plausible self-hosted replacement for Todoist / Trello / Asana / ClickUp for individuals + small teams.

Built + maintained by **kolaente (Konrad Langenberg)** via `go-vikunja/vikunja` (moved from `code.vikunja.io` to GitHub under the org). **AGPL-3.0-or-later** for most of the repo; `desktop/` is GPL-3.0-or-later. Commercial-tier-funds-upstream: **Vikunja Cloud** (<https://vikunja.cloud>) for hassle-free managed hosting.

Use cases: (a) personal GTD / Todoist replacement (b) small-team project management without SaaS (c) CalDAV-sync todo → Apple Reminders / phone calendar (d) homelab "one tool for my life" todo hub.

Features:

- **Tasks**: title, description, due date, reminders, priority, subtasks, attachments, labels, assignees
- **Projects** (formerly "lists") with hierarchy
- **Views**: List, Kanban, Gantt, Table, Filter
- **Labels + Filters** — advanced filter expressions
- **Sharing** — user-level + link-based
- **Reminders + notifications** (email + web)
- **CalDAV sync** — integrate with phone/desktop calendars (Apple Reminders, DAVx⁵)
- **REST API** + **Swagger docs**
- **Native mobile apps**: iOS (App Store) + Android (F-Droid + Play Store)
- **Desktop apps**: Electron-based (GPL-3)
- **Import**: Todoist, Trello, Microsoft To-Do, TickTick, Vikunja export
- **Saved filters** + **team workspaces**
- **Configurable keyboard shortcuts**
- **Multi-language i18n**
- **Dark mode**

- Upstream repo: <https://github.com/go-vikunja/vikunja>
- Homepage: <https://vikunja.io>
- Docs: <https://vikunja.io/docs>
- Installing: <https://vikunja.io/docs/installing/>
- Features page: <https://vikunja.io/features/>
- Try instance: <https://try.vikunja.io>
- Managed: <https://vikunja.cloud>
- Swagger API docs: <https://try.vikunja.io/api/v1/docs>
- Roadmap: <https://my.vikunja.cloud/share/...>
- Donations: <https://www.buymeacoffee.com/kolaente> / <https://github.com/sponsors/kolaente>
- Docker Hub: <https://hub.docker.com/r/vikunja/vikunja>
- F-Droid (Android): <https://f-droid.org/packages/io.vikunja.app/>

## Architecture in one minute

- **Go** backend (single binary) + **Vue 3** frontend
- **DB**: SQLite (default), MySQL / MariaDB, PostgreSQL
- **File storage**: local filesystem
- **Single-container image** (combines API + frontend; previously separate)
- **Resource**: small — 100-300MB RAM typical

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Docker             | **`vikunja/vikunja`** — single container (API + frontend)      | **Upstream-primary** (as of v1.0+)                                                 |
| Docker Compose     | Compose examples in docs                                                   | Add external Postgres if scaling                                                           |
| Binary             | Single Go binary + static files                                                                     | Supported                                                                                              |
| Kubernetes         | Community Helm charts                                                                                 | Works                                                                                                  |
| Managed            | Vikunja Cloud                                                                                                          | Funds upstream                                                                                                                |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `todo.example.com`                                              | URL          | TLS required (mobile apps + CalDAV)                                                                                  |
| `VIKUNJA_SERVICE_JWTSECRET` | long random                                                                  | Secret       | **Immutable** once users exist — rotating invalidates sessions                                                         |
| `VIKUNJA_SERVICE_PUBLICURL` | same as domain                                                                              | Config       | What UI + API tell clients                                                                                              |
| DB                   | SQLite (default) / MySQL / Postgres                                             | DB           | External DB for teams                                                                                              |
| SMTP                 | For password reset + reminders                                                                                                    | Email        | Strongly recommended                                                                                                              |
| Admin user           | via registration OR CLI                                                                                                                          | Bootstrap    | Disable open registration after admin setup                                                                                                                 |
| Import data          | Export from Todoist / Trello / etc.                                                                                                                            | Migration    | Built-in importers for common tools                                                                                                                                 |

## Install via Docker Compose

```yaml
services:
  vikunja:
    image: vikunja/vikunja:2                         # **pin major version**; 2.x current
    restart: unless-stopped
    ports: ["3456:3456"]
    environment:
      VIKUNJA_SERVICE_PUBLICURL: https://todo.example.com
      VIKUNJA_SERVICE_JWTSECRET: ${JWT_SECRET}
      VIKUNJA_DATABASE_TYPE: postgres
      VIKUNJA_DATABASE_HOST: db:5432
      VIKUNJA_DATABASE_DATABASE: vikunja
      VIKUNJA_DATABASE_USER: vikunja
      VIKUNJA_DATABASE_PASSWORD: ${DB_PASSWORD}
    volumes:
      - ./vikunja-files:/app/vikunja/files
    depends_on: [db]
  db:
    image: postgres:15
    environment:
      POSTGRES_USER: vikunja
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: vikunja
    volumes: [pg_data:/var/lib/postgresql/data]

volumes:
  pg_data:
```

See <https://vikunja.io/docs/installing/> for authoritative values.

## First boot

1. Deploy → browse URL → register first user (= admin by default)
2. **Disable open registration** (Admin / Env — `VIKUNJA_SERVICE_ENABLEREGISTRATION: false`)
3. Configure SMTP → send test email
4. Create your first Project → first Tasks
5. Install mobile apps → point at your server → login
6. (opt) Configure CalDAV → integrate with phone calendar
7. (opt) Import from Todoist/Trello
8. Put behind TLS reverse proxy
9. Back up DB + `files/`

## Data & config layout

- **DB** — all tasks, projects, users
- **`files/`** — task attachments
- **Config** via env vars (`VIKUNJA_*` prefix) or `config.yml`
- **JWT secret** in env / config

## Backup

```sh
# DB
pg_dump -Fc -U vikunja vikunja > vikunja-db-$(date +%F).dump
# OR for SQLite:
# sqlite3 vikunja.db ".backup 'vikunja-$(date +%F).db'"

# Attachments
sudo tar czf vikunja-files-$(date +%F).tgz vikunja-files/

# Also back up config/.env including JWT secret
```

## Upgrade

1. Releases: <https://github.com/go-vikunja/vikunja/releases>. Active cadence.
2. **v1.x → v2.x was a breaking change** (single-container move, config refactors). Read migration guide if coming from pre-v2.
3. Docker: bump tag; migrations run automatically.
4. **Back up DB before major versions.**
5. Mobile app + server should be on compatible versions — upstream maintains API compat windows.

## Gotchas

- **v1 → v2 structural change** — prior versions had separate `vikunja/api` + `vikunja/frontend` containers; current (v2+) is a single `vikunja/vikunja` image. If migrating from old compose files, restructure. Same class as Lychee v7 Docker-layout change (batch 83).
- **`VIKUNJA_SERVICE_JWTSECRET` immutability** — rotating invalidates every session + every active mobile app login. Set once; secure. **Eighth tool in immutability-of-secrets family** (Black Candy, Lychee, Forgejo, Nexterm, Fider, Wakapi, Statamic, FreeScout).
- **CalDAV sync quality varies by client.** DAVx⁵ on Android = excellent (same as Radicale batch 79 pattern). Apple Reminders CalDAV = workable but has quirks around list-vs-project mapping. Test your specific sync chain before bet-the-farm reliance.
- **Projects vs Lists rename**: historically "Lists"; renamed to "Projects" to support nesting + broader use. If you find older docs referencing "lists", they mean projects.
- **Attachments in DB backup?** NO — attachments live on filesystem in `files/`. Back up separately. Common backup-coverage gap.
- **Open registration** enabled by default. Disable it after creating your admin user unless you intentionally run a multi-tenant instance.
- **Mobile app OSS trust signal**: Android on F-Droid = no Google Play tracking. Same privacy-signal family as Black Candy (83). iOS via App Store unavoidably involves Apple account.
- **Email notifications** (reminders) rely on SMTP. Without SMTP: reminders fire in-app only — reduced value for users who don't open the app daily.
- **Vikunja Cloud commercial-tier-funds-upstream**: kolaente offers managed hosting; revenue sustains OSS development. Same pattern as Rallly.co (batch 75), Fider Cloud, etc. **Not feature-gate — pure managed-tier subtype #2.**
- **Import fidelity**: importers are best-effort. Todoist recurring rules + custom views may not round-trip perfectly. Inspect imported data before deleting the original.
- **No E2E encryption** for tasks — plaintext-at-rest in DB. If tasks contain sensitive info (passwords, medical, legal), encrypt backups + consider who has DB access.
- **Multi-user sharing model**: user-to-user sharing + team workspaces + link sharing. Fine for small teams. For enterprise RBAC + SAML / audit-log, check if those are in Pro tier or missing.
- **API-first design** → easy to integrate with automation (Zapier / n8n / Home Assistant via webhooks). Vikunja's REST + Swagger make custom integrations straightforward.
- **Project health**: kolaente solo-led + active commits + paid Cloud + sponsors + F-Droid + iOS/Android apps. Bus-factor-1 mitigated by (a) active sponsorship model (b) clean Go + Vue stack (c) substantial user base (d) Vikunja Cloud revenue.
- **License nuance**: main repo = **AGPL-3.0-or-later**; `desktop/` Electron app = **GPL-3.0-or-later**. Unsplash images (backgrounds) have separate attribution requirement. Minor nuance; not deal-breaking.
- **Alternatives worth knowing:**
  - **Planka** — Trello-like kanban; simpler scope
  - **Kanboard** — PHP; stable + mature; kanban-only
  - **Nextcloud Tasks + Deck** — if Nextcloud already deployed
  - **WeKan** — Trello-clone; JavaScript
  - **Taiga** — agile PM + sprint planning; heavier
  - **Focalboard** — open-source by Mattermost; Trello/Notion-ish
  - **Todoist / Notion / Asana / ClickUp / Trello** — commercial
  - **Cal.com** — no relation (appointments, not todos)
  - **Choose Vikunja if:** want one tool for todos + projects + kanban + CalDAV + native mobile apps + AGPL.
  - **Choose Planka / WeKan if:** pure kanban focus.
  - **Choose Nextcloud Tasks + Deck if:** already running Nextcloud.
  - **Choose Taiga if:** agile/scrum workflows priority.

## Links

- Repo: <https://github.com/go-vikunja/vikunja>
- Homepage: <https://vikunja.io>
- Docs: <https://vikunja.io/docs>
- Installing: <https://vikunja.io/docs/installing/>
- Try instance: <https://try.vikunja.io>
- API docs (Swagger): <https://try.vikunja.io/api/v1/docs>
- Vikunja Cloud: <https://vikunja.cloud>
- Releases: <https://github.com/go-vikunja/vikunja/releases>
- Docker Hub: <https://hub.docker.com/r/vikunja/vikunja>
- F-Droid (Android): <https://f-droid.org/packages/io.vikunja.app/>
- Sponsor: <https://github.com/sponsors/kolaente>
- Planka (alt): <https://planka.app>
- Kanboard (alt): <https://kanboard.org>
- WeKan (alt): <https://wekan.fi>
- Focalboard (alt): <https://www.focalboard.com>
- Taiga (alt): <https://www.taiga.io>
