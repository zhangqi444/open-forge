---
name: CommaFeed
description: "Google Reader inspired self-hosted RSS aggregator. Quarkus + React/TypeScript; native compilation for fast startup. H2 / PostgreSQL / MySQL / MariaDB. Fever-compatible API. OPML. Apache-2.0. Free public instance at commafeed.com funded by donations."
---

# CommaFeed

CommaFeed is **"the Google Reader you still miss, self-hosted"** — an RSS/Atom feed aggregator modeled on the classic Google Reader UI + keyboard shortcuts. Fast (Quarkus native compile → sub-second startup), scalable (millions of feeds, thousands of users per the README), feature-rich (4 layouts, dark mode, RTL, keyboard shortcuts, OPML, 25+ language translations). Optionally you can just use the free public instance at commafeed.com instead of self-hosting.

Built + maintained by **Athou** (Jérémie Panzer + community). **Apache-2.0**. Active + mature + funded via donations (public instance is free, no ads, no tracking).

Use cases: (a) **personal RSS reader** — your daily news + blogs + tech feeds (b) **replacement for defunct Google Reader** — UX-faithful (c) **replacement for Feedly/Inoreader** — escape commercial freemium (d) **multi-user family RSS** — each family member own account (e) **team knowledge monitoring** — track competitor blogs + industry feeds (f) **self-hosted Fever API server** — for mobile native apps that speak Fever (Reeder, Unread, etc.).

Features:

- **4 different layouts** — cards, title-only, magazine, detailed
- **Light/dark theme**
- **Fully responsive** — mobile + desktop
- **Keyboard shortcuts** for almost everything (true to Google Reader spirit)
- **RTL feed support**
- **Translated into 25+ languages**
- **Scales to millions of feeds / thousands of users** (per upstream claim)
- **OPML import/export**
- **REST API**
- **Fever-compatible API** — native mobile apps work out of the box
- **Auto-mark-read rules** — user-defined
- **Push notifications** for new articles
- **Custom CSS + JavaScript** — power-user customization
- **Browser extension** — one-click subscribe from any page
- **Native compilation** (Quarkus + GraalVM) — blazing startup + low memory
- **4 DB backends** — H2 (embedded), Postgres, MySQL, MariaDB

- Upstream repo: <https://github.com/Athou/commafeed>
- Homepage: <https://www.commafeed.com>
- Docs: <https://athou.github.io/commafeed/>
- Browser extension: <https://github.com/Athou/commafeed-browser-extension>
- Custom CSS docs: <https://athou.github.io/commafeed/documentation/custom-css>
- Public-instance limitations: <https://github.com/Athou/commafeed/discussions/1567>
- PikaPods cloud hosting: <https://www.pikapods.com/pods?run=commafeed>
- Docker Hub: <https://hub.docker.com/r/athou/commafeed>
- Releases: <https://github.com/Athou/commafeed/releases>

## Architecture in one minute

- **Quarkus (Java)** backend — compiles to native via GraalVM for fast startup + low memory
- **React/TypeScript** frontend
- **DB**: H2 (embedded, single-user), PostgreSQL (multi-user production), MySQL / MariaDB
- **Resource**: native-compiled = ~50-100MB RAM; scales with feed count + users
- **Port 8082** default

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **`athou/commafeed:<db>-<native|jvm>`**                          | **Pick the DB-specific image**                                                     |
| Native binaries    | `linux-x86_64`, `linux-aarch_64`, `windows-x86_64` from releases          | No JRE needed                                                                                   |
| JVM package        | `jvm.zip` — `java -jar quarkus-run.jar`                                                  | Cross-platform; needs JRE                                                                                               |
| PikaPods cloud     | 1-click $1/mo (20% revenue-share to CommaFeed)                                                                    | Supporting upstream while easy                                                                                                 |
| Public instance    | commafeed.com                                                                                               | Free; some limitations                                                                                                                 |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `rss.example.com`                                           | URL          | TLS recommended                                                                                    |
| DB choice            | H2 / Postgres / MySQL / MariaDB                             | DB           | Postgres for production multi-user                                                                                    |
| Admin creds          | First-boot registration                                                                           | Bootstrap    | Strong password                                                                                    |
| DB creds             | Username + password + host                                                                                   | DB           | For non-H2                                                                                                            |
| `COMMAFEED_*` env    | Quarkus config                                                                                                        | Config       | See upstream docs                                                                                                                            |

## Install via Docker

```yaml
services:
  commafeed:
    image: athou/commafeed:5.x-postgresql-native   # **pin to specific release tag**
    restart: unless-stopped
    environment:
      - COMMAFEED_DATABASE_TYPE=postgresql
      - QUARKUS_DATASOURCE_JDBC_URL=jdbc:postgresql://db:5432/commafeed
      - QUARKUS_DATASOURCE_USERNAME=commafeed
      - QUARKUS_DATASOURCE_PASSWORD=${DB_PASSWORD}
    ports: ["8082:8082"]
    depends_on: [db]
  db:
    image: postgres:17
    environment:
      POSTGRES_DB: commafeed
      POSTGRES_USER: commafeed
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - ./commafeed-db:/var/lib/postgresql/data
```

## First boot

1. Start → browse `http://host:8082`
2. Default admin login: `admin` / `admin` — **change immediately** (default-creds risk)
3. Create user account(s)
4. Import OPML from previous reader or subscribe to first feed
5. Install browser extension for one-click subscribe
6. Configure notification + theme preferences
7. Put behind TLS reverse proxy
8. Back up DB + config

## Data & config layout

- DB — user accounts, subscriptions, feed metadata, read/unread state, starred items
- Feed content cache — in DB (or filesystem depending on config)
- Config — env vars / Quarkus properties

## Backup

```sh
docker compose exec db pg_dump -U commafeed commafeed > commafeed-$(date +%F).sql
# Export OPML from app for portable feed list: Settings → Import/Export → Export OPML
```

OPML export gives you PORTABLE feed list — migrate to any RSS reader trivially. Keep a recent OPML backup.

## Upgrade

1. Releases: <https://github.com/Athou/commafeed/releases>. Active + semver.
2. Docker: pull + restart.
3. DB migrations auto-run on startup.
4. Back up DB before major upgrades.

## Gotchas

- **DEFAULT CREDS `admin:admin` ON FIRST BOOT**: change IMMEDIATELY. **6th tool in default-creds-risk family** (joins Black Candy 83, PMS 86, Guacamole 87, pyLoad 88, VerneMQ 91). **Publicly-exposed CommaFeed with default creds = attacker-owned.**
- **CUSTOM CSS + JavaScript = XSS FOR THE AUTHOR THEMSELVES**: CommaFeed explicitly supports user-authored custom CSS + JavaScript in UI. **Per-user (not per-tenant)** — your custom JS runs in YOUR browser, not other users'. Lower-stakes than LimeSurvey (batch 90) or LinkStack (91) multi-tenant JS. Still: don't paste untrusted JS snippets.
- **FEED CONTENT = UNTRUSTED HTML from thousands of sources**: RSS feeds contain HTML from external sites. CommaFeed sanitizes before rendering. Verify sanitization is robust (check feed-rendering with DOMPurify-class lib). Classic web-reader attack: malicious feed embeds JS → hits reader browser. This is generally handled well but worth awareness.
- **EXTENSIVE FEED CONTENT CACHING = DISK + DB GROWTH**: CommaFeed stores article content for offline-read + search. Thousands of feeds × years of retention = multi-GB DB. Plan disk + DB backend (Postgres scales; H2 will struggle).
- **FEVER API = LEGACY BUT GOLD FOR MOBILE APPS**: Fever API was a PHP-era protocol for RSS sync; CommaFeed's Fever API means Reeder / Unread / many iOS/Android RSS apps just work. **API-compat-as-ecosystem-strategy** (3rd tool after Ampache batch 88 + yarr batch 87 Fever) — CommaFeed inherits Fever's mobile-app ecosystem.
- **CODE-POINT-NATIVE-COMPILATION**: Quarkus native binaries start in ms, use ~50MB RAM. Fit for resource-constrained deployments (Pi, small VPS). If debugging issues, the JVM variant gives you standard Java tooling.
- **AUTO-MARK-READ RULES = SOFT CONTENT FILTERING**: user-defined regex/keyword rules mark articles as auto-read. Powerful; check regex engines for ReDoS (regex-denial-of-service); CommaFeed is generally safe here but avoid user-supplied regexes in shared-instance contexts.
- **PUSH NOTIFICATIONS**: require web-push keys + push service. Configure VAPID keys; **these are also immutability-of-secrets** for continuity of push subscriptions.
- **PUBLIC PRESENCE**: CommaFeed is used publicly at commafeed.com (free tier, donation-funded). Supporting upstream via PikaPods hosting (20% revenue share) or donation is a good move if you rely on it.
- **HUB-OF-CREDENTIALS LIGHT**: stores user accounts + auth-tokens to feeds that require it (not common for RSS but some). **30th tool in hub-of-credentials family — LIGHT tier.**
- **FEED PROXY DEFAULTS**: CommaFeed fetches feeds from origin sites. If your instance is publicly-exposed + allows-feed-subscription = potential **SSRF risk** (someone subscribes to `http://internal-service:8080/admin`, CommaFeed fetches it + renders to their reader). Mitigations: (a) restrict internal-network access from CommaFeed's outbound (egress firewall / block RFC1918) (b) upstream feed-proxy validation. For single-user personal use, not a concern.
- **TRANSPARENT-MAINTENANCE**: clean Apache-2 + native-compile maturity + 25+ lang + documented public-instance limitations + explicit GitHub discussion for limits. **13th tool in transparent-maintenance family.**
- **COMMERCIAL-TIER**: public instance is free + donation-funded. PikaPods revenue-share provides some ongoing funding. **"primary-SaaS-with-OSS-of-record"** variant where SaaS is donation-funded (unique pattern, not strictly commercial) — **7th commercial-tier entry or variation of pure-donation**.
- **SOLE-MAINTAINER**: Athou (Jérémie Panzer) solo + contributors. Bus-factor-1 mitigated by Apache-2 + active-community. **5th tool in sole-maintainer-with-community class.**
- **OPML PORTABILITY = ESCAPE HATCH**: your feed list is portable OPML — move to Miniflux / FreshRSS / Tiny Tiny RSS / any other RSS reader in minutes. **Low lock-in = low-risk tool adoption.**
- **ALTERNATIVES WORTH KNOWING:**
  - **Miniflux** — Go + minimalist; MIT; widely-loved; miniflux.app
  - **FreshRSS** — PHP + feature-rich; AGPL-3; freshrss.org
  - **Tiny Tiny RSS** (ttrss) — PHP + OG classic; now less active
  - **yarr** (batch 87 already in our catalog) — Go single-binary minimal
  - **NewsBlur** — commercial SaaS + OSS
  - **Feedbin** (batch 89 catalog) — commercial SaaS-primary with OSS-of-record
  - **Feedly / Inoreader** — commercial SaaS freemium
  - **Reeder** (client) — iOS/macOS client; pairs with any Fever-API server (including CommaFeed)
  - **Choose CommaFeed if:** you want Google-Reader-UX-faithful + Quarkus-native-compilation + multi-lang + Fever-API + mature.
  - **Choose Miniflux if:** you want minimal + Go + single-binary + rock-solid.
  - **Choose FreshRSS if:** you want PHP-stack + feature-rich + shared-hosting-friendly.
  - **Choose yarr if:** you want ultra-minimal + single-user.
- **Project health**: active + mature + Apache-2 + public instance running + donation-funded + native-compilation excellence + 25+ translations. Strong signals.

## Links

- Repo: <https://github.com/Athou/commafeed>
- Public instance: <https://www.commafeed.com>
- Docs: <https://athou.github.io/commafeed/>
- Custom CSS docs: <https://athou.github.io/commafeed/documentation/custom-css>
- Browser extension: <https://github.com/Athou/commafeed-browser-extension>
- Docker: <https://hub.docker.com/r/athou/commafeed>
- PikaPods (cloud host, 20% rev-share): <https://www.pikapods.com/pods?run=commafeed>
- Miniflux (alt): <https://miniflux.app>
- FreshRSS (alt): <https://freshrss.org>
- yarr (alt minimal): <https://github.com/nkanaev/yarr>
- NewsBlur (commercial alt): <https://www.newsblur.com>
- Feedbin (alt, OSS-of-record): <https://github.com/feedbin/feedbin>
- Fever API (legacy but living): <https://feedafever.com/api>
