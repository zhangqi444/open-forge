---
name: Usertour
description: "Open-source user onboarding platform. In-app product tours, checklists, surveys. Alternative to Appcues/Userpilot/Userflow/Userguiding/Chameleon. usertour org. Docker Compose. Discord + docs site."
---

# Usertour

Usertour is **"Appcues / Userpilot / Chameleon — but open-source + self-hostable + no per-seat pricing"** — in-app onboarding flows, product tours, checklists, surveys. Embed a small JS SDK on your app; drive flows from Usertour backend.

Built + maintained by **usertour** org. usertour.io website + docs + blog + Twitter + Discord. Commercial SaaS at usertour.io alongside OSS. Active.

Use cases: (a) **onboard new users** with guided tours (b) **feature-announcement flows** (c) **NPS + product surveys** (d) **onboarding checklists** (e) **help-content flow management** (f) **A/B-test onboarding** (g) **analytics on funnel drop-off** (h) **PM-owned in-app comms**.

Features (per README):

- **In-app product tours**
- **Checklists**
- **Surveys**
- **Self-deploy via Docker**
- **Unlimited** self-hosted version
- **Commercial SaaS** parallel

- Upstream repo: <https://github.com/usertour/usertour>
- Website: <https://usertour.io>
- Docs: <https://docs.usertour.io>
- Discord: <https://discord.gg/WPVJPX8fJh>

## Architecture in one minute

- Node.js likely + PostgreSQL
- JS SDK served to your app
- Dashboard for flow authoring
- Analytics storage (postgres or OLAP)
- **Resource**: moderate (~1GB)
- **Port**: 8011 default

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker Compose** | Upstream                                                        | **Primary**                                                                        |
| **Usertour SaaS**  | Cloud                                                                                                                  | Alt                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `usertour.example.com`                                      | URL          | TLS                                                                                    |
| `.env`               | Review `.env.example`                                       | Config       | All required envs                                                                                    |
| PostgreSQL           | Data                                                        | DB           |                                                                                    |
| Embed origin         | Your app's domain                                           | CORS         |                                                                                    |

## Install via Docker Compose

Per README:
```sh
cp .env.example .env   # set all required envs
docker compose up -d
# Visit http://localhost:8011
```
**Pin tag** in production:
```yaml
services:
  usertour:
    image: usertour/usertour:v0.X.Y        # **pin version**
    ports: ["8011:8011"]
    env_file: .env
```

## First boot

1. Set `.env` — DB connection, secrets, etc.
2. `docker compose up -d`
3. Visit :8011 and create admin
4. Create a project; get embed key
5. Embed JS SDK on your app with key
6. Build a flow in dashboard
7. Test with a user segment
8. Put behind TLS + CDN

## Data & config layout

- PostgreSQL — users, flows, analytics events
- Static JS bundle served to embedded apps

## Backup

```sh
docker compose exec postgres pg_dump -U $POSTGRES_USER usertour > usertour-$(date +%F).sql
# Contains flow configs + user-analytics PII — ENCRYPT
```

## Upgrade

1. Releases: <https://github.com/usertour/usertour/releases>
2. Diff `.env.example` for new required envs
3. Docker pull + restart

## Gotchas

- **157th HUB-OF-CREDENTIALS CROWN-JEWEL TIER 1 — IN-APP-ANALYTICS + PII + JS-EMBED**:
  - Holds: all-user-flow-analytics, user-PII (emails/IDs passed via SDK), embed-API-key
  - Embedded-JS-SDK = supply-chain-adjacent; compromise of Usertour = JS injection into embedding sites
  - **157th tool in hub-of-credentials family — Tier 1 CROWN-JEWEL**
  - **NEW CROWN-JEWEL Tier 1 sub-category: "in-app-onboarding-platform + embed-SDK-supply-chain-risk"** (1st — Usertour)
  - **CROWN-JEWEL Tier 1: 51 tools / 48 sub-categories**
- **EMBED-JS-XSS-SUPPLY-CHAIN**:
  - JS SDK runs on your customers' browsers via your app
  - Usertour compromise = JS injection across all embedding products
  - **Recipe convention: "embedded-tool-XSS-blast-radius"** — reinforces Coral (120)
- **USER-PII-PASSED-TO-USERTOUR**:
  - User IDs, emails, traits pushed via SDK
  - GDPR/CCPA subject
  - **Recipe convention: "analytics-SDK-PII-data-processor-agreement callout"**
  - **NEW recipe convention** (Usertour 1st formally)
- **COMMERCIAL-PARALLEL (Usertour SaaS)**:
  - **Commercial-parallel-with-OSS-core: 14 tools** 🎯 **14-TOOL MILESTONE**
- **"ALTERNATIVE-TO" COMMERCIAL POSITIONING**:
  - Explicit list: Appcues, Userpilot, Userflow, Userguiding, Chameleon
  - Clear commercial-positioning
  - **Recipe convention: "alternative-to-commercial-tools-explicit-list positive-signal"**
  - **NEW positive-signal convention** (Usertour 1st formally)
- **DISCORD-COMMUNITY**:
  - Active Discord chat
  - **Discord-community-channel: N tools** (many — continuing pattern)
- **UNLIMITED-WHEN-SELF-HOSTED**:
  - OSS lifts the SaaS usage caps
  - **Recipe convention: "self-host-removes-SaaS-limits positive-signal"**
  - **NEW positive-signal convention** (Usertour 1st formally)
- **.ENV-EXAMPLE-PATTERN**:
  - Require `.env.example` copy + edit before boot
  - **Recipe convention: "dotenv-example-explicit-copy positive-signal"**
  - **NEW positive-signal convention** (Usertour 1st formally)
- **INSTITUTIONAL-STEWARDSHIP**: usertour org + website + docs + blog + Twitter + Discord + SaaS. **143rd tool — product-led-startup-OSS sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + docs + blog + releases + SaaS-parallel. **149th tool in transparent-maintenance family.**
- **USER-ONBOARDING-CATEGORY:**
  - **Usertour** — OSS + multi-format (tours + surveys + checklists)
  - **Flows.sh** — OSS; tours
  - **Intro.js** — library; not a platform
  - **Shepherd.js** — library
  - **Appcues/Userpilot/Chameleon** — commercial
- **ALTERNATIVES WORTH KNOWING:**
  - **Intro.js / Shepherd.js** — if you just need tour library
  - **Appcues** — if you want commercial + support
  - **Choose Usertour if:** you want OSS + platform + analytics-included.
- **PROJECT HEALTH**: active + commercial-parallel + multi-channel-community + docs + blog. Strong.

## Links

- Repo: <https://github.com/usertour/usertour>
- Website: <https://usertour.io>
- Docs: <https://docs.usertour.io>
- Intro.js (lib alt): <https://github.com/usablica/intro.js>
- Shepherd.js (lib alt): <https://github.com/shipshapecode/shepherd>
