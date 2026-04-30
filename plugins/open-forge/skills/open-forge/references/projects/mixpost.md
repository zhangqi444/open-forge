---
name: Mixpost
description: "Self-hosted social media management + scheduling platform. Multi-account, multi-platform, team collaboration, analytics, calendar. Laravel package. MIT (Community Edition). Commercial Pro/Enterprise tiers at mixpost.app. Alternative to Buffer/Hootsuite/Later."
---

# Mixpost

Mixpost is **"Buffer / Hootsuite / Later / Sprout Social — self-hosted and yours"** — a social media management + scheduling platform for managing multiple accounts across Twitter/X, Facebook, Instagram, LinkedIn, TikTok, YouTube, Pinterest, Mastodon, Bluesky, etc. Draft + schedule + queue posts; collaborate with teams; analyze performance; maintain a content calendar; reuse templates + hashtags + media library. The self-hosted Community Edition is MIT-licensed; Pro/Enterprise tiers add additional features + priority support at mixpost.app.

Built + maintained by **Inovector** (Bulgarian SaaS company) + community. **License: MIT** (Community / OSS core); commercial Pro + Enterprise tiers. Active + well-documented + marketplace + Discord.

Use cases: (a) **content marketing team** managing 5-20 social accounts across multiple platforms (b) **agency workflow** — manage clients' social accounts with separate workspaces (c) **small business** scheduling a week of posts in advance (d) **escape Buffer/Hootsuite costs** ($49-$249/mo per seat) (e) **data-ownership** — all drafts + analytics + calendar on your servers (f) **team collaboration** — assign, review, approve posts (g) **content calendar visualization** for marketing planning.

Features (from upstream README):

- **Unified account management** — many platforms in one
- **Advanced analytics** — per-platform
- **Post versions + conditions** — tailor per-network
- **Media library** — reuse images, GIFs, videos
- **Team collaboration + workspaces**
- **Queue + calendar**
- **Customizable post templates**
- **Dynamic variables + hashtag groups**
- **Pro/Enterprise** tiers with additional features

- Upstream repo: <https://github.com/inovector/mixpost>
- Homepage: <https://mixpost.app>
- Pricing: <https://mixpost.app/pricing>
- Documentation: see repo + homepage
- Discord: <https://mixpost.app/discord>
- Facebook community: <https://www.facebook.com/groups/getmixpost>
- Packagist: <https://packagist.org/packages/inovector/mixpost>

## Architecture in one minute

- **PHP 8+ / Laravel** package — installs into a Laravel app
- **MySQL / MariaDB / PostgreSQL** — DB
- **Redis** — queues + cache
- **Resource**: moderate — 400-800MB RAM per Laravel instance
- **Port 80/443** via webserver

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Laravel package** | **composer require inovector/mixpost-app** — install into new Laravel project | **Primary official path**                                                 |
| **Docker (community)** | Community Docker images exist                                         | Check homepage                                                                                   |
| Managed Cloud      | mixpost.app — Pro/Enterprise hosted                                                                                    | If you prefer managed                                                                                               |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `mixpost.example.com`                                       | URL          | TLS MANDATORY (OAuth redirects require it)                                                                                    |
| DB                   | MySQL / PostgreSQL                                          | DB           | Laravel-compatible                                                                                    |
| Redis                | URL                                                         | Queue        | Required for scheduling workers                                                                                    |
| `APP_KEY`            | Laravel                                                                                        | **CRITICAL** | **IMMUTABLE**                                                                                    |
| Social platform OAuth | Twitter/X, Meta (Facebook+Instagram), LinkedIn, TikTok, YouTube, Pinterest, etc. apps         | **CRITICAL** | **Each platform = separate developer app + API review**                                                                                                            |
| Admin creds          | First-boot                                                                                                            | Bootstrap    | Strong password                                                                                                                            |
| SMTP                 | Notifications                                                                                                                       | Email        | Configure early                                                                                                                                            |

## Install via Laravel (upstream-primary)

```sh
# In a new Laravel project
composer require inovector/mixpost-app
php artisan mixpost:install
php artisan migrate
php artisan queue:work  # dedicated worker for scheduling
```

See <https://docs.mixpost.app> for full installation docs including web server + queue + scheduler cron setup.

## First boot

1. Install Laravel + Mixpost package
2. Run migrations
3. Configure web server + queue worker + cron scheduler
4. Register each social platform's API developer app (Twitter, Meta, etc.)
5. Connect first social account via OAuth in Mixpost
6. Test post scheduling + immediate-publish
7. Configure team workspaces
8. Put behind TLS reverse proxy
9. Set up queue-worker monitoring (workers MUST stay alive)
10. Back up DB + media library

## Data & config layout

- DB — posts, schedules, accounts, users, workspaces, analytics
- Media library — uploaded images/videos for posts
- `.env` — secrets (APP_KEY, DB, social OAuth app credentials)
- Queue state (Redis)

## Backup

```sh
docker compose exec db pg_dump -U mixpost mixpost > mixpost-$(date +%F).sql
sudo tar czf mixpost-media-$(date +%F).tgz storage/app/
```

## Upgrade

1. Releases on Packagist: <https://packagist.org/packages/inovector/mixpost>. Active.
2. `composer update inovector/mixpost-app` + `php artisan migrate`.
3. Back up BEFORE major upgrades.

## Gotchas

- **SOCIAL PLATFORM API COMPLEXITY = EXTREME**:
  - **Every platform requires** a separate developer app + review process + OAuth setup + permission-granting flows
  - **Twitter/X** closed its free API in 2023 — now $100-$5000/mo for basic API access; **Twitter-posting via Mixpost requires paid Twitter API tier** (significant cost + was a shock for existing users)
  - **Meta (Facebook + Instagram)** review is rigorous + takes weeks
  - **LinkedIn** API is restrictive
  - **TikTok** API is newer + evolving
  - **YouTube** channel posting different from video upload
  - **Platform API changes** can break Mixpost features overnight (Mixpost or other tools must react + update)
  - **18th tool in network-service-legal-risk family (API-TOS-platform-enforcement)** joining Redlib 95 + Dispatcharr 96. **NEW: "commercial-social-platform-API-dependency" sub-family** — distinct from front-end-proxy (Redlib) + IPTV-conduit (Dispatcharr) + content-download (YDL-M 97). Mixpost PUSHES content TO platforms via their sanctioned APIs. Legal risk is lower (you authorize via OAuth); cost + dependency risk is higher. **9th sub-family of network-service-legal-risk.**
- **HUB-OF-CREDENTIALS = CROWN-JEWEL TIER 1** for marketers / brands:
  - **OAuth refresh tokens** for all connected social accounts
  - **Posts (future + past)** — potentially pre-announced campaigns
  - **Media library** — brand assets
  - **Analytics** — competitive intelligence
  - **Team credentials + workspaces**
  - **SMTP for notifications**
  - **51st tool in hub-of-credentials family — CROWN-JEWEL Tier 1 (9th tool)** (joining Octelium, Guacamole, Homarr, pgAdmin, WGDashboard, Lunar, Dagu, GrowChief — Mixpost's CROWN-JEWEL framing: one-breach → brand's social accounts can be hijacked + used for phishing/crypto-scams/reputation-damage)
  - **Attack scenario**: attackers target Mixpost → get OAuth tokens → post "CEO fired + crypto opportunity" from official accounts → 100k+ followers see it → market moves / reputational damage. Ask: is Mixpost's deployment hardened against this?
- **MIGRATION CONVENTION: CROWN-JEWEL Tier 1 NOW 9 TOOLS** (need to acknowledge growth):
  1. Octelium (VPN zero-trust)
  2. Guacamole (browser-to-RDP/SSH bastion)
  3. Homarr (unified dashboard)
  4. pgAdmin (DBA panel)
  5. WGDashboard (Wireguard admin)
  6. Lunar (commerce platform)
  7. Dagu (workflow orchestrator)
  8. GrowChief (B2B outreach)
  9. **Mixpost (social media publisher)** — **NEW; marketing/brand sub-category of CROWN-JEWEL**
- **`APP_KEY` IMMUTABILITY** (Laravel): **33rd tool in immutability-of-secrets family.**
- **COMMERCIAL-TIER OPEN-CORE**: Mixpost Community is MIT + self-host; Mixpost Pro/Enterprise is commercial with additional features. **Standard open-core pattern.** Inovector funds OSS development via Pro sales. **16th tool in commercial-tier taxonomy** — open-core variant.
- **QUEUE WORKERS MUST STAY ALIVE** for scheduled posts. Use Supervisor/systemd/Horizon. Common Laravel ops concern.
- **OAuth REDIRECT URLS**: each platform's OAuth app needs exact redirect URL registered. Changing domain later = reconfiguring every platform. **Plan domain carefully.**
- **POST-PUBLISH FAILURES** (rate limits, API changes, platform bans): Mixpost retries + alerts; monitor Queue Worker health + failed-job counts.
- **BRAND REPUTATION STAKES**: a bug, compromise, or mis-configured Mixpost = real business damage (wrong content posts, or spam bursts). Change management + approval workflows matter. Mixpost's team-collaboration features (assign-approve) address this.
- **REGIONAL CONTENT LAWS**: posting content in regions with strict content laws (Germany: NetzDG, EU: DSA, etc.) = legal responsibility. Mixpost user + workspace + platform.
- **INSTITUTIONAL-STEWARDSHIP — COMPANY TIER**: Inovector is a legal entity + commercial team. **27th tool in institutional-stewardship — company sub-tier.**
- **TRANSPARENT-MAINTENANCE**: MIT + Pro tier + Discord + Facebook community + Packagist metrics. **33rd tool in transparent-maintenance family.**
- **MIT LICENSE**: permissive; commercial-reuse-OK; company chose MIT rather than AGPL — indicates Pro-tier features are the value-capture mechanism (code is shareable).
- **COMPANY-COMMERCIAL-OPEN-CORE strategy works here** because self-hosted Community covers most small-team needs; agencies + enterprises pay for Pro features (advanced analytics, priority support, SLAs). Inovector is the 1st mirror of this "sell-enterprise-OSS-community-is-marketing" model in catalog? Actually several precedents (Lunar 92, LimeSurvey 90, OpnForm 95); Mixpost joins.
- **ALTERNATIVES WORTH KNOWING:**
  - **Postiz** — MIT; newer; multi-platform scheduler
  - **Publer** — commercial SaaS; feature-rich
  - **Buffer** — commercial SaaS; freemium; long-running
  - **Hootsuite** — commercial SaaS; enterprise-focused
  - **Later** — commercial SaaS; Instagram-first
  - **Sprout Social** — commercial SaaS; enterprise
  - **SocialBee** — commercial SaaS
  - **Hypefury** — commercial SaaS; Twitter-first
  - **Choose Mixpost if:** you want SELF-HOST + Laravel + MIT + proven + optional Pro-tier.
  - **Choose Postiz if:** you want newer + TypeScript/Node + AGPL.
  - **Choose Buffer/Hootsuite if:** you accept commercial + simpler UX + no-ops burden.
- **PROJECT HEALTH**: active + MIT + company-backed + Pro-tier funding + Discord + multi-year. Strong signals.

## Links

- Repo: <https://github.com/inovector/mixpost>
- Homepage: <https://mixpost.app>
- Pricing: <https://mixpost.app/pricing>
- Discord: <https://mixpost.app/discord>
- Packagist: <https://packagist.org/packages/inovector/mixpost>
- Postiz (alt): <https://github.com/gitroomhq/postiz-app>
- Buffer (commercial alt): <https://buffer.com>
- Hootsuite (commercial alt): <https://hootsuite.com>
- Twitter API pricing (ouch): <https://developer.twitter.com/en/portal/products>
