---
name: Feedbin
description: "Simple, fast, nice-looking web RSS reader — Ruby on Rails. Commercial SaaS (feedbin.com) with open-source repo. Upstream EXPLICITLY does not recommend self-hosting and provides no self-host support. MIT. For self-hosters, upstream redirects to yarr / Tiny Tiny RSS / FreshRSS."
---

# Feedbin

Feedbin is **"a commercial-SaaS RSS reader whose source code happens to be open"** — a Ruby on Rails web RSS reader with polished UX, REST-like API for clients (Reeder, Fiery Feeds, Unread, NetNewsWire), and long-running commercial operation at feedbin.com. **Upstream's README is unusually explicit:** *"No support is provided for installing the open-source project"* + *"Feedbin's goal is to be a great web-based RSS service. This goal is at odds with being a great self-hosted RSS reader. There are a lot of moving parts and things to configure, and for that reason I do not recommend that you run Feedbin in production unless you have plenty of time to get it properly configured."* Upstream explicitly points self-hosters toward **yarr** (batch 87), **Tiny Tiny RSS**, and **FreshRSS** instead.

Built + maintained by **Feedbin** (Ben Ubois, commercial). **MIT-licensed** source; commercial SaaS is primary product. "Open source of record" + no operator support = rare but honest positioning.

Use cases: (a) **paid Feedbin SaaS** via feedbin.com — the upstream-recommended path (b) **advanced self-hosters with Rails experience** willing to handle the operational complexity (c) **Feedbin-as-backend** for third-party clients via Feedbin API (works against either cloud or self-hosted).

Features:

- **Simple, fast, polished** RSS reading UX
- **REST-like API** (<https://github.com/feedbin/feedbin-api>) — client ecosystem (Reeder, Fiery Feeds, Unread, NetNewsWire, etc.) supports it
- **Full-text extraction** via companion `extract` service (Node.js)
- **Image privacy proxy** via companion `privacy-please` service (HTTPS image proxy)
- **Face-detected preview image cropping** via `pigo` companion
- **Newsletter → RSS** conversion (send newsletters to a Feedbin email address)
- **Starred / read-later / favorites**
- **Search** across articles
- **Sharing to read-it-later services** (Instapaper, Readwise, etc.)
- **Podcast listening** (Feedbin SaaS also does podcast subscriptions)

- Upstream repo: <https://github.com/feedbin/feedbin>
- Homepage / SaaS: <https://feedbin.com>
- API docs: <https://github.com/feedbin/feedbin-api>
- Companion — Privacy Please (image proxy): <https://github.com/feedbin/privacy-please>
- Companion — extract (content extraction): <https://github.com/feedbin/extract>
- Companion — pigo (face detection): <https://github.com/esimov/pigo>
- Community self-host attempt (unofficial): <https://github.com/angristan/feedbin-docker>

## Architecture in one minute

- **Ruby 3.4+** (Rails) — main app
- **Postgres 11+** — primary DB
- **Redis 6+** — caching + background jobs
- **Elasticsearch 8.5+** — full-text search
- **Sidekiq / Foreman** — background workers
- **Optional companion services**: extract (Node.js), privacy-please (image proxy), pigo (binary)
- **Resource**: substantial — Postgres + Redis + Elasticsearch + Rails = 2-4GB RAM minimum + dedicated process management

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **feedbin.com (SaaS)** | **Upstream-recommended path**                                | **Paid commercial product — what the source's author wants you to use**                        |
| Bare-metal Rails   | Clone + bundle + rake db:setup + foreman start                            | **Explicitly not recommended by upstream**                                                 |
| Docker (community) | `angristan/feedbin-docker` — UNOFFICIAL                                   | **Unofficial + upstream-disclaimed**                                                       |

## Inputs to collect (self-host, if you insist)

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `feedbin.example.com`                                       | URL          | TLS mandatory                                                                                    |
| `.env` file          | Copy `.env.example` → customize                                     | Config       | Many env vars; review + customize                                                                                    |
| Postgres DB          | `feedbin` DB + user                                                                | DB           | Plan for scale                                                                                                      |
| Redis                | Single instance; persistence configured                                                         | Cache/jobs   | Critical for background jobs                                                                                                              |
| Elasticsearch        | ES 8.5+ (Elastic License — read carefully; may restrict commercial redistribution)                                | Search       | Required for search feature                                                                                                              |
| Companion services   | extract + privacy-please + pigo (all optional)                                                                            | Optional     | Extends functionality                                                                                                                   |

## Install (self-host — not recommended by upstream)

Per README, abbreviated:

```sh
# Install Ruby 3.4, Postgres 11, Redis 6, Elasticsearch 8.5 — OS-specific
git clone https://github.com/feedbin/feedbin.git
cd feedbin
bundle
cp .env.example .env
# edit .env
rake db:setup
bundle exec foreman start
```

**This is the skeleton only. Real production Feedbin requires Sidekiq tuning, ES index management, SMTP config, TLS termination, reverse proxy, log rotation, backup strategy, companion-service orchestration, etc. — none of which upstream supports.**

## First boot

- Only the author really knows the full list of env vars + "moving parts" needed. **That's upstream's point.** If you're determined, read the `.env.example` carefully + plan many hours of config.

## Data & config layout

- **Postgres** — users, subscriptions, articles, feeds, stars, reading state
- **Redis** — Sidekiq job queues + caches
- **Elasticsearch** — search index of article bodies
- **File storage** — image/favicon cache; S3-compatible configurable
- **`.env`** — app config (API keys for optional integrations, SMTP, S3, etc.)

## Backup

Standard Rails-Postgres-Redis-ES backup: pg_dump + Redis AOF/RDB + ES snapshot. **Operational complexity matches Synapse (batch 84) in 4-dependency-stack territory.**

## Upgrade

1. Upstream releases are infrequent — git commits are the tracking signal.
2. Rails migrations run via `rake db:migrate`.
3. Ruby + dependency upgrades often needed alongside.
4. **No self-host support channel** — your community is `angristan/feedbin-docker` users + whoever else tries.

## Gotchas

- **UPSTREAM EXPLICITLY DISCOURAGES SELF-HOSTING.** The README is remarkably clear. This is a rare + refreshingly honest stance:
  - *"No support is provided for installing the open-source project."*
  - *"Feedbin's goal is to be a great web-based RSS service. This goal is at odds with being a great self-hosted RSS reader."*
  - *"I do not recommend that you run Feedbin in production unless you have plenty of time to get it properly configured."*
  - **The author's three recommended alternatives** (yarr, Tiny Tiny RSS, FreshRSS) are listed in the README itself.
  - **Respect the signal.** This is **upstream honest-maintenance-status taken to its logical endpoint**: the project is open-source-of-record but NOT optimized for self-host + author explicitly doesn't want to provide that support.
- **Open-source-of-record vs self-host-friendly distinction**: Feedbin is a NEW category in our recipe taxonomy — **"open-source-of-record" tools**. The code is MIT-licensed + publicly hosted for transparency, code audit, community PRs, possible forks, but the primary product is commercial SaaS + self-host is an afterthought with no support. **Same pattern may apply to:** apps whose source is on GitHub primarily for transparency/compliance but where self-host is explicitly unsupported. **New category: "open-source-of-record"** — 1st tool.
- **4-dependency-stack operational burden** (Ruby + Postgres + Redis + Elasticsearch): 2-4GB RAM minimum; 4 services to update + back up + monitor + debug. Same weight-class as Synapse (batch 84). Compare to yarr's single-Go-binary (batch 87) — different end of the self-host spectrum.
- **Elasticsearch license gotcha**: ES moved to Elastic License (proprietary) in 2021 → OpenSearch fork (Apache-2.0). Feedbin specifies ES 8.5 → that's Elastic License. **Check your use case** against Elastic's licensing. For redistribution / commercial SaaS setup = legal-review required. For personal self-host = typically fine. Same class as Redis licensing note (batch 85).
- **API-compat-as-ecosystem-strategy**: Feedbin's API is supported by many premium RSS clients (Reeder, Fiery Feeds, Unread, NetNewsWire, ReadKit). **This API is the secondary ecosystem asset** — even if you don't run Feedbin yourself, a paid feedbin.com subscription gives you access to those best-in-class clients. Similar pattern to Subsonic API (Ampache batch 88), Fever API (yarr batch 87). Feedbin API = 3rd API-compat-as-ecosystem-strategy entry.
- **Newsletter-to-RSS is a killer feature** of Feedbin SaaS — send email newsletters to a Feedbin-provided address, they appear as RSS. Nobody else does this well. If you use a lot of newsletters, SaaS Feedbin wins vs self-hosted alternatives.
- **Podcast subscription** support in SaaS.
- **Commercial-tier taxonomy: "primary-SaaS with OSS-of-record"** — distinct tier:
  - **feature-gated Premium** (Rotki 87, Chartbrew 86): OSS core + paid advanced
  - **hosted-SaaS-of-OSS-product** (Piwigo 88, AzuraCast 87): OSS product; same code paid-hosted
  - **open-core**: OSS core + proprietary enterprise features
  - **primary-SaaS with OSS-of-record** (Feedbin): commercial SaaS IS the product; OSS is transparency-focused not self-host-focused
  - **dual-licensed** (Octelium 88, IronCalc 86): AGPL + permissive simultaneously
- **Hub-of-credentials tier**: Feedbin stores user passwords + Feedbin API tokens + OAuth tokens for integrated services (Instapaper, Readwise, etc.). 15th tool, LIGHT tier.
- **If you want a self-hosted RSS reader**: take upstream's advice. Use **yarr** (87) for minimal, **Miniflux** for balanced, **FreshRSS** for multi-user, **Tiny Tiny RSS** for legacy-power-user. Save yourself Feedbin's self-host pain.
- **If you want Feedbin's UX + features**: pay for feedbin.com. $5-10/month. Author gets paid; you get support + updates. Sustainable.
- **Project health**: commercial SaaS = funded indefinitely as long as subscribers exist. Ben Ubois long-running. Not bus-factor-1-for-SaaS because paying customers keep it viable. OSS-side is less clear (slow commits when not needed for SaaS).
- **Alternatives worth knowing** (per upstream's own recommendation):
  - **yarr** — minimal Go + SQLite single-user (batch 87)
  - **Miniflux** — Go + Postgres; multi-user-capable
  - **FreshRSS** — PHP + MySQL/Postgres; multi-user; mature
  - **Tiny Tiny RSS (tt-rss)** — PHP; long-running; power-user
  - **Commafeed** — Java; multi-user
  - **Feedbin SaaS itself** — paid; upstream-supported
  - **Choose Feedbin SaaS if:** you want polished commercial UX + newsletter-to-RSS + premium-iOS-clients + willing to pay subscription.
  - **Choose yarr/Miniflux/FreshRSS/tt-rss if:** you want self-hosted with real operator support.
  - **DO NOT choose self-hosted Feedbin UNLESS** you enjoy Rails ops + can read through a 4-service-stack without hand-holding.

## Links

- Repo: <https://github.com/feedbin/feedbin>
- SaaS / primary product: <https://feedbin.com>
- API: <https://github.com/feedbin/feedbin-api>
- Privacy Please: <https://github.com/feedbin/privacy-please>
- extract: <https://github.com/feedbin/extract>
- Community docker (unofficial): <https://github.com/angristan/feedbin-docker>
- yarr (upstream-recommended alt): <https://github.com/nkanaev/yarr>
- Tiny Tiny RSS (upstream-recommended alt): <https://tt-rss.org>
- FreshRSS (upstream-recommended alt): <https://freshrss.org>
- Miniflux (alt): <https://miniflux.app>
