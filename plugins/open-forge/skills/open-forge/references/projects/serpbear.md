---
name: SerpBear
description: "Open-source search engine position tracking + keyword research app. Unlimited keywords. Google SERP scraping via third-party APIs. Google Ads + GSC integration. Node.js. towfiqi/serpbear. Docker Hub. Docs + CHANGELOG + Codacy."
---

# SerpBear

SerpBear is **"AccuRanker / Semrush / Ahrefs rank-tracker — but self-hosted + OSS"** — search engine position tracking and keyword research. **Unlimited domains + keywords**. Email notifications on position change. Built-in API. Google Ads + GSC integrations. PWA mobile app.

Built + maintained by **towfiqi**. Codacy code-quality. Docs site + CHANGELOG. Docker Hub (`towfiqi/serpbear`). Free-tier-friendly (can run on Fly.io / mogenius.com).

Use cases: (a) **track Google rankings** for your domain (b) **competitor rank tracking** (c) **keyword research + ideation** (d) **monthly search-volume-lookup** via Google Ads (e) **GSC-actual-visits correlation** (f) **email alerts on ranking drops** (g) **SEO reporting API** for custom dashboards (h) **Semrush-alternative self-hosted**.

Features (per README):

- **Unlimited keywords + domains**
- **Email notification** (daily/weekly/monthly)
- **SERP API** built-in
- **Keyword research** via Google Ads
- **GSC integration** for real visits
- **PWA mobile app**
- **Zero-cost deploy** (Fly.io / mogenius.com)

- Upstream repo: <https://github.com/towfiqi/serpbear>
- Docs: <https://docs.serpbear.com>
- CHANGELOG: <https://github.com/towfiqi/serpbear/blob/main/CHANGELOG.md>
- Docker: <https://hub.docker.com/r/towfiqi/serpbear>

## Architecture in one minute

- **Node.js** (Next.js likely)
- SQLite
- Scraper via third-party API (ScrapingAnt / ScrapingRobot / SearchApi / SerpApi / HasData / proxies)
- **Resource**: low — ~200MB
- **Port**: HTTP

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | `towfiqi/serpbear`                                              | **Primary**                                                                        |
| **Fly.io / mogenius** | Free-tier                                                                                                              | Alt                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `serp.example.com`                                          | URL          | TLS                                                                                    |
| Admin user/pass      | First-boot                                                  | Bootstrap    | Strong                                                                                    |
| Scraper API key      | ScrapingAnt / etc.                                          | Secret       | **Costs money — track usage**                                                                                    |
| Google Ads test acct | For keyword research                                        | Integration  | Optional                                                                                    |
| GSC service-account  | For visit data                                              | Integration  | Optional                                                                                    |
| SMTP                 | Notifications                                               | Email        |                                                                                    |

## Install via Docker

```yaml
services:
  serpbear:
    image: towfiqi/serpbear:latest        # **pin**
    ports: ["3000:3000"]
    environment:
      - USER=admin
      - PASSWORD=change-me
      - SECRET=random-long-string
      - APIKEY=random-api-key
      - NEXT_PUBLIC_APP_URL=https://serp.example.com
    volumes:
      - ./serpbear-data:/app/data
    restart: unless-stopped
```

## First boot

1. Start; browse; login with env-set creds
2. Add first domain
3. Add keywords
4. Configure scraper-API-key
5. Test scrape (check ranking)
6. Configure GSC integration for real-visit data
7. Configure Google Ads test-account for research
8. Set up SMTP for notifications
9. Back up `/app/data`

## Data & config layout

- `/app/data/` — SQLite + configs

## Backup

```sh
sudo tar czf serpbear-$(date +%F).tgz serpbear-data/
# Contains scraper API keys + GSC creds + Ads creds — **ENCRYPT**
```

## Upgrade

1. CHANGELOG: <https://github.com/towfiqi/serpbear/blob/main/CHANGELOG.md>
2. Docker pull + restart

## Gotchas

- **167th HUB-OF-CREDENTIALS Tier 2 — SEO-TOOLING-CREDS**:
  - Holds: scraper-API keys (cost money!), Google Ads credentials, GSC service-account (read-domain-performance)
  - SMTP creds
  - **167th tool in hub-of-credentials family — Tier 2**
- **SCRAPER-API-COST-RISK**:
  - Third-party scrapers are per-request paid
  - Misconfig = bill-spike
  - **Recipe convention: "third-party-API-cost-control-discipline callout"**
  - **NEW recipe convention** (SerpBear 1st formally)
- **GOOGLE-SCRAPING-TOS**:
  - Google's own rate-limits + TOS
  - Use legitimate scraper-APIs, not direct
  - **Recipe convention: "Google-SERP-scraping-TOS-awareness callout"**
  - **NEW recipe convention** (SerpBear 1st formally)
- **GSC-SERVICE-ACCOUNT-SCOPE**:
  - Read-only on your own properties
  - Per-property delegation
  - **Recipe convention: "GSC-service-account-property-scope-discipline callout"**
  - **NEW recipe convention** (SerpBear 1st formally)
- **"STANDWITHPALESTINE" README-BANNER**:
  - Explicit political/social-cause banner in README
  - Maintainer's personal statement
  - **Recipe convention: "README-political-banner neutral-signal"**
  - **NEW neutral-signal convention** (SerpBear 1st formally)
- **BUILT-IN-API POSITIVE**:
  - SERP API for dashboards
  - **Recipe convention: "built-in-REST-API-for-reporting positive-signal"**
  - **NEW positive-signal convention** (SerpBear 1st formally)
- **PWA-MOBILE-APP**:
  - **PWA-installable: 4 tools** 🎯 **4-TOOL MILESTONE** (continuing Mini QR pattern)
- **CODACY-CODE-QUALITY**:
  - **Codacy-code-quality-badge: 2 tools** (Cloud Commander+SerpBear) 🎯 **2-TOOL MILESTONE**
- **ZERO-COST-DEPLOY-OPTION**:
  - Fly.io / mogenius.com free-tier
  - Low-barrier-to-try
  - **Recipe convention: "free-tier-PaaS-deploy-option positive-signal"**
  - **NEW positive-signal convention** (SerpBear 1st formally)
- **UNLIMITED-KEYWORDS-SELF-HOSTED**:
  - **Recipe convention: "self-host-removes-SaaS-limits"** — reinforces Usertour (121)
- **INSTITUTIONAL-STEWARDSHIP**: towfiqi + docs + CHANGELOG + Codacy + active + Docker-Hub + free-tier-deploy-option. **153rd tool — sole-dev-with-docs-site sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + CHANGELOG + Codacy + docs + Docker-Hub. **159th tool in transparent-maintenance family.**
- **RANK-TRACKING-CATEGORY:**
  - **SerpBear** — self-hosted; third-party-scraper-backed
  - **Ahrefs/Semrush/AccuRanker** — commercial SaaS
  - **SerpWatcher (Mangools)** — commercial
  - **Wincher** — commercial
- **ALTERNATIVES WORTH KNOWING:**
  - **Semrush/Ahrefs** — if you want full SEO-suite with data you don't collect yourself
  - **Choose SerpBear if:** you want OSS + self-hosted + unlimited-keywords.
- **PROJECT HEALTH**: active + Codacy + docs + CHANGELOG + Docker-Hub. Strong for sole-dev.

## Links

- Repo: <https://github.com/towfiqi/serpbear>
- Docs: <https://docs.serpbear.com>
