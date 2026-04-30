---
name: Baserow
description: "Open-source no-code platform — spreadsheet-database hybrid + applications + automations + AI (Kuma assistant) + dashboards. Django + Vue.js + PostgreSQL. Airtable alternative. Open-core: MIT core + Premium + Enterprise. GDPR/HIPAA/SOC 2 Type II compliant."
---

# Baserow

Baserow is **the leading open-source Airtable alternative** — spreadsheet-database hybrid + application builder + automations + dashboards + **Kuma AI assistant** for building whole solutions via natural language. Trusted by 150,000+ users; **Django + Vue.js + PostgreSQL**; enterprise-grade: **GDPR + HIPAA + SOC 2 Type II compliant**; **API-first + headless**; self-hostable with no storage/record limits.

Built + maintained by **Baserow B.V.** (Netherlands); Bram Wiepjes founder. **Open-core model**: MIT-licensed core includes most non-premium features; Premium + Enterprise tiers add advanced capabilities.

> **Repository migration note (2025):** Baserow moved from GitLab → GitHub. New issues/discussions on **<https://github.com/baserow/baserow>**; historical GitLab archive remains at **<https://gitlab.com/baserow/baserow>**.

Features (core + premium):

- **Spreadsheet-database hybrid** — tables + views (grid, kanban, calendar, gallery, form)
- **Application builder** — publish internal tools/portals on your own domain
- **Automations** — no-code workflow builder
- **Dashboards** — data viz on your own data
- **Kuma AI assistant** — build databases/workflows via natural language
- **API-first + headless** — integrate with anything via REST
- **Unlimited records + storage** (self-hosted; cloud has pricing tiers)
- **Role-based access** (Premium/Enterprise)
- **SAML SSO** (Enterprise)
- **Audit log** (Enterprise)
- **PostgreSQL** storage — proper relational DB, not opaque proprietary
- **Django + Vue.js** stack — maintainable, familiar

- Upstream repo: <https://github.com/baserow/baserow>
- Legacy GitLab archive: <https://gitlab.com/baserow/baserow>
- Homepage: <https://baserow.io>
- Docs: <https://baserow.io/docs/index>
- API redoc: <https://api.baserow.io/api/redoc/>
- Community forum: <https://community.baserow.io/>
- Sponsor (Bram2w): <https://github.com/sponsors/bram2w>
- Pricing / managed: <https://baserow.io/pricing>
- Elestio managed: <https://elest.io/open-source/baserow>
- Docker Hub: <https://hub.docker.com/r/baserow/baserow>

## Architecture in one minute

- **Django (Python)** backend + **Vue.js** frontend
- **PostgreSQL** — required (central storage for all tables + user data)
- **Redis** — Celery broker + cache
- **Celery** — background workers (imports, exports, automations)
- **S3-compat optional** — file attachments; local disk default
- **Single all-in-one Docker image** option (`baserow/baserow`) OR multi-container compose for production scale
- **Resource**: small idle (500 MB-1 GB); scales with workspaces + automations + concurrent users

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Single VM          | **All-in-one Docker** (`baserow/baserow`) OR Docker Compose       | **Upstream-primary** for small-medium                                                  |
| Kubernetes         | **Official Helm chart**                                                   | For scale / HA                                                                             |
| Heroku / Render / Railway | One-click templates                                                            | Upstream-documented                                                                                    |
| DigitalOcean / AWS | Upstream install guides                                                                | Documented                                                                                             |
| Cloudron           | Cloudron packaged                                                                          | Self-hoster friendly                                                                                   |
| Elestio            | Managed deploy; revenue share                                                                       | Ethical-managed tier                                                                                              |
| Managed            | **Baserow Cloud** — upstream SaaS                                                                             | Commercial; directly funds upstream                                                                                               |

## Inputs to collect

| Input                | Example                                                        | Phase        | Notes                                                                    |
| -------------------- | -------------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `baserow.example.com`                                              | URL          | TLS + WebSocket pass-through                                                      |
| PostgreSQL           | external PG 12+ or bundled                                                | DB           | **Don't point multiple Baserow instances at same DB**                                       |
| Redis                | bundled or external                                                        | Cache        | For Celery                                                                                                |
| Storage              | local / S3-compat                                                                  | Storage      | User attachments                                                                                                         |
| SMTP                 | for user invitations + password resets                                                    | Email        | Strongly recommended                                                                                                      |
| Domain publish       | application builder `publish_to_domain` uses your controlled domain                                             | DNS          | For public-facing portals                                                                                                        |
| Enterprise license   | optional — Premium / Enterprise keys                                                                       | License      | Unlocks gated features                                                                                                                  |

## Install via all-in-one Docker

```sh
docker run \
  -v baserow_data:/baserow/data \
  -p 80:80 -p 443:443 \
  -e BASEROW_PUBLIC_URL=https://baserow.example.com \
  baserow/baserow:2.2.2
```

For production use Docker Compose variant with external Postgres + Redis + media volume.

## First boot

1. Create first user (auto-promoted to admin)
2. Create first workspace → first database → first table
3. Explore views (grid/kanban/calendar/gallery/form)
4. Try Kuma AI: ask it to build a table/automation
5. Configure SMTP for invitations
6. Create admin user + disable open signup (if appropriate)
7. Try application builder: build a simple internal tool
8. Put behind TLS reverse proxy (nginx/traefik); `BASEROW_PUBLIC_URL` must match
9. Schedule Postgres + media-volume backups

## Data & config layout

- PostgreSQL — ALL workspace data, user data, schema, values
- Redis — Celery queue + session
- `/baserow/data/` (all-in-one) — PG + uploads + logs
- Docker Compose: separate volumes per service

## Backup

```sh
pg_dump -Fc -U baserow baserow > baserow-$(date +%F).dump
sudo tar czf baserow-media-$(date +%F).tgz /var/lib/docker/volumes/baserow_data
```

For all-in-one image, just tar the named volume.

## Upgrade

1. Releases: <https://github.com/baserow/baserow/releases>. Active — frequent releases.
2. **Always back up Postgres first.**
3. Docker: bump tag → migrations run on restart.
4. **Read upgrade notes for major versions** — occasional schema migrations.

## Gotchas

- **Repository migrated GitLab → GitHub** mid-2025. PRs/MRs didn't migrate — historical discussion on GitLab. New contributions go to GitHub. Classic "rebrand/migration transition" pattern (matches Scanopy←NetVisor batch 76).
- **Open-core model**: MIT for non-premium + non-enterprise features. **Some features you may assume are "core" are gated** — RBAC advanced, SAML, audit logs, row-level permissions. Evaluate needs against tier before committing to self-host.
- **`BASEROW_PUBLIC_URL` must match public URL** — same failure mode as Kan `NEXT_PUBLIC_BASE_URL`, Rallly `NEXT_PUBLIC_BASE_URL`, Kener `ORIGIN` (batches 75-77). Misconfigure = auth callbacks + email links break.
- **PostgreSQL IS the primary store** — unlike Airtable's proprietary engine, Baserow's data is queryable via SQL directly. Massive data-sovereignty win + analytics-friendly. Corollary: careless DB access bypasses Baserow's RBAC. Don't hand out DB credentials.
- **Don't point multiple Baserow instances at same DB** — migrations race; corruption risk.
- **Kuma AI = data sent to LLM provider.** When AI features are used, your schema + queries + possibly data samples are sent to configured AI backend. Privacy-boundary concern matching WhoDB (batch 77). Review what endpoint Kuma uses; check for Ollama/local-AI support if sensitive.
- **GDPR/HIPAA/SOC 2 compliance statements apply to Baserow Cloud** primarily. Self-hosting = compliance is YOUR responsibility (same OpenEMR-HIPAA pattern, batch 74). Audit logs, encryption-at-rest, BAAs = your problem.
- **Celery workers must run** — imports/exports/automations fail silently without Celery. Monitor worker health.
- **Attachments volume grows quickly** — images + documents. Size + rotate policy recommended. S3-compat storage vastly better at scale than local disk.
- **Application builder = stateful public-facing app** — if you publish an internal tool to a public domain, anyone can hit it. Implement your app's auth WITHIN Baserow's app builder; don't rely on "security through obscurity."
- **Self-host storage unlimited; cloud tiered** — self-host advantage for high-record-count use cases (millions of rows).
- **SMTP config = invitation deliverability** — magic-link-style invites mandatory for multi-user orgs. Same pattern as Kan (batch 77), Rallly (batch 75).
- **All-in-one image vs Compose**: all-in-one simpler but less flexible (single container = harder to scale Celery workers). For small/personal: all-in-one great. For production multi-user: compose + Helm.
- **Airtable-migration**: Baserow has Airtable import; works for most tables. Complex formulas + automations may need manual reconstruction.
- **License**: **MIT** (core) + **Premium/Enterprise commercial tiers**. Open-core.
- **Project health**: Baserow B.V. corporate-backed; sustained release cadence; strong community. Not bus-factor-1.
- **Alternatives worth knowing:**
  - **NocoDB** — Node-based; similar Airtable-alt positioning
  - **Teable** — newer Postgres-native Airtable-alt
  - **Mathesar** (batch 75) — Foundation-governed Postgres-spreadsheet
  - **Airtable** — commercial SaaS the open-source world chases
  - **Rowy** — Firestore-based (not self-host-friendly typically)
  - **Choose Baserow if:** mature Airtable-alt + app-builder + automations + corporate-backed OSS + EU-based.
  - **Choose NocoDB if:** Node stack preferred + can-connect-to-existing-DBs (MySQL/Postgres/SQL Server).
  - **Choose Mathesar if:** Foundation governance + Postgres-native + non-Airtable positioning.
  - **Choose Teable if:** modern Postgres-native + simpler scope.

## Links

- Repo: <https://github.com/baserow/baserow>
- GitLab archive: <https://gitlab.com/baserow/baserow>
- Homepage: <https://baserow.io>
- Docs: <https://baserow.io/docs/index>
- API redoc: <https://api.baserow.io/api/redoc/>
- Community forum: <https://community.baserow.io/>
- Docker Hub: <https://hub.docker.com/r/baserow/baserow>
- Helm chart: <https://github.com/baserow/baserow/tree/master/deploy>
- Releases: <https://github.com/baserow/baserow/releases>
- Pricing: <https://baserow.io/pricing>
- Elestio: <https://elest.io/open-source/baserow>
- Sponsor: <https://github.com/sponsors/bram2w>
- NocoDB (alt): <https://github.com/nocodb/nocodb>
- Teable (alt): <https://github.com/teableio/teable>
- Mathesar (batch 75 alt): <https://github.com/mathesar-foundation/mathesar>
