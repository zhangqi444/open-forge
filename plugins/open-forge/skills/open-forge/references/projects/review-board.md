---
name: Review Board
description: "Open-source web-based code + document review tool. Since 2006 — flexible workflows, MIT, Python. PyPI-distributed. reviewboard/reviewboard. reviewboard.org. Commercial services parallel."
---

# Review Board

Review Board is **"GitHub PR reviews — but self-hosted + workflow-flexible + since 2006"** — an open-source web-based code and document review tool. Designed to support diverse workflows from 2-person startups to enterprise teams of thousands. **Since 2006** — mature, long-lived. MIT licensed. Python. PyPI-distributed.

Built + maintained by **reviewboard** org (Beanbag Inc.). Commercial services parallel (support + hosted). PyPI primary distribution. Uses Review Board for its own development ("reviewed-with-badge").

Use cases: (a) **self-hosted pre-commit code review** (b) **patch-based workflows** (diff files, not just git) (c) **document review** (non-code) (d) **enterprise code-review compliance** (e) **alternative to GitHub/Gitlab PRs** (f) **legacy SCM integration** (g) **long-term code-review audit trail** (h) **regulated-industry review requirement**.

Features (per README):

- **Code + document review**
- **Workflow-flexible** — not tied to git
- **Since 2006** — mature
- **MIT licensed**
- **Python** + PyPI
- **Self-hosting** primary model
- **Commercial support** parallel

- Upstream repo: <https://github.com/reviewboard/reviewboard>
- Website: <https://www.reviewboard.org>
- PyPI: <https://pypi.org/project/reviewboard>

## Architecture in one minute

- **Python/Django**
- Postgres / MySQL / SQLite
- Memcached recommended
- **Resource**: moderate
- **Port**: HTTP

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **PyPI**           | `pip install reviewboard`                                                                                              | **Primary**                                                                                   |
| **Docker**         | Community images                                                                                                       | Alt                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `review.example.com`                                        | URL          | **TLS MANDATORY**                                                                                    |
| Python 3.x           | System                                                      | Runtime      |                                                                                    |
| DB                   | Postgres recommended                                        | DB           |                                                                                    |
| Memcached            | For performance                                             | Cache        |                                                                                    |
| SCM integrations     | git/hg/svn/perforce/etc.                                    | Integration  | Per-repository                                                                                    |
| Admin                | Bootstrap                                                   | Auth         |                                                                                    |

## Install

Follow official docs (non-trivial):
```sh
pip install reviewboard
rb-site install /var/www/reviews
# interactive setup: admin, DB, cache, path
```

Then front with gunicorn + nginx + TLS.

## First boot

1. `rb-site install` interactive setup
2. Configure web server
3. Point at DB + Memcached
4. Create admin + first project
5. Connect SCM repository
6. Invite team; test review flow
7. Put behind TLS
8. Back up DB

## Data & config layout

- DB — reviews, users, comments, attachments
- Static + media dirs (per rb-site)

## Backup

```sh
pg_dump reviewboard > reviewboard-$(date +%F).sql
# Contents: all review discussions + source-code snippets in diffs (potentially IP-sensitive code) — **ENCRYPT**
```

## Upgrade

1. Releases: <https://www.reviewboard.org/downloads/>
2. `pip install -U reviewboard`
3. `rb-site upgrade /var/www/reviews`

## Gotchas

- **197th HUB-OF-CREDENTIALS CROWN-JEWEL TIER 1 — SOURCE-CODE-REVIEWS-SCM-TOKENS**:
  - Holds: **source-code diffs** (your org's IP!), SCM tokens (git/hg/svn creds), user accounts, review discussions, attachments
  - Source-code IP is extremely sensitive — often trade-secret level
  - Long review history = codebase archaeology
  - **197th tool in hub-of-credentials family — Tier 1 CROWN-JEWEL**
  - **NEW CROWN-JEWEL Tier 1 sub-category: "code-review-tool + source-code-IP-repository"** (1st — Review Board; distinct from Gitea/Gitlab which are SCM, this is review-layer)
  - **CROWN-JEWEL Tier 1: 67 tools / 60 sub-categories** 🎯 **60-SUB-CATEGORY CROWN-JEWEL MILESTONE at Review Board**
- **SINCE-2006-TWO-DECADE-OSS**:
  - Among the oldest tools in the catalog
  - **Decade-plus-OSS: 16 tools** 🎯 **16-MILESTONE** (+Review Board)
  - **Two-decade-plus-OSS: 1 tool** 🎯 **NEW FAMILY** (Review Board — 20+ years distinct milestone vs decade-plus)
- **REVIEWED-WITH-BADGE**:
  - Self-hosting meta (they use Review Board to develop Review Board)
  - **Recipe convention: "self-dogfood-reviewed-with-badge positive-signal"**
  - **NEW positive-signal convention** (Review Board 1st formally)
  - Reinforces Maloja (128) "author-runs-public-instance-as-reference"
- **MULTI-SCM-INTEGRATION**:
  - git/hg/svn/perforce/etc.
  - **Recipe convention: "multi-SCM-integration-breadth positive-signal"**
  - **NEW positive-signal convention** (Review Board 1st formally)
- **ENTERPRISE-COMPLIANCE-USE-CASE**:
  - Regulated-industry code review
  - **Recipe convention: "regulated-industry-audit-trail-use-case positive-signal"**
  - **NEW positive-signal convention** (Review Board 1st formally)
- **COMMERCIAL-SERVICES-PARALLEL**:
  - Beanbag Inc. offers support + hosted
  - **Commercial-parallel-with-OSS-core: 22 tools** 🎯 **22-MILESTONE** (+Review Board)
- **RST-README-FORMAT**:
  - reStructuredText (not Markdown)
  - **Recipe convention: "reStructuredText-README-format neutral-signal"**
  - **NEW neutral-signal convention** (Review Board 1st formally — rare in modern catalog)
  - **reStructuredText-README: 1 tool** 🎯 **NEW FAMILY** (Review Board)
- **INSTITUTIONAL-STEWARDSHIP**: Beanbag Inc. + 20-year sustainable OSS + PyPI + commercial-parallel + reviewboard.org + self-dogfood. **183rd tool — 20-year-sustainable-OSS-company sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: 20-year active + PyPI + commercial + self-hosted + dogfooded. **189th tool in transparent-maintenance family.**
- **CODE-REVIEW-CATEGORY:**
  - **Review Board** — pre-git workflows; multi-SCM; 20-year
  - **Gerrit** — Google-origin; git-centric; complex
  - **Phabricator (fork: Phorge)** — legacy; community-fork
  - **GitLab CE** — bundles review with SCM
  - **Gitea + forks** — bundles review with SCM
- **ALTERNATIVES WORTH KNOWING:**
  - **Gerrit** — if you want git-centric + dominant
  - **Phorge** — if you want Phabricator-style + community-continued
  - **GitLab/Gitea** — if you want bundled SCM + review
  - **Choose Review Board if:** you want workflow-flexible + multi-SCM + patch-based + mature.
- **PROJECT HEALTH**: 20-year active + PyPI + commercial-backed + dogfooded. Exceptional.

## Links

- Repo: <https://github.com/reviewboard/reviewboard>
- Website: <https://www.reviewboard.org>
- Gerrit (alt): <https://www.gerritcodereview.com>
- Phorge (alt): <https://we.phorge.it>
