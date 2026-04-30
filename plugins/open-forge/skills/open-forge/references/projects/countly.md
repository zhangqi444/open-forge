---
name: Countly
description: "Privacy-first, self-hostable product analytics + customer engagement platform — mobile, web, desktop, IoT. On-prem or private-cloud deployment; no SaaS-only lock-in. Community Edition (open-source, non-commercial) + Enterprise (commercial). MongoDB + Node.js. AGPL-3.0 + commercial."
---

# Countly

Countly is **a self-hostable product analytics + customer engagement platform** — think Google Analytics / Mixpanel / Amplitude / Heap, but you run it on your infrastructure. Users track events from mobile apps, web apps, desktop apps, and IoT devices via Countly SDKs (Android, iOS, Flutter, React Native, JavaScript, Unity, Unreal, .NET, Python, PHP, many more), and you get dashboards + real-time user activity + retention cohorts + funnels + A/B testing + push notifications + in-app messaging + crash reports.

**Positioning**: privacy-first + self-host-first. Countly explicitly markets on-prem / private-cloud deployment as the differentiator vs Mixpanel/Amplitude/GA4.

> **⚠️ License clarity — read carefully:**
> - **Countly Lite** = core analytics + essentials; **open-source under a non-commercial-use license** (AGPL-3.0 with additional terms). Free for non-commercial or small teams.
> - **Countly Enterprise** = full analytics + engagement + push + advanced retention + A/B tests + SLA support; **proprietary commercial**.
> - **Read LICENSE before using in commercial settings** — the Lite license has commercial-use restrictions. Different from typical AGPL/MIT.

Features (Lite + Enterprise):

- **Event tracking** — flexible custom events with segments
- **Sessions + user profiles** — retention, stickiness, cohort analysis
- **Funnels + flows + retention**
- **Crash reports** — stack traces + device breakdown
- **Performance monitoring** — APM for mobile + web
- **Push notifications** (Enterprise) — APNS + FCM
- **In-app messaging** — pop-ups, banners, survey triggers
- **Remote config + feature flags**
- **A/B testing**
- **User engagement** — segmentation + targeted campaigns
- **Server-side SDK support** — Node, Python, PHP, Go, Java, .NET
- **Device SDKs** — all major mobile + web + IoT runtimes
- **Plugin architecture** — extend with custom metrics
- **SSO** — SAML/OIDC/LDAP (Enterprise)
- **GDPR/CCPA compliance tools**

- Upstream repo: <https://github.com/Countly/countly-server>
- Website: <https://countly.com>
- SDKs + docs: <https://support.countly.com>
- Installation: <https://support.countly.com/hc/en-us/articles/360036862332-Installing-the-Countly-Server>
- Discord: <https://discord.gg/countly>
- Pricing (Enterprise): <https://countly.com/pricing>

## Architecture in one minute

- **Node.js** API + dashboard servers
- **MongoDB** — main DB (events, profiles, aggregations)
- **Redis** (optional — caching)
- **Plugin-based architecture** — many features live as plugins
- **Nginx / Apache** in front (reverse proxy)
- **Resource**: small deployments ~2-4 GB RAM; millions of events/day needs sharded MongoDB + multiple Countly nodes

## Compatible install methods

| Infra              | Runtime                                                          | Notes                                                                           |
| ------------------ | ---------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| Single VM          | **Official install script on Ubuntu LTS**                            | **Upstream-documented primary path**                                                |
| Single VM          | **Docker Compose**                                                           | Community + official images                                                                   |
| Kubernetes         | Helm chart (Enterprise support; community manifests exist)                                   | Scale path                                                                                                   |
| Cluster            | Multi-node Countly + sharded MongoDB                                                                        | Production-scale HA                                                                                                             |
| Managed            | **Countly Cloud** (Enterprise SaaS)                                                                                     | Commercial hosted                                                                                                                       |
| Raspberry Pi       | Not the target — MongoDB footprint                                                                                                  |                                                                                                                                                            |

## Inputs to collect

| Input              | Example                                | Phase      | Notes                                                                      |
| ------------------ | -------------------------------------- | ---------- | -------------------------------------------------------------------------- |
| Domain             | `analytics.example.com`                       | URL        | For SDK endpoints + dashboard                                                        |
| MongoDB            | connection string                                   | DB         | Bundled or external Atlas/self-host                                                                 |
| Admin account      | first user on setup wizard                                   | Bootstrap  | Set strong password; enable 2FA                                                                                     |
| SMTP (opt)         | for user invites + alerts                                             | Email      | Optional                                                                                                              |
| TLS                | mandatory for mobile SDK data ingestion                                        | Security   | Mobile OS certificate policies                                                                                                         |
| App keys           | one per tracked app                                                                    | SDK        | Generated in dashboard                                                                                                                                    |

## Install via Docker Compose

```yaml
services:
  mongo:
    image: mongo:6
    volumes:
      - ./mongo:/data/db
  countly-api:
    image: countly/countly-server:latest              # pin in prod
    environment:
      COUNTLY_CONFIG_API_MONGODB: mongodb://mongo:27017/countly
    depends_on:
      - mongo
    ports:
      - "3001:3001"
  countly-frontend:
    image: countly/countly-server:latest
    command: ["frontend"]
    environment:
      COUNTLY_CONFIG_FRONTEND_MONGODB: mongodb://mongo:27017/countly
    depends_on:
      - mongo
    ports:
      - "6001:6001"
```

(Simplified — upstream provides a full Compose for prod.) Put behind TLS reverse proxy; configure SDK endpoint URL.

## First boot

1. Browse the dashboard port → setup wizard
2. Create super-admin
3. **Create an App** → pick type (Mobile / Web / Desktop / Server) → copy App Key
4. Integrate SDK in your app → point at `https://analytics.example.com/` with App Key
5. Test events → watch them appear in real-time
6. Build your first funnel / cohort
7. Configure alerts + dashboards

## Data & config layout

- MongoDB — everything (events, users, sessions, config)
- `/opt/countly/` (native install) — server code
- Config in MongoDB + env + `frontend/express/config.js` / `api/config.js`

## Backup

```sh
# MongoDB (CRITICAL — all analytics)
docker exec countly-mongo mongodump --uri mongodb://localhost/countly --archive | gzip > countly-$(date +%F).gz
```

Analytics data grows quickly — plan retention (e.g., keep raw events 90 days, aggregates 2 years).

## Upgrade

1. Releases: <https://github.com/Countly/countly-server/releases>. Regular.
2. Back up MongoDB.
3. Docker: bump tag → restart; migrations auto.
4. Native: upstream upgrade script — run + verify.

## Gotchas

- **License complexity — read it.** Lite is open-source but **non-commercial** use-restricted in parts; Enterprise is proprietary. If you deploy for a commercial product, confirm Enterprise license or ensure your Lite usage fits the non-commercial terms.
- **Privacy-first positioning**: Countly explicitly differentiates on not-SaaS; self-host = you own the data. Good fit for EU/GDPR + healthcare + government + any data-sovereignty-sensitive workload.
- **Mobile SDK HTTPS requirement**: iOS (ATS) + Android (CNIC restrictions) require HTTPS for analytics endpoints. Self-signed = extra work. Use Let's Encrypt.
- **MongoDB sizing**: events accumulate fast. Millions of events/day needs sharding + indexes + retention policy. Plan disk at ~10-50 bytes per event (after compression) for mobile analytics.
- **Real-time dashboards** on large datasets can be slow without proper indexes + aggregations — Countly's background aggregation jobs are critical; monitor they're running.
- **SDK versioning**: client SDKs evolve; server expects compatible schemas. Keep server + SDKs within one major version.
- **Push notifications (Enterprise)** require APNS certs (iOS) + FCM server keys (Android). Configure per-app.
- **Enterprise vs Lite feature matrix**: many "advanced" features (push, retention cohorts, flows, A/B testing, iframe embedding, SSO) are Enterprise-gated. Check feature list against pricing before committing.
- **Plugin management**: many features live as plugins; enable/disable in admin → Configurations. Some community plugins are unmaintained.
- **SDK opt-in for GDPR**: Countly SDKs have explicit GDPR consent helpers. Use them; don't default users to tracked.
- **Self-hosted Countly isn't ad-network-clean**: if you plan to monetize with ads, Mixpanel / Amplitude integrations with ad tools are deeper; Countly is for product analytics more than ad attribution.
- **Comparison to GA4**: GA4 is free + SaaS + cookie-dependent; Countly is self-host + consent-aware + SDK-based. Different philosophies.
- **Comparison to PostHog**: PostHog is also open-source + self-host-capable + feature-rich; competes directly. PostHog uses Postgres+ClickHouse; Countly uses MongoDB. Architecture preference often decides.
- **Comparison to Plausible / Umami / Matomo**: those are web-analytics-focused; Countly is product/app analytics (cohorts, funnels, user profiles).
- **Resource scaling**: small teams fine on one node; Mixpanel-scale (billions of events) needs MongoDB shards + multiple Countly nodes + ops team. Contact Countly for Enterprise architecture.
- **License**: **AGPL-3.0 with additional non-commercial terms for Lite**. Read <https://github.com/Countly/countly-server/blob/master/LICENSE>.
- **Alternatives worth knowing:**
  - **PostHog** — modern OSS product analytics; Postgres+ClickHouse (separate recipe likely)
  - **Matomo** — web analytics; PHP; mature (separate recipe likely)
  - **Plausible** / **Umami** — lightweight privacy-focused web analytics (separate recipes likely)
  - **Mixpanel** / **Amplitude** / **Heap** — commercial SaaS product analytics
  - **GA4** — free SaaS; cookie-based; privacy-invasive
  - **Snowplow** — open-source event pipeline; big-data-oriented
  - **OpenPanel** — newer OSS alternative
  - **Aptabase** — minimalist mobile analytics
  - **Choose Countly if:** you need product analytics + engagement (push/A-B/in-app) + self-host + multi-platform SDKs.
  - **Choose PostHog if:** you want Postgres/ClickHouse stack + active modern development.
  - **Choose Matomo/Plausible if:** web-only analytics + simpler.
  - **Choose Mixpanel/Amplitude if:** commercial SaaS + zero ops acceptable.

## Links

- Repo: <https://github.com/Countly/countly-server>
- Website: <https://countly.com>
- Install guide: <https://support.countly.com/hc/en-us/articles/360036862332-Installing-the-Countly-Server>
- SDKs: <https://support.countly.com/hc/en-us/articles/360037236571-Downloading-and-Installing-SDKs>
- Docs: <https://support.countly.com>
- Releases: <https://github.com/Countly/countly-server/releases>
- Discord: <https://discord.gg/countly>
- Pricing (Enterprise / Cloud): <https://countly.com/pricing>
- PostHog (alt): <https://posthog.com>
- Matomo (alt): <https://matomo.org>
- Plausible (alt): <https://plausible.io>
- Umami (alt): <https://umami.is>
- Snowplow (alt): <https://snowplow.io>
