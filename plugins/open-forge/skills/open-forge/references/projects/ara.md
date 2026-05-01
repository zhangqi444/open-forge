---
name: ARA
description: "ARA Records Ansible — reporting for ansible/ansible-playbook runs regardless of host/tool. Django REST API + local-first web UI + CLI. SQLite/MySQL/PostgreSQL. Codeberg-mirrored + GitHub. ansible-community/ara."
---

# ARA

ARA Records Ansible — **"Jenkins-like history + a searchable UI for all your Ansible runs, across any tool"** — provides **Ansible reporting** by recording `ansible` and `ansible-playbook` commands regardless of how/where they run. Works from distros, Mac, tools like ansible-pull/test/runner/navigator, AWX, Automation Controller (Tower), Molecule, Semaphore; CI (Jenkins, Rundeck, Zuul); Git forges (GitHub/GitLab/Gitea/Forgejo). **Django REST API** + included **CLI** + **local-first web UI**.

Built + maintained by **ansible-community/ara** org (community-backed). Apache-2.0 likely. Codeberg mirror. Documentation at readthedocs. Recorded demo.

Use cases: (a) **audit-log of all Ansible runs** — compliance (b) **cross-CI Ansible reporting** — Jenkins + Zuul + GitLab (c) **troubleshoot failed plays** (d) **historical playbook database** (e) **team-collaboration history** (f) **Molecule test-result archive** (g) **per-environment run-log** (h) **fleet-wide Ansible observability**.

Features (per README):

- **Record Ansible via callback plugin**
- **Django REST API**
- **CLI** for querying
- **Local-first web UI**
- **SQLite/MySQL/PostgreSQL**
- **Any Ansible-running tool** or CI platform
- **Python ≥3.8** requirement

- Upstream repo: <https://github.com/ansible-community/ara>
- Codeberg mirror: <https://codeberg.org/ansible-community/ara>
- Docs: <https://ara.readthedocs.io>

## Architecture in one minute

- **Callback plugin** loaded by Ansible
- **Django REST API** server (receives records)
- **Web UI** (Django views)
- **Client library** + CLI
- **DB**: SQLite (default), MySQL, PostgreSQL
- **Resource**: low-moderate depending on data volume
- **Port**: 8000 or similar (Django)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Pip install**    | `pip install ara`                                               | **Primary** — installs plugin + server                                                                                    |
| **Docker**         | Community images                                                                                                       | Alt                                                                                   |
| **Ansible collection** | `ansible.builtin` + `ara` plugin                                                                                   | Alt                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `ara.example.com`                                           | URL          | TLS                                                                                    |
| DB                   | SQLite default; Postgres for scale                          | DB           |                                                                                    |
| Callback plugin      | Install on each Ansible runner                              | Integration  |                                                                                    |
| Auth                 | Optional (see docs)                                         | Auth         | Default: **open** — lock down!                                                                                    |
| Redaction rules      | What to ignore                                              | Config       |                                                                                    |

## Install

Quick pip install:
```sh
python3 -m pip install "ara[server]"
ara-manage migrate
ara-manage runserver 0.0.0.0:8000
```

Configure Ansible to use ARA callback:
```sh
export ANSIBLE_CALLBACK_PLUGINS="$(python -m ara.setup.callback_plugins)"
export ARA_API_CLIENT=http
export ARA_API_SERVER=http://localhost:8000
```

Any `ansible-playbook` command now records.

## First boot

1. Install
2. Run migrations
3. Start server
4. Point Ansible at it (via env vars)
5. Run a playbook; browse recorded output
6. **Enable authentication** for production
7. Configure redaction (don't record secrets)
8. Put behind TLS

## Data & config layout

- SQLite file OR Postgres DB
- Per-playbook: hosts, tasks, results, files, records

## Backup

```sh
# SQLite:
sudo cp /path/to/ansible.sqlite ansible-$(date +%F).sqlite
# PG:
pg_dump ara > ara-$(date +%F).sql
# **May contain secrets if redaction not configured — ENCRYPT**
```

## Upgrade

1. Releases: <https://github.com/ansible-community/ara/releases>
2. `pip install --upgrade ara`
3. `ara-manage migrate`
4. Read release notes

## Gotchas

- **146th HUB-OF-CREDENTIALS CROWN-JEWEL TIER 1 — ANSIBLE-FLEET-RUN-HISTORY**:
  - Records EVERY ansible-playbook invocation
  - Includes: task outputs (may contain secrets), target hosts, variable data, state
  - Leak = infra-blueprint + potentially-secrets
  - **146th tool in hub-of-credentials family — Tier 1 CROWN-JEWEL**
  - **NEW CROWN-JEWEL Tier 1 sub-category: "ansible-run-history + task-output-archive"** (1st — ARA; IaC-sensitive)
  - **CROWN-JEWEL Tier 1: 45 tools / 42 sub-categories**
- **SECRETS-IN-TASK-OUTPUT BY DEFAULT**:
  - Ansible task output often contains `no_log: false` leakage
  - ARA records whatever runs
  - **Recipe convention: "ansible-no_log-discipline-before-recording callout"**
  - **NEW recipe convention** (ARA 1st formally) — HIGHEST-severity
- **REDACTION-CONFIGURATION**:
  - ARA supports ignoring certain patterns
  - Must be configured; default records everything
  - **Recipe convention: "recording-tool-redaction-default-configure callout"**
  - **NEW recipe convention** (ARA 1st formally)
- **DEFAULT-OPEN-AUTH**:
  - Default: no authentication
  - Must explicitly enable for production
  - README emphasizes this
  - **Recipe convention: "default-open-auth-requires-explicit-lockdown callout"**
  - **NEW recipe convention** (ARA 1st formally) — reinforces unclear-auth-policy (112)
- **IAC-DATA-SENSITIVITY**:
  - Records = maps of your infra (hosts, roles, secrets-references)
  - Parallel to portracker (117) infra-discovery-map pattern
  - **Infra-data-sensitivity family: 3 tools** (portracker+ARA+Reitti-infra-analog) 🎯 **3-TOOL MILESTONE** — 3 distinct data-treasure-sensitivities: network, IaC, physical
- **BROAD-ANSIBLE-ECOSYSTEM-SUPPORT**:
  - Works with AWX, Tower, Molecule, Semaphore, Jenkins, Zuul, etc.
  - **Recipe convention: "broad-ecosystem-integration-support positive-signal"**
  - **NEW positive-signal convention** (ARA 1st formally)
- **CODEBERG-MIRRORED**:
  - GH is primary; Codeberg mirror = resilience
  - **Codeberg-mirrored: 1 tool** 🎯 **NEW FAMILY** (ARA) — operator-resilience signal
- **COMMUNITY-GOVERNED-ORG**:
  - ansible-community (not Red Hat directly)
  - **Recipe convention: "community-governed-OSS-org positive-signal"**
  - **NEW positive-signal convention** (ARA 1st formally)
- **RECURSIVE-ACRONYM**:
  - "ARA Records Ansible"
  - Playful + memorable
  - **Recipe convention: "recursive-acronym-naming neutral-signal"**
  - **NEW neutral-signal convention** (ARA 1st formally)
- **LOCAL-FIRST-WEB-UI**:
  - Web UI runs local by default
  - **Recipe convention: "local-first-web-UI positive-signal"** — reinforces Logdy (115)
- **INSTITUTIONAL-STEWARDSHIP**: ansible-community org + Codeberg mirror + readthedocs + demo-video + broad-ecosystem-support + CLI+API+UI. **132nd tool — community-governed-org-with-mirror sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + Codeberg mirror + readthedocs + demo + broad-integration + releases. **138th tool in transparent-maintenance family.**
- **ANSIBLE-TOOLING-CATEGORY:**
  - **ARA** — recording + reporting
  - **AWX** — Ansible Tower upstream
  - **Semaphore** — lighter UI
  - **ansible-pull + cron** — classic
- **ALTERNATIVES WORTH KNOWING:**
  - **AWX** — if you want full orchestration + UI
  - **Semaphore** — if you want lighter orchestration UI
  - **Choose ARA if:** you already run Ansible via your-own-tools but want central reporting.
- **PROJECT HEALTH**: active + community-governed + Codeberg-mirror + broad-ecosystem-support + docs + demo. Strong.

## Links

- Repo: <https://github.com/ansible-community/ara>
- Codeberg: <https://codeberg.org/ansible-community/ara>
- Docs: <https://ara.readthedocs.io>
- AWX (alt): <https://github.com/ansible/awx>
- Semaphore (alt): <https://github.com/semaphoreui/semaphore>
