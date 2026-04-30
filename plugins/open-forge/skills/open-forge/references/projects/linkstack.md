---
name: LinkStack
description: "Self-hosted Linktree alternative — personalized profile page + link aggregator. Highly customizable; intuitive UI. PHP + MySQL/SQLite. GPL-3.0. LinkStackOrg community-maintained. Fork of LittleLink Custom; easy Docker + bare-metal install."
---

# LinkStack

LinkStack is **"your self-hosted Linktree / Beacons / Bio.Link"** — a profile-page + link-aggregator platform. One URL (`yourname.example.com`) displays a curated collection of your external links (social profiles, portfolio, contact, Stripe payment, newsletter signup, Spotify, etc.) with your custom branding + themes. Popular for: content creators, musicians, small businesses, educators, event organizers. Escape commercial Linktree's ads + data-harvesting + CSP limitations; self-host your bio page.

Built + maintained by **LinkStackOrg** (Julian Prieber + community; fork of Julian's earlier "LittleLink Custom" project). **License: AGPL-3.0 in recent versions / GPL-3.0 in older** — check current LICENSE file. Active Discord + Mastodon + Patreon/Liberapay funding.

Use cases: (a) **creator bio page** — musician / streamer / podcaster / influencer links (b) **business "all our links" page** — social + shop + contact in one URL (c) **event page** — tickets, RSVP, map, schedule (d) **portfolio landing** — "my CV, GitHub, LinkedIn, blog" (e) **church / nonprofit** — donations + services + contact (f) **family / personal** — "here's where to find me online" (g) **replacement for Linktree / Beacons / Lnk.bio / Bio.Link**.

Features (from upstream README + ecosystem):

- **Customizable profile page** — themes, fonts, colors, custom CSS
- **Link types** — external URLs, email, phone, Spotify, YouTube, payment, file download
- **Theme engine** — 20+ built-in themes + custom theme creation
- **Icon library** — huge icon set for platform-specific buttons
- **Multi-user** — one instance serves many profiles (for a "LinkStack-as-a-Service" model)
- **Admin panel** — user management + role-based permissions
- **Analytics** — click tracking per link
- **QR code generator** for your profile URL
- **Short URLs** — built-in link shortener
- **Password-protected profiles** + unlisted mode
- **Verified badge** feature
- **Integrates with**: Google Analytics, Plausible, Matomo, Simple Analytics (self-hosted analytics)
- **Docker + bare-metal + shared-hosting** install paths
- **API** for programmatic integrations
- **Import from LittleLink / Linktree** (migration helpers)
- **Accessible** (WCAG considerations)

- Upstream repo: <https://github.com/LinkStackOrg/LinkStack>
- Homepage: <https://linkstack.org>
- Docs: <https://docs.linkstack.org>
- Demo: check homepage for current demo
- Discord: <https://discord.linkstack.org>
- Mastodon: <https://mstdn.social/@linkstack>
- Sponsor (GitHub): <https://github.com/sponsors/julianprieber>
- Sponsor (Patreon): <https://patreon.com/julianprieber>
- Sponsor (Liberapay): <https://liberapay.com/LinkStack>

## Architecture in one minute

- **PHP 8.x + Laravel** — backend
- **MySQL / MariaDB / SQLite / PostgreSQL** — DB (SQLite for tiny installs)
- **Composer + npm** — dependency management
- **Apache / nginx + PHP-FPM** — web server
- **Resource**: light — 256-512MB RAM; scales with traffic to profile pages
- **Port 80/443** via web server

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **ZIP download**   | **`linkstack.zip` latest release → unzip → browse for installer** | **Upstream-recommended easy path**                                                 |
| Docker             | `linkstackorg/linkstack` official image                                   | Hub: <https://hub.docker.com/r/linkstackorg/linkstack>                                                                                  |
| Docker compose     | Upstream-provided compose                                                                | For container orchestration                                                                                      |
| Shared hosting     | Works on any PHP/MySQL shared host                                                                                   | Historic strength for LittleLink lineage                                                                                                 |
| Bare-metal Laravel | Clone repo + Composer install                                                                                                | For PHP devs                                                                                                                         |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `links.example.com`                                         | URL          | TLS MANDATORY                                                                                    |
| DB                   | MySQL / MariaDB / SQLite / Postgres                         | DB           | SQLite for single-user; MySQL+ for multi-user scale                                                                                    |
| Admin email + password | At installer                                                        | Bootstrap    | **Strong password**                                                                                    |
| `APP_KEY`            | Laravel app key                                                                                  | **CRITICAL** | **IMMUTABLE** — Laravel-standard                                                                                                              |
| SMTP                 | For user password-reset + notifications                                                                                       | Outbound     | Useful for multi-user                                                                                                                        |
| Base URL             | Must match public domain                                                                                                 | Config       | Affects share links + assets                                                                                                                                           |

## Install (ZIP, shared hosting / VPS path)

```sh
cd /var/www/
wget https://github.com/linkstackorg/linkstack/releases/latest/download/linkstack.zip
unzip linkstack.zip
chown -R www-data:www-data linkstack/
# Configure web server document root → linkstack/
# Browse to domain → installer wizard
```

## Install via Docker

```yaml
services:
  linkstack:
    image: linkstackorg/linkstack:latest   # **pin version** in prod
    restart: unless-stopped
    environment:
      - TZ=UTC
      - DB_CONNECTION=mysql
      - DB_HOST=db
      - DB_DATABASE=linkstack
      - DB_USERNAME=linkstack
      - DB_PASSWORD=${DB_PASSWORD}
      - APP_KEY=${LINKSTACK_APP_KEY}
      - APP_URL=https://links.example.com
    volumes:
      - ./linkstack-data:/var/www/html/LinkStack/linkstack
    ports: ["8080:80"]
    depends_on: [db]
  db:
    image: mariadb:11
    environment:
      MARIADB_DATABASE: linkstack
      MARIADB_USER: linkstack
      MARIADB_PASSWORD: ${DB_PASSWORD}
      MARIADB_ROOT_PASSWORD: ${DB_ROOT_PASSWORD}
    volumes:
      - ./linkstack-db:/var/lib/mysql
```

## First boot

1. Browse to domain → installer wizard
2. Configure DB → create admin user
3. Log in to admin panel
4. Create your first profile (slug = URL subpath)
5. Add links with custom icons + theme
6. Upload profile photo + set bio
7. Test public URL → verify rendering
8. Configure privacy settings (public / unlisted / password-protected)
9. Put behind TLS reverse proxy
10. Back up DB + `/linkstack-data`

## Data & config layout

- DB — users, profiles, links, themes, click analytics
- `/var/www/html/LinkStack/linkstack` (or equivalent) — config, uploaded images, cache
- `.env` — secrets (APP_KEY, DB creds, SMTP)
- `storage/` — uploaded user images + exported data

## Backup

```sh
docker compose exec db mariadb-dump -ulinkstack -p${DB_PASSWORD} linkstack > linkstack-$(date +%F).sql
sudo tar czf linkstack-files-$(date +%F).tgz linkstack-data/
# .env + APP_KEY: secure separate backup
```

## Upgrade

1. Releases: <https://github.com/LinkStackOrg/LinkStack/releases>. Active cadence.
2. Admin-UI auto-updater works for many upgrades (check docs).
3. Docker: pull + restart.
4. **Back up BEFORE major upgrades** — Laravel migrations run on boot.
5. Plugin / theme compat may break across major versions.

## Gotchas

- **LINK-AGGREGATOR PROFILE PAGE = HIGH-PROFILE TARGET IF USED BY PROMINENT PEOPLE**: if a celebrity / high-follower account uses your LinkStack instance, their bio page is a **phishing / impersonation target**. Attackers want to compromise the instance + swap their links to malicious destinations.
  - **Implications**: strong admin auth + admin MFA + audit-log for link changes + alerts on high-profile-profile edits
  - **25th tool in hub-of-credentials family** — in the "aggregated-public-presence" subtype (LinkStack + other link-aggregators + profile-services)
- **MULTI-USER INSTANCE = MULTI-TENANT COMPROMISE RADIUS**: if you host LinkStack for many people, one admin account compromise affects ALL profiles. **RBAC + per-user permissions** — not all users should be able to edit each other's profiles.
- **`APP_KEY` IMMUTABILITY** (Laravel-standard): **21st tool in immutability-of-secrets family**. Changing breaks existing encrypted sessions + encrypted DB fields.
- **CLICK TRACKING = ANALYTICS PRIVACY surface**: every click is logged with IP + user-agent. **GDPR-relevant** if EU visitors click your links. Configure:
  - Anonymize IPs in LinkStack OR upstream self-hosted analytics (Plausible / Matomo with IP anonymization)
  - Publish privacy notice on your profile page
  - Don't click-track externally for ad-attribution (more GDPR exposure)
- **LINK-SHORTENER FEATURE = ABUSE VECTOR**: built-in link shortener can be abused to redirect to phishing/malware. **If exposing shortener creation** — rate-limit, require auth, reputation-check destinations, or disable feature for public instances.
- **UPLOAD SECURITY**: users upload profile photos + potentially file-share links. **Image-magic / file-extension validation** to prevent PHP / SVG-with-JavaScript upload attacks. Laravel's built-in validators help; confirm LinkStack uses them on all upload paths.
- **XSS in CUSTOM CSS / JS**: LinkStack allows custom CSS + sometimes JS for profile customization. **Beware of untrusted multi-user setups** — one user's malicious JS runs in other visitors' browsers on their profile page. Same class as LimeSurvey (batch 90) custom-JS warning. **Limit custom-JS to trusted admins.**
- **FORK-LINEAGE NOTE**: LinkStack originated as **LittleLink Custom**. Older repo URLs may still work; older docs may reference LittleLink. Current canonical: `LinkStackOrg/LinkStack`.
- **COMMERCIAL-TIER**: no LinkStack-hosted SaaS (at time of writing); funded via GitHub Sponsors + Patreon + Liberapay. **"services-around-OSS" / pure-donation model.** Same as SWAG/LSIO (batch 90 — Open Collective donations) + some other community tools.
- **PROJECT HEALTH**: single-figurehead (Julian Prieber) with community contributors + multi-channel funding (Sponsors + Patreon + Liberapay) + active Discord + Mastodon presence. Bus-factor-adjacent-to-1 but donations-funded + forkable. Moderate risk; worth sponsoring if you rely on it.
- **THEMES = UI-layer risk**: themes can inject arbitrary CSS + sometimes JS. Install only from official + trusted sources. Same plugin-as-RCE caveat (but lower-stakes since themes are typically CSS-only).
- **MIGRATION from Linktree**: Linktree doesn't have a structured export API — migration is usually manual (copy links). Plan to re-create links by hand when migrating.
- **MIGRATION from LittleLink**: LinkStack has import paths from its predecessor; check docs.
- **DOMAIN + BRAND**: multi-user LinkStack serves each user at `yourdomain.example/username` OR optionally custom subdomain per user (harder config). For personal use, just serve your domain root = your profile.
- **SEO + OPEN GRAPH**: social-media sharing of profile URLs relies on Open Graph meta tags. LinkStack generates these; verify by testing with Twitter Card / Facebook Debugger / WhatsApp preview.
- **LOW-BANDWIDTH**: LinkStack profile pages are small assets → CDN in front (Cloudflare free tier) gives you global low-latency + basic DDoS protection essentially free.
- **Alternatives worth knowing:**
  - **LittleLink** (ancestor; simpler static-site generator)
  - **BioDrop** — Next.js; MIT; multi-user
  - **Solo** — minimal Next.js link-in-bio
  - **Linkstack alternatives / Bento** — commercial SaaS
  - **Beacons.ai / Linktree** — commercial SaaS incumbents
  - **Carrd** — commercial simple one-page sites
  - **Choose LinkStack if:** you want mature + PHP/Laravel + self-host + multi-user-capable + theme-rich.
  - **Choose BioDrop if:** you want Node/Next.js + MIT + modern dev-friendly.
  - **Choose static LittleLink if:** you want tiny footprint + no DB + just your own links.
  - **Choose Linktree if:** you don't want to self-host + accept free-tier branding.

## Links

- Repo: <https://github.com/LinkStackOrg/LinkStack>
- Homepage: <https://linkstack.org>
- Docs: <https://docs.linkstack.org>
- Docker: <https://hub.docker.com/r/linkstackorg/linkstack>
- Discord: <https://discord.linkstack.org>
- Mastodon: <https://mstdn.social/@linkstack>
- Sponsor: <https://github.com/sponsors/julianprieber>
- BioDrop (alt): <https://github.com/EddieHubCommunity/BioDrop>
- LittleLink (ancestor): <https://github.com/sethcottle/littlelink>
- Linktree (commercial alt): <https://linktr.ee>
- Beacons.ai (commercial alt): <https://beacons.ai>
