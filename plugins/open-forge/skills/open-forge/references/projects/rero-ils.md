# RERO ILS

**Large-scale Integrated Library System (ILS) for library networks** — full-featured open-source ILS with circulation, acquisitions, cataloging, serial management, and a web-based interface for both staff and patrons. Built on the Invenio framework, supports consortial multi-library networks.

**Official site:** https://rero21.ch
**Source:** https://github.com/rero/rero-ils
**License:** AGPL-3.0
**Demo:** https://ils.test.rero.ch

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Linux VPS / bare metal | Docker Compose | Recommended for self-hosted deployments |
| Hosted service | RERO+ managed | Available as SaaS from RERO+ for libraries |

---

## Inputs to Collect

### Phase 1 — Planning
- Single library vs library network/consortium
- Whether to use RERO's public MEF authority server or run your own
- Domain / hostname

### Phase 2 — Deploy
- PostgreSQL credentials
- Elasticsearch/OpenSearch credentials
- Redis connection
- Mail/SMTP config
- MEF server URL (default: `https://mef.test.rero.ch` for testing)

---

## Software-Layer Concerns

- **Stack:** Python (Invenio framework), PostgreSQL, Elasticsearch/OpenSearch, Redis, Celery workers
- **Three repos:**
  - `rero-ils` — main backend (Invenio-based)
  - `rero-ils-ui` — Angular frontend
  - `ng-core` — shared Angular components
- **MEF dependency:** RERO ILS requires a running MEF (Multilingual Entity File) server for authority records (authors, subjects); use RERO's public MEF server (`mef.test.rero.ch`) or self-host
- **Complex stack:** Substantial infrastructure requirements; intended for library networks, not single casual users
- **Installation:** Follow `INSTALL.md` in the repository

---

## Deployment

Follow the official installation guide:
https://github.com/rero/rero-ils/blob/master/INSTALL.md

For development environment setup:
https://github.com/rero/developer-resources/blob/master/rero-instances/rero-ils/dev_installation.md

---

## Upgrade Procedure

Follow upstream release notes and migration guides:
https://github.com/rero/rero-ils/releases

Always back up PostgreSQL and Elasticsearch data before upgrading. Run Invenio DB/index migrations after updating.

---

## Gotchas

- **High infrastructure complexity** — requires PostgreSQL + Elasticsearch/OpenSearch + Redis + Celery; not a lightweight install
- **MEF server required** — without a MEF instance, authority/entity linking won't work; use RERO's public MEF for testing
- **Primarily for library networks** — designed for consortial use; single-library installs are possible but the feature set is oriented toward networks
- **French/Swiss origin** — primary development team is Swiss; some docs and UI strings are French-first
- **Frontend is a separate repo** — `rero-ils-ui` must be built/deployed alongside the backend

---

## Links

- Upstream README: https://github.com/rero/rero-ils#readme
- Installation guide: https://github.com/rero/rero-ils/blob/master/INSTALL.md
- User documentation: https://bib.rero.ch/help/home/
- Developer resources: https://github.com/rero/developer-resources
- Demo: https://ils.test.rero.ch
