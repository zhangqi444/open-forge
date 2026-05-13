---
name: Beaver Habit Tracker
description: "Self-hosted habit tracking app — no goals. NiceGUI-based Python. SaaS parallel. Multi-ecosystem derivatives (HabitDeck, Apple Shortcut, Home Assistant, CalDAV, OpenClaw Skill). Uptime Robot. daya0576/beaverhabits."
---

# Beaver Habit Tracker

Beaver Habit Tracker is **"Loop Habit Tracker — but self-hosted + web + ecosystem-integrated"** — a self-hosted habit tracking app with an explicit **"without Goals"** philosophy (just track, don't moralize). Vibrant derivatives ecosystem: Stream Deck / Apple Shortcut / Home Assistant / CalDAV / OpenClaw Skill.

Built + maintained by **daya0576**. NiceGUI-based Python likely. Docker. SaaS parallel (beaverhabits.com). Uptime Robot public monitoring. Unraid Community Apps listed.

Use cases: (a) **daily-habit tracking** (b) **streak visualization** (c) **journaling-adjacent habit log** (d) **Home Assistant automation trigger** (e) **iOS Shortcut quick-log** (f) **Stream Deck button-bind habits** (g) **CalDAV event-bridge** (h) **voice-log via OpenClaw Skill**.

Features (per README):

- **Habit tracking** — no goals
- **Self-hosted**
- **Docker + Fly.io + Unraid CA**
- **API** w/ How-to Guide
- **Rich ecosystem derivatives**
- **Uptime Robot public uptime**
- **SaaS parallel**

- Upstream repo: <https://github.com/daya0576/beaverhabits>
- SaaS: <https://beaverhabits.com>
- Demo: <https://beaverhabits.com/demo>
- API guide: <https://github.com/daya0576/beaverhabits/wiki/Beaver-Habit-Tracker-API-How%E2%80%90to-Guide>
- Derivatives:
  - HabitDeck (Stream Deck): <https://github.com/nov1n/HabitDeck>
  - OpenClaw Skill: <https://clawhub.ai/daya0576/beaverhabits>

## Architecture in one minute

- **Python + NiceGUI** likely
- SQLite default
- Docker-first
- **Resource**: very low
- **Port**: HTTP

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | Upstream                                                                                                               | **Primary**                                                                                   |
| **Unraid**         | Community Apps                                                                                                         | Alt                                                                                   |
| **Fly.io**         | Deploy template                                                                                                        | Alt                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `habits.example.com`                                        | URL          | TLS                                                                                    |
| Admin user/pass      | Bootstrap                                                   | Auth         |                                                                                    |
| API token            | For derivatives                                             | Secret       |                                                                                    |

## Install via Docker

Per README:
```yaml
services:
  beaverhabits:
    image: daya0576/beaverhabits:latest
    user: "1000:1000"  # Run as non-root for security
    environment:
      - HABITS_STORAGE=USER_DISK  # USER_DISK = per-user JSON files; DATABASE = single SQLite
      # - TRUSTED_LOCAL_EMAIL=you@example.com  # Skip login for trusted local access
    ports: ["8080:8080"]
    volumes:
      - ./beaver-data:/app/.user
    restart: unless-stopped
```

## First boot

1. Start
2. Sign up
3. Create habits
4. Enable API + get token (if using derivatives)
5. Test derivative (Stream Deck / HA / Shortcut)
6. Put behind TLS
7. Back up `/app/.user`

## Data & config layout

- `.user/` — per-user habit data (sensitive personal PII)

## Backup

```sh
sudo tar czf beaver-$(date +%F).tgz beaver-data/
# Contains: habit log = behavioral PII — **ENCRYPT**
```

## Upgrade

1. Releases: <https://github.com/daya0576/beaverhabits/releases>
2. Docker pull + restart

## Gotchas

- **189th HUB-OF-CREDENTIALS Tier 3 — HABIT-BEHAVIORAL-PII**:
  - Holds: daily habit-check data (behavioral PII — sleep, exercise, habits), API tokens for derivatives
  - **189th tool in hub-of-credentials family — Tier 3**
- **BEHAVIORAL-PII-HABIT-LOG**:
  - Habit log can reveal sensitive behaviors (sleep patterns, substance tracking, mood)
  - **Recipe convention: "behavioral-habit-log-PII-retention-discipline callout"**
  - **NEW recipe convention** (Beaver Habit 1st formally)
- **RICH-DERIVATIVES-ECOSYSTEM**:
  - HabitDeck + Apple Shortcut + Home Assistant + CalDAV + OpenClaw Skill
  - 5+ community-built integrations
  - **Recipe convention: "rich-community-derivatives-ecosystem positive-signal"**
  - **NEW positive-signal convention** (Beaver Habit 1st formally)
  - **Rich-community-derivatives: 1 tool** 🎯 **NEW FAMILY** (Beaver Habit — distinct from plugin-API which is first-party)
- **NO-GOALS-PHILOSOPHY**:
  - Explicit design philosophy ("just track")
  - **Recipe convention: "explicit-product-philosophy-design-choice neutral-signal"**
  - **NEW neutral-signal convention** (Beaver Habit 1st formally)
- **UPTIME-ROBOT-PUBLIC-MONITORING**:
  - Public uptime badge
  - **Recipe convention: "public-uptime-transparency-badge positive-signal"**
  - **NEW positive-signal convention** (Beaver Habit 1st formally)
  - **Public-uptime-monitoring: 1 tool** 🎯 **NEW FAMILY** (Beaver Habit)
- **UNRAID-COMMUNITY-APPS-LISTED**:
  - Easy Unraid deploy
  - **Recipe convention: "Unraid-Community-Apps-listed positive-signal"**
  - **NEW positive-signal convention** (Beaver Habit 1st formally)
  - **Unraid-Community-Apps-listed: 1 tool** 🎯 **NEW FAMILY** (Beaver Habit)
- **COMMERCIAL-SAAS-PARALLEL**:
  - beaverhabits.com commercial
  - **Commercial-parallel-with-OSS-core: 18 tools** 🎯 **18-TOOL MILESTONE** (+Beaver Habit)
- **FLY-IO-DEPLOY**:
  - Fly.io supported (like Podsync b124)
  - **Free-tier-PaaS-deploy-option: 2 tools** (Podsync+Beaver Habit) 🎯 **2-TOOL MILESTONE**
- **INSTITUTIONAL-STEWARDSHIP**: daya0576 sole-dev + SaaS-parallel + Uptime-public + Unraid CA + derivatives-ecosystem + demo + API-docs. **175th tool — sole-dev-ecosystem-rich-habit-tool sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + public-uptime + SaaS + derivatives + releases + API-docs. **181st tool in transparent-maintenance family.**
- **HABIT-TRACKER-CATEGORY:**
  - **Beaver Habit** — no-goals philosophy; Python; rich-derivatives
  - **Loop Habit Tracker** — Android-only (reference)
  - **Habitica** — gamified; MMO-style
  - **Everyday** — iOS/Android
- **ALTERNATIVES WORTH KNOWING:**
  - **Habitica** — if you want gamified
  - **Vikunja/Jotty** — if just want checklist
  - **Choose Beaver Habit if:** you want no-goals + web + rich-derivatives.
- **PROJECT HEALTH**: active + SaaS + ecosystem + Unraid + Fly. Strong.

## Links

- Repo: <https://github.com/daya0576/beaverhabits>
- SaaS: <https://beaverhabits.com>
- Habitica (alt): <https://github.com/HabitRPG/habitica>
