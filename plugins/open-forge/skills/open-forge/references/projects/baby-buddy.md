---
name: Baby Buddy
description: "Track baby sleep/feeding/diapers/tummy-time/growth. Django + Bootstrap. Multi-child + multi-caregiver. BSD-2-Clause. babybuddy org; community translations (25+ languages); coverage + CI. Active. demo.baby-buddy.net."
---

# Baby Buddy

Baby Buddy is **"infant-tracker web app + API for obsessive new parents"** — tracks sleep, feedings, diaper changes, tummy time, temperature, notes, weight/height/growth, and more for each child. Designed to help new caregivers **see patterns** in baby's needs + predict cries/sleep before they happen. Django-based; clean Bootstrap UI; per-user language; **25+ community-translated languages**; multi-child + multi-caregiver; API + mobile-friendly; browser notifications.

Built + maintained by **babybuddy organization** + community. License: **BSD-2-Clause**. Active; CI + Coveralls coverage; demo site at demo.baby-buddy.net (resets hourly); SECURITY.md + docs.baby-buddy.net; GitHub Codespaces.

Use cases: (a) **new parent sanity** — 3am feeds clearer after seeing 4-week pattern (b) **shared-parenting tracking** — dad + mom + nanny all log same child (c) **pediatrician visits** — show the app during checkup (d) **multi-child family** — single instance for multiple kids (e) **sleep-training data** — objective sleep-patterns (f) **growth tracking** — weight/height over time (g) **API for integrations** — home-automation (e.g., lit-button logs "diaper change"; crib-sensor logs sleep) (h) **tummy-time + development** — milestone tracking.

Features (per README):

- **Sleep, feedings, diaper changes, tummy time, temperature, notes, weight/height**
- **Multi-child** + **multi-caregiver**
- **25+ languages** (community-translated)
- **API** for integrations
- **Demo instance** at demo.baby-buddy.net
- **Mobile-responsive** UI
- **Timezone + unit preferences** per-user

- Upstream repo: <https://github.com/babybuddy/babybuddy>
- Docs: <https://docs.baby-buddy.net>
- Demo: <https://demo.baby-buddy.net> (admin/admin; resets hourly)
- Security: <https://github.com/babybuddy/babybuddy/blob/master/SECURITY.md>

## Architecture in one minute

- **Python + Django** backend
- **Bootstrap + vanilla JS** frontend
- **SQLite / PostgreSQL / MySQL** DB
- **Resource**: low — 200-400MB RAM
- **Port 8000** default

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **`lscr.io/linuxserver/babybuddy`** + official images           | **Primary**                                                                        |
| **pip / source**   | Django typical                                                                            | Alt                                                                                   |
| **GitHub Codespaces** | Ready-to-code dev env                                                                                                              | Dev                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `baby.example.com`                                          | URL          | TLS MANDATORY                                                                                    |
| DB                   | SQLite / PostgreSQL / MySQL                                 | DB           | PostgreSQL for multi-user reliability                                                                                    |
| `SECRET_KEY`         | Django signing                                              | **CRITICAL** | **IMMUTABLE**                                                                                    |
| Admin creds          | First-boot                                                  | Bootstrap    | Strong                                                                                    |
| Child records        | Child name, DOB                                             | Bootstrap    |                                                                                    |
| Caregiver accounts   | One per caregiver                                                                                   | Bootstrap    |                                                                                    |
| Timezone + units     | Per-user preferences                                                                                                      | Config       | Imperial vs Metric                                                                                                            |

## Install via Docker

Follow upstream docs: <https://docs.baby-buddy.net/setup/deployment/>

```yaml
services:
  babybuddy:
    image: lscr.io/linuxserver/babybuddy:latest        # **pin version**
    environment:
      PUID: 1000
      PGID: 1000
      TZ: America/Los_Angeles
      SECRET_KEY: ${SECRET_KEY}
      DB_ENGINE: postgresql
      POSTGRES_USER: babybuddy
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: babybuddy
      POSTGRES_HOST: db
    volumes:
      - babybuddy-config:/config
    ports: ["8000:8000"]
    depends_on: [db]

  db:
    image: postgres:17
    environment:
      POSTGRES_DB: babybuddy
      POSTGRES_USER: babybuddy
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes: [pgdata:/var/lib/postgresql/data]

volumes:
  babybuddy-config: {}
  pgdata: {}
```

## First boot

1. Start stack → browse `:8000`
2. Log in as admin; change password
3. Add child record (name + DOB)
4. Add caregivers (invite-only)
5. Per-user: set timezone + units
6. Install app on phone home-screen (PWA)
7. Log first entry → test timeline
8. Set up API tokens (optional) for automations
9. Configure notification for 4h-no-feed, etc.
10. Back up DB

## Data & config layout

- `/config/` — Django settings + media
- PostgreSQL — all child/caregiver data
- Per-child timeline with thousands of entries accumulated over months/years

## Backup

```sh
docker compose exec db pg_dump -U babybuddy babybuddy > babybuddy-$(date +%F).sql
sudo tar czf babybuddy-config-$(date +%F).tgz babybuddy-config/
```

## Upgrade

1. Releases: <https://github.com/babybuddy/babybuddy/releases>. Active.
2. Docker pull + restart; migrations auto-run
3. **Back up BEFORE** (years of baby data)

## Gotchas

- **CHILD DATA = HIGHEST-SENSITIVITY PII + CROWN-JEWEL**:
  - Data tracked: child name, DOB, weight, height, health metrics, feeding frequency, sleep, diaper-contents-notes, medical notes
  - Child data under 13 = **COPPA** (US), **GDPR-K** (EU), other jurisdictions' child-data laws
  - Shared with CARE-GIVER accounts (family/nannies) — need-to-know basis
  - **85th tool in hub-of-credentials family — Tier 1 CROWN-JEWEL**
  - **NEW CROWN-JEWEL Tier 1 sub-category: "child-data-tracking-tool"** — 1st tool named (Baby Buddy)
  - **CROWN-JEWEL Tier 1: 21 tools; 19 sub-categories**
  - **Recipe convention: "COPPA/GDPR-K child-data protection" convention** (MANDATORY for child-data tools)
  - **NEW recipe convention**
- **FAMILY-DATA-CROWN-JEWEL META-FAMILY**:
  - Baby Buddy joins Gramps (103) in tracking family + personal-relationship data
  - **NEW META-FAMILY: "family-data-CROWN-JEWEL"** — 2 tools (Gramps + Baby Buddy)
  - Gramps = deceased + living ancestors
  - Baby Buddy = children (highest-sensitivity sub-category)
- **MULTI-CAREGIVER = ACCESS-CONTROL IMPORTANT**:
  - Per-caregiver accounts with appropriate permissions
  - When caregivers leave (former nanny, ex-partner) → REVOKE access
  - **Recipe convention: "caregiver-access-revocation-discipline" callout**
  - **NEW recipe convention**
- **DEMO-CREDENTIALS admin/admin**:
  - For PUBLIC DEMO at demo.baby-buddy.net (resets hourly)
  - Not for self-hosted production — always change defaults
  - **Default-creds-risk family: 10 tools now** (+Baby Buddy demo)
- **BSD-2-CLAUSE LICENSE**:
  - Permissive (no copyleft)
  - Fork-friendly
  - **Recipe convention: "permissive-BSD/MIT-license" positive-signal** — no strong-copyleft restrictions
- **SECRET_KEY IMMUTABILITY**: **49th tool in immutability-of-secrets family.**
- **25+ LANGUAGES + COMMUNITY TRANSLATIONS**:
  - Extensive localization coverage
  - **Recipe convention: "community-translations-wide-coverage" positive-signal**
  - Note: README doesn't mention specific tool (Weblate vs Crowdin vs Transifex); still high coverage
- **BABY-DATA LONG-TERM RETENTION**:
  - Data useful while child is infant (0-3 years typically)
  - Long-term: historical-context for medical history later in life
  - **Retention policy**: consider export + preservation even after active-use
  - **Recipe convention: "long-term-personal-data-archive" applies** (Papermerge 103 precedent) — now 2 tools
- **SECURITY.md PRESENT**:
  - Dedicated SECURITY.md documenting responsible-disclosure
  - **Recipe convention: "dedicated-SECURITY.md-file" positive-signal**
  - **NEW positive-signal convention** (Baby Buddy 1st formally)
- **CODESPACES-READY**:
  - Ready-to-code in Codespaces
  - Low-friction contribution
  - **Recipe convention: "Codespaces-ready-dev-env" positive-signal**
  - **NEW positive-signal convention**
- **PUBLIC DEMO WITH HOURLY RESET**:
  - demo.baby-buddy.net for try-before-install
  - Hourly reset = clean state
  - **Recipe convention: "hourly-reset-demo-site" positive-signal**
- **INSTITUTIONAL-STEWARDSHIP**: babybuddy org + large community + translators + multi-language. **71st tool — community-project-with-translator-network sub-tier** (similar to YunoHost's EU-funded or Gramps' project-governance; babybuddy is community-governed)
  - **Reinforces "large-community-project with project-governance" sub-tier** (now 2 tools: Gramps + Baby Buddy)
- **TRANSPARENT-MAINTENANCE**: active + CI + Coveralls + demo + docs + SECURITY.md + Codespaces + 25+ languages + BSD-2-Clause + code-style-black. **79th tool in transparent-maintenance family.**
- **PARENTING-TRACKER-CATEGORY (rare):**
  - **Baby Buddy** — OSS
  - **Huckleberry** — commercial iOS/Android
  - **Baby Tracker** — commercial
  - **Ovia Parenting** — commercial
  - **Sprout Baby** — commercial
- **ALTERNATIVES WORTH KNOWING:**
  - **Huckleberry / Baby Tracker / etc.** — commercial mobile; richer ML-predictions
  - **Pen-and-paper logbook** — minimal viable solution
  - **Choose Baby Buddy if:** you want OSS + BSD + self-hosted + multi-caregiver + 25-languages.
- **PROJECT HEALTH**: active + CI + coverage + docs + demo + SECURITY.md + 25-languages + code-style-black. EXCELLENT.

## Links

- Repo: <https://github.com/babybuddy/babybuddy>
- Docs: <https://docs.baby-buddy.net>
- Demo: <https://demo.baby-buddy.net>
- Security: <https://github.com/babybuddy/babybuddy/blob/master/SECURITY.md>
- Huckleberry (commercial alt): <https://huckleberrycare.com>
