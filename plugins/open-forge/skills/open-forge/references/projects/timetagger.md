---
name: TimeTagger
description: "Web-based time-tracking — interactive timeline UI, tags-not-projects, PDF/CSV reports, Pomodoro. Async Python + uvicorn. PyPI + Docker. readthedocs docs. almarklein/timetagger. timetagger.app SaaS."
---

# TimeTagger

TimeTagger is **"Toggl / Harvest — but self-hosted + timeline-native + tag-based"** — a web-based time-tracking solution for individuals + freelancers. **Interactive timeline** UI, **tags-not-projects** philosophy, PDF/CSV reports, daily/weekly/monthly targets, experimental Pomodoro, responsive. Async Python + uvicorn.

Built + maintained by **almarklein**. PyPI + Docker. readthedocs docs. timetagger.app commercial SaaS-parallel. CLI tool in separate repo. 3rd-party VSCode extension.

Use cases: (a) **freelancer billing hours tracker** (b) **self-reported productivity tracking** (c) **client-hour reporting** (d) **timeline-based time visualization** (e) **Pomodoro-integrated time tracking** (f) **PDF invoice-ready reports** (g) **cross-device sync for small teams** (h) **VS Code time-tracking integration**.

Features (per README):

- **Interactive timeline UI**
- **Tags-not-projects**
- **PDF + CSV reports**
- **Daily/weekly/monthly targets**
- **Pomodoro** (experimental)
- **Responsive**
- **Multi-device sync**
- **Async Python** (uvicorn)

- Upstream repo: <https://github.com/almarklein/timetagger>
- Website: <https://timetagger.app>
- Demo: <https://timetagger.app/demo>
- Docs: <https://timetagger.readthedocs.io>
- CLI: <https://github.com/almarklein/timetagger_cli>
- VSCode ext (3rd party): <https://github.com/Yamakaze-chan/TimeTagger_VSCodeExtension>

## Architecture in one minute

- **Async Python + uvicorn**
- Likely SQLite
- PyPI-installable
- **Resource**: very low
- **Port**: HTTP

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | Upstream                                                                                                               | **Primary**                                                                                   |
| **PyPI**           | `pip install timetagger`                                                                                               | Alt                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `time.example.com`                                          | URL          | TLS                                                                                    |
| Admin                | Bootstrap                                                   | Auth         |                                                                                    |
| Storage              | SQLite                                                      | Data         |                                                                                    |

## Install via Docker

Per docs:
```yaml
services:
  timetagger:
    image: almarklein/timetagger:latest        # **pin**
    ports: ["8080:80"]
    volumes:
      - ./timetagger-data:/root/_timetagger
    restart: unless-stopped
```

## First boot

1. Start
2. Create user
3. Browse timeline; create first time entry with tags
4. Test PDF/CSV report
5. Configure targets
6. (Optional) Pomodoro
7. Put behind TLS
8. Back up `_timetagger/`

## Data & config layout

- `_timetagger/` — user DB (tags, entries, targets)

## Backup

```sh
sudo tar czf timetagger-$(date +%F).tgz timetagger-data/
# Contents: time-log = billable-hour truth (critical for freelancers) — **ENCRYPT**
```

## Upgrade

1. Releases: <https://github.com/almarklein/timetagger/releases>
2. Docker pull + restart

## Gotchas

- **194th HUB-OF-CREDENTIALS Tier 2 — BILLABLE-HOUR-LOG**:
  - Holds: time entries + tags (what client + project worked on when) — billable-hour truth
  - **Billable-hour-log is financially material** (invoicing evidence)
  - **194th tool in hub-of-credentials family — Tier 2**
- **BILLABLE-HOUR-INTEGRITY**:
  - Time log = financial record
  - Backup + tamper-evidence matter
  - **Recipe convention: "billable-time-log-tamper-evident-audit-trail positive-signal"**
  - **NEW positive-signal convention** (TimeTagger 1st formally)
- **COMMERCIAL-PARALLEL**:
  - timetagger.app SaaS
  - **Commercial-parallel-with-OSS-core: 20 tools** 🎯 **20-TOOL MILESTONE at TimeTagger**
- **PYPI-PLUS-DOCKER-DUAL-DISTRIBUTION**:
  - Both PyPI and Docker
  - **Recipe convention: "PyPI-plus-Docker-dual-distribution positive-signal"**
  - **NEW positive-signal convention** (TimeTagger 1st formally)
- **THIRD-PARTY-VSCODE-EXTENSION**:
  - Community extension in separate repo
  - **Third-party-ecosystem-extension: 1 tool** 🎯 **NEW FAMILY** (TimeTagger — distinct from first-party derivatives like Beaver Habit)
- **READTHEDOCS-DOCS-HOSTING**:
  - Standard Python-community docs host
  - **Recipe convention: "ReadTheDocs-hosted-docs neutral-signal"**
  - **NEW neutral-signal convention** (TimeTagger 1st formally)
- **ASYNC-PYTHON-UVICORN**:
  - Modern async Python
  - **Recipe convention: "async-Python-uvicorn-backend neutral-signal"**
  - **NEW neutral-signal convention** (TimeTagger 1st formally)
- **TAGS-NOT-PROJECTS-PHILOSOPHY**:
  - Explicit design philosophy (like Beaver Habit's "no-goals")
  - **Recipe convention: "explicit-product-philosophy-design-choice"** — reinforces Beaver Habit (127)
- **PDF-REPORTING**:
  - Client-ready output
  - **Recipe convention: "PDF-report-generation-output positive-signal"**
  - **NEW positive-signal convention** (TimeTagger 1st formally)
- **INSTITUTIONAL-STEWARDSHIP**: almarklein sole-dev + website + demo + docs + CLI-separate + SaaS-parallel + CI. **180th tool — sole-dev-freelancer-tool sub-tier** (NEW-soft) 🎯 **180-TOOL INSTITUTIONAL-STEWARDSHIP MILESTONE at TimeTagger**.
- **TRANSPARENT-MAINTENANCE**: active + SaaS + demo + docs + CI + releases. **186th tool in transparent-maintenance family.**
- **TIME-TRACKING-CATEGORY:**
  - **TimeTagger** — timeline + tags; freelancer-focused
  - **Traggo** — tag-based; Go; active
  - **Kimai** — PHP; invoicing-oriented
  - **Clockify / Toggl** — commercial SaaS
- **ALTERNATIVES WORTH KNOWING:**
  - **Traggo** — if you want lightweight + tag-based
  - **Kimai** — if you want invoicing-heavy
  - **Choose TimeTagger if:** you want timeline-UI + tags + Pomodoro + freelancer-sized.
- **PROJECT HEALTH**: active + SaaS + docs + demo + VSCode ecosystem. Strong.

## Links

- Repo: <https://github.com/almarklein/timetagger>
- Website: <https://timetagger.app>
- Traggo (alt): <https://github.com/traggo/server>
- Kimai (alt): <https://github.com/kimai/kimai>
