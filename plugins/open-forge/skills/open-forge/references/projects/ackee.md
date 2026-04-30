---
name: Ackee
description: "Self-hosted privacy-friendly web analytics — Node.js + MongoDB. No cookies, no cross-site tracking, GDPR-friendly. Minimal interface for site traffic stats. Events + GraphQL API. MIT."
---

# Ackee

Ackee is **"Google Analytics, but respectful"** — a self-hosted web analytics tool for people who want useful site insights without tracking individuals. **No cookies, no cross-site identifiers, no cookie banner required** (in most jurisdictions, thanks to anonymized architecture). Node.js + MongoDB. Minimal, focused UI. **GraphQL API** for custom tools. Tracked data is anonymized at ingest — users are not identifiable.

Developed by **Tobias Reich (electerious)** since ~2018; featured in Awesome-Selfhosted; mature + stable; donation-funded.

Features (per upstream):

- **Self-hosted** — 100% open-source
- **Lightweight** — Node.js + MongoDB
- **Minimal UI** — site visits, pages, referrers, browsers, devices, countries, … (all anonymized)
- **No cookies** — no unique user ID → no EU-cookie-banner obligation (per Ackee's design + typical interpretation of ePrivacy/GDPR; consult your own counsel)
- **Events** — track button clicks, newsletter signups, etc.
- **GraphQL API** — build custom tools on top
- **Integrations**: React (`use-ackee`), Vue/Nuxt, Svelte, Angular, WordPress (Soapberry), Gatsby, Gridsome, VuePress, PHP, Dart/Flutter, Django middleware — massive ecosystem of community wrappers
- **Lighthouse reporter + BitBar menu bar** — ecosystem tooling
- **CLI report generator** (`ackee-report`)

- Upstream repo: <https://github.com/electerious/Ackee>
- Homepage: <https://ackee.electerious.com>
- Live demo: <https://demo.ackee.electerious.com>
- GraphQL playground (demo): <https://demo.ackee.electerious.com/api>
- Docs: <https://github.com/electerious/Ackee/tree/master/docs>
- Get started: <https://github.com/electerious/Ackee/blob/master/docs/Get%20started.md>
- FAQ: <https://github.com/electerious/Ackee/blob/master/docs/FAQ.md>
- Options: <https://github.com/electerious/Ackee/blob/master/docs/Options.md>
- Tracker client: <https://github.com/electerious/ackee-tracker>
- Sponsor: <https://github.com/sponsors/electerious>
- PayPal: <https://paypal.me/electerious>

## Architecture in one minute

- **Node.js** server
- **MongoDB** — stores aggregated + anonymized analytics
- **Tracker** — small JS snippet (`ackee-tracker`) embedded on your sites
- **GraphQL API** — everything the UI does, available for external tools
- **Resource**: small — 100-200 MB RAM; MongoDB typical footprint
- **Stateless app** — all state in MongoDB

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Single VM          | **Docker Compose** (Ackee + MongoDB)                               | **Upstream-primary**                                                               |
| Docker standalone  | With external MongoDB                                                      | Documented                                                                                 |
| Kubernetes         | **Helm chart**                                                                        | Official                                                                                               |
| Bare-metal         | Node + MongoDB + PM2/systemd                                                                      | Documented                                                                                             |
| Netlify / Vercel / Heroku / Qovery / Render / Railway / Koyeb / Zeabur | PaaS templates documented                                    | Massive PaaS support                                                                             |

## Inputs to collect

| Input                | Example                                                  | Phase        | Notes                                                                        |
| -------------------- | -------------------------------------------------------- | ------------ | ---------------------------------------------------------------------------- |
| Domain               | `analytics.example.com`                                      | URL          | TLS mandatory (SSL-HTTPS doc covers)                                                 |
| Admin username       | set via env `ACKEE_USERNAME`                                       | Bootstrap    | Used for login                                                                               |
| Admin password       | set via env `ACKEE_PASSWORD`                                             | Bootstrap    | Strong password                                                                                        |
| MongoDB              | `MONGODB_URL`                                                           | DB           | Bundled or external                                                                                              |
| CORS                 | `ACKEE_ALLOW_ORIGIN` — comma-sep list of tracked sites                          | CORS         | Sites you track must be listed                                                                                             |

## Install via Docker Compose

Grab upstream compose. Shape:

```yaml
services:
  mongo:
    image: mongo:5
    volumes:
      - mongo_data:/data/db
    restart: unless-stopped

  ackee:
    image: electerious/ackee:latest             # pin specific version in prod
    environment:
      WAIT_HOSTS: mongo:27017
      ACKEE_MONGODB: mongodb://mongo:27017/ackee
      ACKEE_USERNAME: admin
      ACKEE_PASSWORD: CHANGE_STRONG_PASSWORD
      ACKEE_ALLOW_ORIGIN: "https://mysite.com,https://blog.mysite.com"
    ports:
      - "3000:3000"
    depends_on: [mongo]
    restart: unless-stopped

volumes:
  mongo_data:
```

## First boot

1. Browse → login with `ACKEE_USERNAME/PASSWORD`
2. Create first domain → get tracker snippet
3. Embed tracker on your sites (vanilla JS, or use framework wrapper)
4. Check: load your site → visit returns in Ackee UI within seconds
5. Configure events (if tracking specific interactions)
6. Put Ackee behind TLS + restrict admin UI if needed (forward-auth)
7. Back up MongoDB regularly

## Data & config layout

- MongoDB — all stats + events + domain config + user
- No file storage beyond Mongo
- Tracker snippet — served from YOUR Ackee server; embed in your site's HTML

## Backup

```sh
# Inside mongo container or host with mongo tools:
mongodump --uri mongodb://mongo:27017/ackee --out /backup/ackee-$(date +%F)/
# Or volume tar:
sudo tar czf ackee-$(date +%F).tgz /var/lib/docker/volumes/ackee_mongo_data
```

Mongo consistency: stop Ackee briefly for a point-in-time snapshot, or use `mongodump` (background-safe).

## Upgrade

1. Releases: <https://github.com/electerious/Ackee/releases>. Cadence reduced vs early years but continuing.
2. Docker: bump tag. Mongo major upgrade = separate exercise (follow Mongo upgrade guide).
3. Back up Mongo before Ackee upgrade.

## Gotchas

- **"No cookie banner required" is a common claim but jurisdiction-dependent.** Ackee's design anonymizes per-session + doesn't use unique identifiers → **generally** doesn't require cookie consent under GDPR/ePrivacy. But consult legal counsel for YOUR deployment — some jurisdictions / privacy bodies have varying interpretations. The technical design makes the ARGUMENT easier; it doesn't grant blanket immunity.
- **MongoDB operational burden.** MongoDB is the one non-trivial dep. For simple single-instance Ackee, bundled Mongo is fine. Large-scale analytics = learn Mongo operations (indexes, explain, replica sets if HA).
- **CORS `ACKEE_ALLOW_ORIGIN` must list every origin tracking Ackee.** Subdomains, protocol (https vs http), port variations = explicit list entries. Missing entries = tracker silently fails. Debug by checking browser console for CORS errors.
- **Tracker must load on HTTPS sites.** Modern browsers block mixed-content — if your tracked site is HTTPS, Ackee must serve the tracker + API over HTTPS too.
- **Not all analytics needs fit Ackee's minimalism.** If you need funnel analysis, cohort retention, A/B attribution, Ackee's minimal UI won't deliver. For marketing-analytics scope go to Matomo. For funnel/feature-flag stuff, PostHog. Ackee's sweet spot is **"I want to know roughly what pages people visit, without tracking them."**
- **Ad blockers block Ackee too** (many detect tracker-like patterns). Ackee has some proxy-the-tracker guidance; expect some data loss from ad-blocker users (~10-30% depending on audience). This is a feature of the ecosystem, not a bug of Ackee.
- **Self-host vs cloud decision**: Ackee has no managed cloud from upstream. Self-host or use a PaaS template. Donation-funded project; no commercial managed tier.
- **MIT license** — permissive. Embed in commercial projects freely.
- **Project health**: Tobias Reich solo-led long-running; donation-funded; active responsive. Bus-factor-1 risk honesty note (matches TaxHacker/Librum/Pinchflat solo-dev pattern from batches 73-76). Mature codebase + Node-standard stack = easy to self-support if upstream stalls.
- **Ecosystem strength mitigates bus-factor** — MANY community integrations (React/Vue/Angular/Nuxt/Gatsby/VuePress/Django/WordPress/...). Core stability + community momentum.
- **GraphQL API is Ackee's differentiator**: if you want to build a custom dashboard or export reports, the GraphQL API is first-class. Other privacy-analytics tools often lack this.
- **Alternatives worth knowing:**
  - **Plausible Analytics** — the darling of privacy analytics; Elixir; simpler ops; commercial + OSS (AGPL)
  - **Umami** — Node+Postgres/MySQL; similar scope; growing fast
  - **Matomo** — PHP; feature-heavy; more traditional analytics
  - **GoatCounter** — Go+SQLite; extremely minimal; free cloud tier
  - **Fathom Analytics** — commercial SaaS; great UX
  - **Simple Analytics** — commercial SaaS
  - **PostHog** — product analytics (different scope); self-hostable; heavier
  - **Choose Ackee if:** Node stack + GraphQL API + minimalism + early-adopter-confident.
  - **Choose Plausible if:** more polish + active community + simpler ops.
  - **Choose Umami if:** MySQL/Postgres preferred over Mongo + modern UI.
  - **Choose GoatCounter if:** extreme minimalism + SQLite + zero overhead.
  - **Choose Matomo if:** more feature parity with GA; fine with PHP.

## Links

- Repo: <https://github.com/electerious/Ackee>
- Homepage: <https://ackee.electerious.com>
- Live demo: <https://demo.ackee.electerious.com>
- GraphQL playground demo: <https://demo.ackee.electerious.com/api>
- Docs: <https://github.com/electerious/Ackee/tree/master/docs>
- Get started: <https://github.com/electerious/Ackee/blob/master/docs/Get%20started.md>
- FAQ: <https://github.com/electerious/Ackee/blob/master/docs/FAQ.md>
- Tracker client: <https://github.com/electerious/ackee-tracker>
- Releases: <https://github.com/electerious/Ackee/releases>
- Plausible (alt): <https://plausible.io>
- Umami (alt): <https://umami.is>
- Matomo (alt): <https://matomo.org>
- GoatCounter (alt): <https://www.goatcounter.com>
- PostHog (alt): <https://posthog.com>
