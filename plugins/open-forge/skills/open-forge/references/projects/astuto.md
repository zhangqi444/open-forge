---
name: Astuto
description: "Open-source customer feedback tool (roadmap + voting + moderation + webhooks). ⚠️ NO LONGER MAINTAINED (issue #487). Ruby on Rails. PG 14.5. riggraz sole, honest discontinuation notice."
---

# Astuto

Astuto is **"Canny.io / Upvoty / Roadmunk — but self-hosted + OSS + Ruby-on-Rails"** — an OSS **customer feedback tool** to collect, manage, prioritize user feedback. Public roadmap, voting, moderation queue, OAuth2 sign-in, webhooks, REST API, anonymous feedback option, branded customization.

## ⚠️ MAINTAINER STATUS: NOT MAINTAINED ANYMORE

Per README (top of file): **"Astuto is not maintained anymore! See [this issue](https://github.com/astuto/astuto/issues/487). Thanks everyone for the support :)"**

**Honest discontinuation notice** by maintainer riggraz. This is a **positive stewardship signal** — honesty beats silent abandonment. However, it means:

1. **No security patches** for this codebase
2. **Ruby/Rails dependency updates** will not land
3. **Docker image may drift** against modern base-images
4. **Forking** is possible and legitimate (OSS spirit)
5. **Existing instances** continue to work but age

**Recommendation for new deployments**: prefer **maintained alternatives** listed below. Astuto can be useful if (a) you accept maintenance burden yourself, (b) you fork and maintain, (c) short-term / PoC.

This recipe is preserved for **historical + fork-reference** purposes and to **document the honest-discontinuation pattern** (rare in OSS).

Built + maintained by **riggraz** (sole). License: check LICENSE. **No-longer-active**; PostgreSQL 14.5; Ruby on Rails.

Use cases (historical): (a) **replace Canny.io / Upvoty** OSS (b) **public product feedback site** (c) **internal feature-request board** (d) **community road-map**.

Features (per README — historical):

- **Roadmap** (public)
- **Simple Sign-In** (email + OAuth2)
- **Webhooks** (Jira, Trello, Slack, etc.)
- **REST API**
- **Moderation queue**
- **Anonymous feedback** option
- **Brand customization**
- **Invitation system**
- **Recap emails**

- Upstream repo: <https://github.com/astuto/astuto>
- Discontinuation issue: <https://github.com/astuto/astuto/issues/487>
- Docs repo (offline): <https://github.com/astuto/astuto-docs>

## Architecture in one minute

- **Ruby on Rails**
- **PostgreSQL** 14.5
- **Docker Compose**
- **Resource**: moderate — 300-600MB RAM

## Compatible install methods (historical)

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker Compose** | `riggraz/astuto:latest` + PG 14.5                              | Historical; may drift                                                                                    |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `feedback.example.com`                                      | URL          | TLS                                                                                    |
| Admin creds          | First-boot                                                  | Bootstrap    |                                                                                    |
| PostgreSQL 14.5      | Data                                                        | DB           | Aging stack                                                                                    |
| SMTP                 | For recap + notifications                                   | Config       |                                                                                    |
| OAuth2 (opt)         | Sign-in provider                                            | Config       |                                                                                    |

## Install via Docker (historical, not recommended for new)

```yaml
services:
  db:
    image: postgres:14.5
    environment:
      POSTGRES_USER: astuto
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes: [dbdata:/var/lib/postgresql/data]
  web:
    image: riggraz/astuto:latest        # **frozen; not recommended**
    # ... (see upstream; don't expose publicly without review)

volumes:
  dbdata: {}
```

## Gotchas

- **120th HUB-OF-CREDENTIALS TIER 2 — CUSTOMER-FEEDBACK-DATA**:
  - Holds customer emails, IP-addresses, feedback-content, OAuth-tokens
  - **120th tool in hub-of-credentials family — Tier 2**
- **⚠️ NOT MAINTAINED = ACUTE SECURITY RISK**:
  - No CVE patches
  - Ruby/Rails has regular CVEs
  - PostgreSQL 14.5 may outlive support
  - **Recipe convention: "unmaintained-but-honestly-declared" stewardship pattern**
  - **NEW recipe convention** (Astuto 1st formally for discontinuation-declared tools)
- **HONEST-DISCONTINUATION = POSITIVE STEWARDSHIP DESPITE NEGATIVE OUTCOME**:
  - "Not maintained anymore" banner is HONEST
  - Contrast with silent-abandonment (far more common)
  - **NEW institutional-stewardship sub-tier: "honest-discontinuation-notice"** (1st — Astuto; aligns with but distinct from Scriberr 109 "paused-but-not-abandoned")
    - Distinction: Scriberr = honest-pause-intending-return; Astuto = honest-permanent-discontinuation
- **FORKING IS LEGITIMATE**:
  - OSS spirit; if you need it long-term, fork + patch
  - **Recipe convention: "fork-opportunity-for-abandoned-OSS" callout**
  - **NEW recipe convention** (Astuto 1st formally)
- **PRODUCT-HUNT LAUNCH-ARTIFACT**:
  - README has Product Hunt badge (launched publicly)
  - **Recipe convention: "Product-Hunt-launch-artifact" neutral-signal**
- **CUSTOMER-FEEDBACK-DATA-LEGAL-EXPOSURE**:
  - Feedback DB = contains customer messages (may contain PII, complaints, legal threats)
  - Compromise could affect customer-relations
  - **Recipe convention: "customer-feedback-legal-exposure" callout**
  - **NEW recipe convention** (Astuto 1st formally)
- **INSTITUTIONAL-STEWARDSHIP**: riggraz sole + honest-discontinuation + community-thank-you + GitHub-archive-preserved. **106th tool — honest-discontinuation-notice sub-tier** (NEW — exceptional despite being project-end).
- **TRANSPARENT-MAINTENANCE**: **NO — discontinued**. Does NOT count toward transparent-maintenance family (requires ACTIVE maintenance).
- **HONEST-DISCONTINUATION-SUB-TIER FAMILY**:
  - **Astuto** — clean project-end
  - **Scriberr (109)** — paused-but-not-abandoned (distinct; intent-to-return)
  - **Honest-maintainer-declaration: 2 tools** 🎯 **2-TOOL MILESTONE** (honest-pause + honest-end)
- **CUSTOMER-FEEDBACK-TOOL-CATEGORY (active alternatives):**
  - **Canny** (commercial) — mature; well-funded
  - **Upvoty** (commercial)
  - **Productboard** (commercial) — enterprise
  - **Fider** (OSS) — Go; self-hostable; **ACTIVELY MAINTAINED** (preferred OSS alt)
  - **FeatureOS** (commercial)
- **ALTERNATIVES WORTH KNOWING — PREFERRED FOR NEW DEPLOYMENTS:**
  - **Fider** — if you want OSS + actively-maintained
  - **Canny** — if you want mature + hosted
  - **Choose Astuto only if:** you're already running it, or forking for a specific need.
- **PROJECT HEALTH**: **DISCONTINUED**. Honest notice. Preservation-value: stewardship-example + fork-base.

## Links

- Repo (archived/discontinued): <https://github.com/astuto/astuto>
- Discontinuation issue: <https://github.com/astuto/astuto/issues/487>
- Fider (active alt): <https://github.com/getfider/fider>
- Canny (commercial alt): <https://canny.io>
