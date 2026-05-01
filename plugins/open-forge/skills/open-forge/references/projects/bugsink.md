---
name: Bugsink
description: "Self-hosted error tracking, Sentry-SDK compatible. Scalable + reliable. bugsink/bugsink. bugsink.com docs + screenshots. Docker quickstart one-liner."
---

# Bugsink

Bugsink is **"Sentry but lighter + self-host-first"** — a self-hosted error tracking platform fully compatible with Sentry SDK. Drop-in replacement for Sentry-endpoint URL. Built to self-host with **quick one-liner Docker spin-up**.

Built + maintained by **bugsink**. Docker-deployable. bugsink.com website with detailed docs.

Use cases: (a) **self-hosted Sentry replacement** (b) **error tracking for privacy-sensitive apps** (c) **cost-control alternative to Sentry cloud** (d) **on-prem error aggregation** (e) **Sentry-SDK compatibility without cloud** (f) **homelab application error monitoring** (g) **regulated-industry error tracking** (h) **small-team error alerting**.

Features (per README):

- **Sentry-SDK compatible** — drop-in
- **Self-hosted first** design
- **Scalable + reliable**
- **Docker quickstart**
- **Detailed docs on bugsink.com**

- Upstream repo: <https://github.com/bugsink/bugsink>
- Website: <https://www.bugsink.com>
- Docs: <https://www.bugsink.com/docs/>
- Quickstart: <https://www.bugsink.com/docs/quickstart/>
- Install guide: <https://www.bugsink.com/docs/installation/>

## Architecture in one minute

- Python/Django likely (Sentry-compat)
- DB store
- Sentry-compat ingest endpoint
- **Resource**: moderate (scales with event volume)
- **Port**: HTTP

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | Upstream one-liner                                                                                                     | **Primary**                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `errors.example.com`                                        | URL          | **TLS MANDATORY**                                                                                    |
| SECRET_KEY           | 50+ random chars                                            | Secret       | **Django-style; generate fresh**                                                                                    |
| Admin user/pass      | Create via CREATE_SUPERUSER                                 | Auth         |                                                                                    |
| PORT                 | 8000                                                        | Config       |                                                                                    |

## Install via Docker (one-liner from README)

```sh
docker pull bugsink/bugsink:latest        # **pin**
docker run \
  -e SECRET_KEY=PUT_AN_ACTUAL_RANDOM_SECRET_HERE_OF_AT_LEAST_50_CHARS \
  -e CREATE_SUPERUSER=admin:admin \
  -e PORT=8000 \
  -p 8000:8000 \
  bugsink/bugsink
```

## First boot

1. Set SECRET_KEY to ACTUAL random 50+ chars (NOT the placeholder!)
2. Use CREATE_SUPERUSER env w/ real password (NOT admin:admin!)
3. Open UI, login
4. Create project → get DSN
5. Point Sentry-SDK at Bugsink DSN instead of Sentry
6. Verify events flowing
7. Put behind TLS
8. Back up DB

## Data & config layout

- DB — errors + events + user accounts + projects

## Backup

```sh
# DB dump
# Contents: app error payloads (stack traces may contain sensitive data!) — **ENCRYPT**
```

## Upgrade

1. Releases: <https://github.com/bugsink/bugsink/releases>
2. Docker pull + restart
3. Migrations auto

## Gotchas

- **192nd HUB-OF-CREDENTIALS CROWN-JEWEL TIER 1 — ERROR-TRACKING-STACK-TRACES-SECRETS**:
  - Holds: **stack traces from your apps** — these frequently contain environment variables, tokens, SQL with data, request bodies with PII
  - Error events = accidental-secret-disclosure hotspot
  - **192nd tool in hub-of-credentials family — Tier 1 CROWN-JEWEL**
  - **NEW CROWN-JEWEL Tier 1 sub-category: "error-tracking + stack-trace-accidental-secret-disclosure"** (1st — Bugsink; distinct sensitivity type)
  - **CROWN-JEWEL Tier 1: 66 tools / 59 sub-categories**
- **DEFAULT-ADMIN-ADMIN-PLACEHOLDER**:
  - README shows `admin:admin` in quickstart
  - **MUST change for prod**
  - **Recipe convention: "README-quickstart-placeholder-credentials-warning callout"**
  - **NEW recipe convention** (Bugsink 1st formally)
- **50-CHAR-SECRET-KEY-MANDATORY**:
  - Explicit length requirement
  - **Recipe convention: "SECRET_KEY-generation-randomness-rotation-mandatory"** — reinforces Etebase (127)
- **STACK-TRACE-PII-DISCIPLINE**:
  - Python-style stack traces show variable values
  - Can contain passwords, tokens, user data
  - **Recipe convention: "stack-trace-PII-variable-value-scrubbing-discipline callout"**
  - **NEW recipe convention** (Bugsink 1st formally; HIGH-severity)
- **SENTRY-SDK-COMPAT-DROP-IN**:
  - Change-one-URL migration
  - **Recipe convention: "standard-SDK-compat-drop-in-migration positive-signal"**
  - **NEW positive-signal convention** (Bugsink 1st formally)
- **RETENTION-PLANNING**:
  - Error volume can balloon
  - **Recipe convention: "error-event-retention-volume-planning callout"**
  - **NEW recipe convention** (Bugsink 1st formally)
- **COMMERCIAL-PARALLEL**:
  - bugsink.com itself offers SaaS
  - **Commercial-parallel-with-OSS-core: 19 tools** 🎯 **19-TOOL MILESTONE** (+Bugsink)
- **SENTRY-ALTERNATIVE-CATEGORY**:
  - Bugsink + GlitchTip are the main Sentry-compat OSS servers
  - **Recipe convention: "alternative-to-commercial-tools-explicit-list positive-signal"** — reinforces Usertour (121)
- **INSTITUTIONAL-STEWARDSHIP**: bugsink org + website + detailed docs + Docker + Sentry-SDK-compat. **178th tool — small-team-error-tracking-stewardship sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + website + docs + Docker + quickstart. **184th tool in transparent-maintenance family.**
- **ERROR-TRACKING-CATEGORY:**
  - **Bugsink** — Sentry-SDK compat; self-host-first
  - **GlitchTip** — Sentry-SDK compat; alternative OSS
  - **Sentry (OSS)** — Apache 2 but complex deploy
  - **Sentry Cloud** — commercial
- **ALTERNATIVES WORTH KNOWING:**
  - **GlitchTip** — if you prefer alternative Sentry-compat OSS
  - **Sentry OSS** — if you want full-feature upstream
  - **Choose Bugsink if:** you want lightweight + self-host-first + Sentry-SDK-compat.
- **PROJECT HEALTH**: active + docs-site + Docker + SaaS-parallel. Strong.

## Links

- Repo: <https://github.com/bugsink/bugsink>
- Website: <https://www.bugsink.com>
- GlitchTip (alt): <https://gitlab.com/glitchtip>
- Sentry OSS: <https://github.com/getsentry/sentry>
