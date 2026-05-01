---
name: Taiga
description: "Feature-rich agile project management tool. Scrum + Kanban + Issues + Wiki. Django/Python backend + AngularJS frontend. .env-based deploy (as of 6.6.0). PostgreSQL. taigaio org."
---

# Taiga

Taiga is **"Jira — but open-source + agile-first + prettier"** — a feature-rich project management platform. Supports **Scrum + Kanban + Issues + Wiki** workflows. Multi-project, multi-user, with roles + permissions. Commercial-parallel: Taiga Cloud exists. `.env`-based deployment (since 6.6.0; migration-guide for earlier).

Built + maintained by **Kaleidos / taigaio** org. Long-running (decade+). License: **AGPL-3.0** (strong copyleft). Docker-compose-based deploy via `taiga-docker` repo.

Use cases: (a) **Scrum/Kanban for dev teams** (b) **replace Jira** (c) **open-source agile PM** (d) **wiki + issues + sprints in one** (e) **self-hosted PM for compliance** (f) **startup scrum board** (g) **multi-project portfolio** (h) **user-story-driven dev**.

Features (per README + docs):

- **Scrum** — backlogs, sprints, burndown, task-board
- **Kanban** — swim lanes, WIP limits
- **Issues** — type/priority/severity
- **Wiki** per project
- **Epics** for cross-project initiatives
- **Custom fields + tags**
- **Webhooks + API**
- **LDAP/OAuth/SAML** auth options
- **Webhook-based integrations**

- Upstream repo (docker): <https://github.com/taigaio/taiga-docker>
- Backend: <https://github.com/taigaio/taiga-back>
- Frontend: <https://github.com/taigaio/taiga-front>
- Docs: <https://docs.taiga.io>

## Architecture in one minute

- **Taiga-back** (Django/Python) — API server
- **Taiga-front** (AngularJS SPA)
- **Taiga-events** (Django Channels) — real-time
- **Taiga-protected** — download-protected assets
- **PostgreSQL** — data
- **Redis** — cache + events
- **RabbitMQ** — messaging
- **Nginx** — reverse proxy (recommended)
- **Resource**: 2-3GB RAM typical — it's the most-complex-stack we've catalogued for PM

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker Compose** | **Official `taiga-docker` repo**                                | **Primary — `stable` branch for prod**                                                                        |
| **Manual**         | Per-component install                                                                                                  | Harder                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `taiga.example.com`                                         | URL          | TLS                                                                                    |
| Superuser creds      | Via `taiga-manage.sh createsuperuser`                       | Bootstrap    |                                                                                    |
| PostgreSQL           | Data                                                        | DB           |                                                                                    |
| Redis                | Cache + events                                              | Infra        |                                                                                    |
| RabbitMQ             | Messaging                                                   | Infra        |                                                                                    |
| Email SMTP           | Notifications                                               | Channels     | Per-org SMTP                                                                                    |
| Auth providers (opt) | LDAP/OAuth/SAML                                             | Auth         |                                                                                    |

## Install via Docker

```sh
git clone -b stable https://github.com/taigaio/taiga-docker.git
cd taiga-docker

# edit .env with domain + secrets
cp .env.example .env

./launch-taiga.sh
./taiga-manage.sh createsuperuser
```

Put nginx/Caddy/Traefik in front for TLS. App runs at localhost:9000 by default.

## First boot

1. Configure `.env`
2. Launch stack
3. Create superuser
4. Log in; change admin password
5. Create first project
6. Test workflows (Scrum or Kanban)
7. Configure SMTP for notifications
8. Optional: configure LDAP/OAuth
9. Put behind TLS
10. Back up PG + user-uploaded-media

## Data & config layout

- **PostgreSQL** — projects, users, issues, wiki, history
- **media** volume — user uploads (attachments)
- **static** volume — served assets

## Backup

```sh
docker compose exec db pg_dump -U taiga taiga > taiga-$(date +%F).sql
sudo tar czf taiga-media-$(date +%F).tgz media/
# **Contains projects, user-uploaded files, emails — ENCRYPT**
```

## Upgrade

1. Releases: <https://github.com/taigaio/taiga-docker/releases>. Active.
2. `git pull` + `./launch-taiga.sh`
3. **Migration 6.6.0**: old docker layout → .env-based
4. Read CHANGELOG for breaking changes

## Gotchas

- **142nd HUB-OF-CREDENTIALS CROWN-JEWEL TIER 1 — PROJECT-PM-CENTRAL**:
  - Holds all project history, user stories, bug details, internal wikis, API tokens, attachments (may include screenshots of prod systems)
  - **142nd tool in hub-of-credentials family — Tier 1 CROWN-JEWEL**
  - **NEW CROWN-JEWEL Tier 1 sub-category: "project-management + internal-wiki + issue-tracker-combined"** (1st — Taiga; distinct from simple task tools)
  - **CROWN-JEWEL Tier 1: 43 tools / 40 sub-categories** 🎯 **40-SUB-CATEGORY MILESTONE at Taiga**
- **MULTI-SERVICE-STACK-COMPLEXITY**:
  - Django + Channels + Nginx + Postgres + Redis + RabbitMQ = 6 services
  - Most-complex stack we've recipe'd
  - **Microservice-complexity-tax: 7 tools** (+Taiga) 🎯 **7-TOOL MILESTONE**
- **AGPL-3.0-STRONG-COPYLEFT**:
  - Hosting for-profit = might need to release modifications
  - Internal-use = OK
  - **Recipe convention: "AGPL-network-service-copyleft"** — reinforces
- **ATTACHMENTS-MAY-CONTAIN-SECRETS**:
  - Screenshots with passwords, credentials in prose, etc.
  - **Recipe convention: "attachment-secret-spillover callout"**
  - **NEW recipe convention** (Taiga 1st formally) — reinforces credentials-in-notes pattern
- **DECADE-PLUS-OSS**:
  - **Decade-plus-OSS: 6 tools** (+Taiga) 🎯 **6-TOOL MILESTONE**
- **STABLE-BRANCH-PRODUCTION-DISCIPLINE**:
  - `stable` branch for prod; `main` for dev
  - Explicit in README
  - **Recipe convention: "branch-discipline-stable-vs-main positive-signal"**
  - **NEW positive-signal convention** (Taiga 1st formally)
- **MIGRATION-GUIDE-FOR-MAJOR**:
  - 6.6.0 moved to .env-based
  - Reinforces Tasks.md (117) author-provided-migration-guide pattern
  - **Author-provided-migration-guide: 2 tools** (Tasks.md+Taiga) 🎯 **2-TOOL MILESTONE**
- **TAIGA-MANAGE.SH CLI WRAPPER**:
  - Django manage.py proxy for admin tasks
  - **Recipe convention: "CLI-admin-wrapper positive-signal"**
  - **NEW positive-signal convention** (Taiga 1st formally)
- **COMMERCIAL-PARALLEL**:
  - Taiga Cloud (hosted SaaS)
  - **Commercial-parallel-with-OSS-core: 11 tools** 🎯 **11-TOOL MILESTONE**
- **INSTITUTIONAL-STEWARDSHIP**: Kaleidos/taigaio + decade+ + docs-site + multi-repo + AGPL + commercial-parallel + stable-branch-discipline + migration-guides. **128th tool — corporate-backed-decade-plus sub-tier**.
- **TRANSPARENT-MAINTENANCE**: active + multi-repo + docs + releases + migration-guide + CHANGELOG + stable-branch. **134th tool in transparent-maintenance family.**
- **PROJECT-MGMT-CATEGORY:**
  - **Taiga** — feature-rich; Scrum+Kanban+Wiki; AGPL
  - **OpenProject** — feature-rich competitor; GPL
  - **Plane** — modern; Django+Next.js; active
  - **Focalboard** — lighter; Kanban
  - **Vikunja** — lighter; task-focused
  - **Wekan** — Kanban-only; mature
- **ALTERNATIVES WORTH KNOWING:**
  - **OpenProject** — if you want enterprise-y PM
  - **Plane** — if you want modern lighter-weight
  - **Focalboard** — if you only want Kanban + lighter
  - **Choose Taiga if:** you want Scrum + Kanban + Wiki + AGPL + decade-proven.
- **PROJECT HEALTH**: mature + corporate-backed + multi-repo + commercial-parallel. Reference-grade.

## Links

- Repo: <https://github.com/taigaio/taiga-docker>
- Docs: <https://docs.taiga.io>
- OpenProject (alt): <https://github.com/opf/openproject>
- Plane (alt): <https://github.com/makeplane/plane>
