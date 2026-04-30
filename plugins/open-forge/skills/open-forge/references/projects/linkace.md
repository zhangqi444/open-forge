---
name: LinkAce
description: "Self-hosted bookmark manager + link archive with automated link monitoring + Internet Archive integration. PHP/Laravel; MySQL/PG; Docker-first. OAuth/OIDC SSO. GPL-3.0. Active single-maintainer project with paid-Cloud tier at linkace.org."
---

# LinkAce

LinkAce is **"Raindrop.io / Pocket / Pinboard, but self-hosted and respectful"** — a bookmark archive for your web discoveries. Save articles for later reading, bookmark tools, preserve important pages long-term, organize with lists + tags, share with friends or keep private. Automated link-monitoring tells you when your bookmarks rot (broken or moved); automated archiving via the Internet Archive snapshots pages for eventual loss. OAuth/OIDC SSO. Full REST API + Zapier integration.

Built + maintained by **Kevin Woblick (Kovah)** + community. **License: GPL-3.0**. Active; 8+ year project; professional-looking managed-Cloud SaaS at linkace.org (open-core / hosted-SaaS-of-OSS); Mastodon + X presence.

Use cases: (a) **personal link archive** — research, recipes, tools, articles (b) **replace Raindrop/Pocket** — escape commercial bookmark-SaaS (c) **team knowledge curation** — shared lists of resources (d) **research bibliography** — articles + papers with tags + notes (e) **preservation-minded archiving** — combine with Internet Archive for long-term durability (f) **bookmark export hub** — API enables integration anywhere (g) **Zapier-integrated workflows** — automatic bookmarking from n8n / Zapier / Make.

Features (from upstream README):

- **Lists + tags** organization
- **Multi-user** with internal sharing of links/lists/tags
- **OAuth + OIDC SSO** — enterprise-friendly auth
- **Automated link monitoring** — broken-link detection + notifications
- **Internet Archive integration** — auto-snapshot saved pages
- **Full REST API** — integrate anywhere
- **Zapier integration** — 2500+ connected apps
- **Advanced search** — filters + ordering
- **Bookmarklet** for quick browser-save
- **Auto title + description** generation
- **Browser extensions**
- **Demo available** at demo.linkace.org

- Upstream repo: <https://github.com/Kovah/LinkAce>
- Homepage / managed Cloud: <https://linkace.org>
- Demo: <https://demo.linkace.org>
- Docs: <https://www.linkace.org/docs/>
- Docker Hub: <https://hub.docker.com/r/linkace/linkace>
- Zapier app: <https://zapier.com/apps/linkace/integrations>
- Mastodon: <https://mastodon.social/@linkace>
- Releases: <https://github.com/Kovah/LinkAce/releases>

## Architecture in one minute

- **PHP 8+ / Laravel 10+** — backend
- **MySQL / MariaDB / PostgreSQL** — DB
- **Redis** (optional) — caching
- **Resource**: moderate — 300-700MB RAM + storage for archives + metadata
- **Port 80/443** via webserver

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker compose** | **`linkace/linkace:simple` (all-in-one) or split services**     | **Upstream-primary**                                                               |
| Bare-metal Laravel | Composer install                                                          | DIY path                                                                                   |
| Managed Cloud      | linkace.org hosted                                                                                  | If you don't want to self-host                                                                                               |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `links.example.com`                                         | URL          | TLS MANDATORY                                                                                    |
| DB                   | MySQL / MariaDB / PostgreSQL                                | DB           | Laravel supports all three                                                                                    |
| Admin creds          | First-boot setup                                                                           | Bootstrap    | Strong password                                                                                    |
| `APP_KEY`            | Laravel                                                                                     | **CRITICAL** | **IMMUTABLE**                                                                                                            |
| OAuth/OIDC config    | (optional) SSO provider                                                                                                       | SSO          | Enterprise-friendly                                                                                                                            |
| SMTP                 | For link-monitoring alerts + user notifications                                                                                                                                             | Email        | Configure to get broken-link alerts                                                                                                                            |

## Install via Docker (simple image)

```yaml
services:
  linkace:
    image: linkace/linkace:simple     # **pin specific version in prod**
    restart: unless-stopped
    environment:
      - APP_URL=https://links.example.com
      - APP_KEY=${LINKACE_APP_KEY}
      - DB_CONNECTION=mysql
      - DB_HOST=db
      - DB_DATABASE=linkace
      - DB_USERNAME=linkace
      - DB_PASSWORD=${DB_PASSWORD}
    volumes:
      - ./linkace-data:/app/storage
    ports: ["8080:80"]
    depends_on: [db]
  db:
    image: mariadb:11
    environment:
      MARIADB_DATABASE: linkace
      MARIADB_USER: linkace
      MARIADB_PASSWORD: ${DB_PASSWORD}
      MARIADB_ROOT_PASSWORD: ${DB_ROOT_PASSWORD}
    volumes:
      - ./linkace-db:/var/lib/mysql
```

## First boot

1. Browse URL → install wizard runs
2. Configure DB + admin user
3. Install browser bookmarklet / extension
4. Save your first link → verify title + description auto-fetched
5. Set up lists + tags structure
6. Configure Internet Archive integration (generates API calls)
7. Configure link-monitoring schedule
8. Put behind TLS reverse proxy
9. Back up DB + storage

## Data & config layout

- DB — users, links, lists, tags, monitoring history
- `storage/` — uploaded favicons + assets + cache
- `.env` — secrets (APP_KEY, DB creds, SMTP, OAuth)

## Backup

```sh
docker compose exec db mariadb-dump -ulinkace -p${DB_PASSWORD} linkace > linkace-$(date +%F).sql
sudo tar czf linkace-storage-$(date +%F).tgz linkace-data/
```

## Upgrade

1. Releases: <https://github.com/Kovah/LinkAce/releases>. Active + semver.
2. Docker: pull + restart → Laravel migrations auto-run.
3. Read release notes for breaking changes.
4. Back up BEFORE major upgrades.

## Gotchas

- **SSRF-VIA-URL-FETCH RISK** (same as CommaFeed 92, Pinry 94): LinkAce fetches saved URLs to auto-generate titles + descriptions + send to Internet Archive. Publicly-exposed multi-user LinkAce = SSRF pivot risk. **3rd tool in SSRF-via-user-URL family.**
  - **Mitigation**: egress firewall on LinkAce container (block RFC1918 + localhost)
  - Upstream URL validation
  - **Family-doc at batch 100**: SSRF-via-user-URL family documenting 3+ tools with common mitigations.
- **INTERNET ARCHIVE INTEGRATION = THIRD-PARTY DEPENDENCY**:
  - Internet Archive may rate-limit requests
  - IA occasionally goes down / becomes read-only (e.g., 2024 DDoS events)
  - IA policy changes affect long-term link-archiving viability
  - **Alternative**: self-host your own archive (ArchiveBox batch <future>) to fully own the chain
- **LINK-MONITORING = HIGH EMAIL VOLUME POTENTIAL**: a 10k-bookmark instance detecting broken links = many alerts. Tune:
  - Batch notifications (daily digest vs per-link)
  - Threshold (only notify if link broken >7d)
  - Disable for users who don't care
- **GDPR + IMPORTED BROWSER HISTORY**: if users import full browser history as bookmarks, that data set is particularly personal. Regulatory:
  - Right to erasure
  - Lawful basis for storage (legitimate-interest typically)
  - Export flow for portability
- **PUBLIC LISTS = PUBLIC CONTENT = COPYRIGHT / DMCA EXPOSURE**: reinforces Pinry 94 precedent. If users share public lists linking to copyrighted content, upstream site lawyers may come knocking. Takedown procedure + abuse contact for public instances.
- **HUB-OF-CREDENTIALS LIGHT**: LinkAce stores user accounts + OAuth tokens (for SSO) + Zapier webhook URLs + IA API tokens. **41st tool in hub-of-credentials family — LIGHT tier.** Moderate sensitivity (bookmarks can reveal research interests, medical conditions, political views).
- **`APP_KEY` IMMUTABILITY** (Laravel-standard): **28th tool in immutability-of-secrets family.**
- **COMMERCIAL-TIER**: **hosted-SaaS-of-OSS-product** at linkace.org — paid Cloud tier. Standard model (Piwigo 88, osTicket 89, Kaneo 93). **12th tool in this commercial-tier category or 9+th tier overall.**
- **SOLE-MAINTAINER with community + commercial backing**: Kovah (Kevin Woblick) + managed-Cloud funding source. **12th tool in sole-maintainer-with-community class**, but commercial-Cloud funding is sustainable-backing signal — stronger than pure-donation. New sub-tier emerging: **"sole-maintainer-with-commercial-Cloud-funding"** — more sustainable than pure-donation sole-maintainers.
- **BOOKMARK DATA = PERSONAL-INFORMATION-DENSE**: what someone bookmarks reveals:
  - Health conditions researched
  - Political leanings
  - Job search (if bookmarking listings)
  - Personal interests + hobbies
  - Shopping intent
  - Financial research
  - **Treat bookmark data as moderately-sensitive** — more than task lists (Kaneo 93), less than health data (SparkyFitness 94).
- **ZAPIER INTEGRATION = ADDITIONAL ATTACK SURFACE**: Zapier-stored LinkAce API keys + Zapier's access-to-2500-apps = transitive-hub-of-credentials (OliveTin 91 precedent). Scope API keys narrowly; audit Zapier logs.
- **BOOKMARKLET SECURITY**: LinkAce bookmarklet runs JavaScript in the page being saved. Bookmarklet itself is yours; the page may attempt to interfere. Standard bookmarklet caveats.
- **BROWSER EXTENSION PERMISSIONS**: similar to Pinry 94 — extension reads current page URL. Standard permissions.
- **TRANSPARENT-MAINTENANCE**: semver + Mastodon + demo + active + Cloud-tier funding. **21st tool in transparent-maintenance family.**
- **INSTITUTIONAL-STEWARDSHIP**: Kovah (individual) + Cloud-tier as funding mechanism. **Sole-maintainer-with-commercial-Cloud-funding** sub-tier — 1st explicit case; emerging pattern. Could also be framed as "company-tier by one person" (Kovah has operationalized the Cloud business).
- **ALTERNATIVES WORTH KNOWING:**
  - **Linkwarden** — modern Next.js; self-hosted; AGPL; includes archive-to-self feature
  - **Hoarder / Karakeep** — modern; AI-tagging; MIT
  - **Shiori** — Go; minimal; GPL-3
  - **Wallabag** — PHP; mature; read-it-later focus; GPL-3
  - **Shaarli** (batch 87) — minimal PHP bookmark tool
  - **Pinry** (batch 94) — image-focused pinboard
  - **Raindrop.io** — commercial SaaS freemium
  - **Pocket** — commercial (Mozilla); free/paid; shutdown-pending risk
  - **Pinboard** — commercial; minimalist; still-running
  - **Instapaper** — commercial SaaS
  - **Choose LinkAce if:** you want PHP/Laravel + multi-user + IA-integration + broken-link-monitoring + OIDC.
  - **Choose Linkwarden if:** you want modern Next.js + self-archive + more content-types.
  - **Choose Hoarder/Karakeep if:** you want AI-tagging + MIT.
  - **Choose Shiori if:** minimal + single-user + Go.
  - **Choose Wallabag if:** read-it-later primary use case.
- **PROJECT HEALTH**: active + GPL-3 + Mastodon + Discord + Cloud-tier funding + Kevin well-known in PHP/Laravel community. Strong signals.

## Links

- Repo: <https://github.com/Kovah/LinkAce>
- Homepage: <https://linkace.org>
- Demo: <https://demo.linkace.org>
- Docs: <https://www.linkace.org/docs/>
- Docker: <https://hub.docker.com/r/linkace/linkace>
- Zapier: <https://zapier.com/apps/linkace/integrations>
- Linkwarden (alt): <https://linkwarden.app>
- Hoarder/Karakeep (alt): <https://github.com/karakeep-app/karakeep>
- Shiori (alt): <https://github.com/go-shiori/shiori>
- Wallabag (alt): <https://wallabag.org>
- Shaarli (alt): <https://github.com/shaarli/Shaarli>
- Raindrop.io (commercial): <https://raindrop.io>
- Pocket (commercial): <https://getpocket.com>
- ArchiveBox (full archiving): <https://archivebox.io>
