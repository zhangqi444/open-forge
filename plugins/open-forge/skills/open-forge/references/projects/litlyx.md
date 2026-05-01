---
name: Litlyx
description: "Modern, cookie-free, privacy-first analytics. 30-second install. Self-host Docker or cloud. Alternative to GA4, PostHog, Mixpanel. Litlyx/litlyx. docs.litlyx.com. Discord."
---

# Litlyx

Litlyx is **"Plausible / Umami — but even simpler + cookie-free + 30-second install"** — a modern analytics tool positioned as an easier + privacy-respecting alternative to Google Analytics 4, PostHog, Mixpanel. **No cookies**. Self-host via Docker, or use hosted cloud. One-script-tag integration.

Built + maintained by **Litlyx** org. Docker + Cloud dual. docs.litlyx.com. Discord. Commercial SaaS parallel at litlyx.com.

Use cases: (a) **GA4 alternative** for privacy-conscious sites (b) **cookie-free website analytics** (c) **30-second-install for quick setup** (d) **PostHog-lite for small teams** (e) **self-hosted or managed cloud** (f) **GDPR-friendly analytics** (g) **dashboard-driven traffic insights** (h) **simple-by-design analytics**.

Features (per README):

- **Cookie-free** analytics
- **30-second install**
- **Universal installation** (single script tag)
- **Self-host Docker** or **Cloud**
- **Alternative to GA4 / PostHog / Mixpanel**
- **Fast + modern**

- Upstream repo: <https://github.com/Litlyx/litlyx>
- Website: <https://litlyx.com>
- Cloud dashboard: <https://dashboard.litlyx.com>
- Docs: <https://docs.litlyx.com>
- Discord: <https://discord.gg/9cQykjsmWX>

## Architecture in one minute

- Web analytics collector + dashboard
- Node.js likely + MongoDB or Postgres
- JS snippet client-side (browser to collector endpoint)
- **Resource**: low-moderate (scales with traffic)
- **Port**: HTTP

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | Upstream                                                                                                               | **Primary**                                                                                   |
| **Cloud**          | litlyx.com                                                                                                             | SaaS alt                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `analytics.example.com`                                     | URL          | **TLS** — CORS                                                                                    |
| Workspace ID         | From Litlyx                                                 | Config       |                                                                                    |
| Target sites         | `example.com`, etc.                                         | Data         | Per-workspace                                                                                    |
| DB                   | Mongo/Postgres                                              | DB           |                                                                                    |

## Install via Docker

Per docs.litlyx.com. Typical compose with DB + collector + dashboard.

## First boot

1. Deploy
2. Sign up / bootstrap
3. Get `workspace_id`
4. Add script tag to your site(s):
   `<script defer data-workspace="ID" src="..."></script>`
5. Verify events in dashboard
6. Put behind TLS
7. Back up DB

## Data & config layout

- DB — events + page-views + per-workspace isolation

## Backup

```sh
# DB dump
# Contents: IP addresses (if stored), referrer PII — **ENCRYPT**
```

## Upgrade

1. Releases: <https://github.com/Litlyx/litlyx/releases>
2. Docker pull + restart
3. DB migrations check

## Gotchas

- **195th HUB-OF-CREDENTIALS Tier 2 — WEBSITE-VISITOR-TELEMETRY**:
  - Holds: per-site visitor telemetry, IP (if stored), referrer PII, workspace IDs
  - Cookie-free doesn't mean no-PII — IP is still PII under GDPR
  - **195th tool in hub-of-credentials family — Tier 2**
- **COOKIE-FREE-NOT-PII-FREE**:
  - Cookieless = fewer legal triggers, but IP remains PII
  - **Recipe convention: "cookie-free-marketing-does-not-equal-PII-free callout"**
  - **NEW recipe convention** (Litlyx 1st formally)
- **ANALYTICS-CATEGORY-DOMINANT-ALTERNATIVES**:
  - Plausible, Umami, PostHog, Matomo, Fathom, GoatCounter + Litlyx
  - Mature category
  - **Analytics-tool category MATURED: 7+ tools** 🎯 **category-maturity-milestone**
- **COMMERCIAL-PARALLEL-CLOUD**:
  - litlyx.com itself offers cloud
  - **Commercial-parallel-with-OSS-core: 21 tools** 🎯 **21-TOOL MILESTONE** (+Litlyx)
- **UNIVERSAL-JS-SNIPPET**:
  - One-tag integration
  - **Recipe convention: "single-script-tag-integration positive-signal"**
  - **NEW positive-signal convention** (Litlyx 1st formally)
- **30-SECOND-INSTALL-POSITIONING**:
  - Reinforces "sub-5-min-quickstart" pattern from SecureAI Tools (127)
  - **Recipe convention: "sub-5-min-quickstart-positioning"** — reinforces SecureAI
- **JSDELIVR-CDN-SNIPPET**:
  - Cloud CDN-hosted JS
  - For self-host, serve from your own domain to avoid 3rd-party supply-chain risk
  - **Recipe convention: "self-host-JS-snippet-not-third-party-CDN callout"**
  - **NEW recipe convention** (Litlyx 1st formally)
- **COOKIE-FREE-GDPR-POSITIONING**:
  - Privacy marketing
  - **Recipe convention: "cookie-free-GDPR-friendly-positioning positive-signal"**
  - **NEW positive-signal convention** (Litlyx 1st formally)
- **ALTERNATIVES-EXPLICIT-LIST**:
  - GA4 + PostHog + Mixpanel called out
  - **Alternative-to-commercial-tools-explicit-list: 3 tools** (Usertour+Bugsink+Litlyx) 🎯 **3-TOOL MILESTONE**
- **INSTITUTIONAL-STEWARDSHIP**: Litlyx org + website + cloud + docs + Discord + Docker. **181st tool — analytics-org-stewardship sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + docs + Discord + dual-deploy. **187th tool in transparent-maintenance family.**
- **ANALYTICS-CATEGORY:**
  - **Litlyx** — cookie-free; 30-sec install; modern
  - **Plausible** — dominant OSS; cookie-free
  - **Umami** — lightweight; cookie-free
  - **PostHog** — product-analytics; heavy
  - **Matomo** — mature; full-featured
  - **Fathom / GoatCounter** — minimalist
- **ALTERNATIVES WORTH KNOWING:**
  - **Plausible** — if you want dominant OSS + mature
  - **Umami** — if you want minimal + similar philosophy
  - **PostHog** — if you want product-analytics + feature-flags
  - **Choose Litlyx if:** you want fastest-setup + cookie-free + cloud-or-self-host.
- **PROJECT HEALTH**: active + cloud + docs + Discord + dual-deploy. Strong.

## Links

- Repo: <https://github.com/Litlyx/litlyx>
- Website: <https://litlyx.com>
- Plausible (alt): <https://github.com/plausible/analytics>
- Umami (alt): <https://github.com/umami-software/umami>
- PostHog (alt): <https://github.com/PostHog/posthog>
