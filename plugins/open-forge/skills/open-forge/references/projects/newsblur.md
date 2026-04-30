---
name: NewsBlur
description: "Self-hostable RSS feed reader with 'training' (machine-learning hide/boost based on your feedback), social sharing (Blurblog), intelligence classifier, and dedicated mobile apps. Python/Django + MongoDB + Postgres + Redis + Elasticsearch. MIT."
---

# NewsBlur

NewsBlur is an **opinionated RSS reader** — built around personal feed training ("intelligence classifier" learns what stories you like + hides ones you don't), a social layer called **Blurblog** (share stories publicly), and first-class mobile apps. In the post-Google-Reader world, NewsBlur is one of the few feed readers with a comprehensive, polished desktop + iOS + Android experience — and it's been self-hostable for years.

Features:

- **Feed subscriptions** — RSS, Atom, JSON Feed
- **River of news** — one unified reading stream
- **Intelligence** — ML-inspired classifier: thumbs-up/thumbs-down stories, tags, authors, sites; NewsBlur learns to hide the junk and boost the gold
- **Blurblog** — publish stories you liked with a comment; social feed of people you follow
- **Saved stories** + tags
- **Shared stories** + comments (decentralized + on-your-instance)
- **Original story view** — strips ads; extracts article text from noisy sites
- **Premium-tier features** (site content refresh every 10 min vs hourly, search, etc. — mirror hosted NewsBlur's tiers)
- **Dedicated mobile apps** — iOS + Android; sync via NewsBlur API
- **Import/export OPML**
- **Fever API** compatibility — some alternative clients work

- Upstream repo: <https://github.com/samuelclay/NewsBlur>
- Website: <https://www.newsblur.com> (hosted version)
- Docker Hub: <https://hub.docker.com/u/newsblur>
- Docs: in-repo `docs/` + upstream site

## Architecture in one minute

NewsBlur is **resource-heavy** and **microservice-y** — it's the reference-implementation of "this is how a full web app is structured":

- **Django** (Python) — web + API
- **MongoDB** — stories + user states (primary data store)
- **Postgres** — accounts + subscriptions (relational pieces)
- **Redis** — session, cache, queue
- **Elasticsearch** — story search (premium)
- **Celery / RabbitMQ** — feed-fetch workers
- **nginx** — static + reverse proxy
- **Haproxy** (optional) — load balancer in HA setups
- **Node.js** — realtime push service

**Self-hosting single-user on a VPS works** but there's a lot of moving parts. Upstream has been refining the Docker Compose setup; still, expect 4-6 GB RAM minimum.

## Compatible install methods

| Infra        | Runtime                                                | Notes                                                                 |
| ------------ | ------------------------------------------------------ | --------------------------------------------------------------------- |
| Single VM    | **Docker Compose** (many services)                        | **Only realistic DIY path**                                               |
| Kubernetes   | Helm (community / custom)                                      | Possible; nontrivial                                                          |
| Cloud        | `newsblur.com` hosted (Premium $36/yr)                                | Upstream's offering + funds development                                              |
| Bare metal   | Highly discouraged; many interlocking services                                | Use Docker                                                                                       |

## Inputs to collect

| Input            | Example                            | Phase      | Notes                                                          |
| ---------------- | ---------------------------------- | ---------- | -------------------------------------------------------------- |
| Domain           | `news.example.com`                   | URL        | Reverse proxy with TLS                                            |
| Host count       | 1 VM w/ 6+ GB RAM                        | Sizing     | ES + Mongo + Postgres + Redis all in one host = tight                    |
| Mongo            | 5.x                                         | DB         | Shipped in compose                                                           |
| Postgres         | 13+                                              | DB         | Shipped in compose                                                                  |
| Redis            | 6+                                                    | Cache      | Shipped in compose                                                                         |
| Elasticsearch    | 7.x (or OpenSearch)                                       | Search     | Optional; for premium-search equivalent                                                            |
| Admin user       | created via `manage.py createsuperuser`                          | Bootstrap  | Django admin                                                                                       |
| OPML import      | upload your existing subs                                              | Migration  | First-boot from Feedly/Inoreader/Google Reader export                                                              |
| Secret key       | Django SECRET_KEY                                                           | Crypto     | Don't rotate                                                                                                        |
| Fetch interval   | default per premium status                                                      | Workers    | How often feeds refresh                                                                                                      |

## Install via Docker Compose

Clone the repo, follow `docker/docker-compose.yml`. It's large — 10+ services.

Minimum env to set:

```yaml
services:
  newsblur_web:
    image: newsblur/newsblur_web:latest   # pin to a specific version in prod
    environment:
      NEWSBLUR_URL: https://news.example.com
      DJANGO_SECRET_KEY: <random-64-chars>
      DATABASE_URL: postgres://newsblur:<strong>@postgres:5432/newsblur
      MONGO_DB: mongodb://mongo:27017/newsblur
      REDIS_URL: redis://redis:6379/0
      ...
```

Follow upstream's `docker/` directory for the canonical stack + env reference.

## First boot

1. `docker compose up -d`
2. Run initial migrations: `docker compose exec newsblur_web python manage.py migrate`
3. Create superuser: `docker compose exec newsblur_web python manage.py createsuperuser`
4. Browse `https://news.example.com/` → register / log in
5. Import your OPML: Settings → Account → Import
6. Add a feed: URL or website → NewsBlur auto-discovers feeds
7. Train the classifier: thumbs-up / thumbs-down stories → "intelligence" tab shows hidden + promoted
8. (Optional) Publish to Blurblog → stories you share appear at `news.example.com/social/<username>/`

## Data & config layout

- Postgres volume — users, subs
- Mongo volume — stories, per-user story state (read/saved/classifiers)
- Redis volume — caches + session
- ES volume — story search index
- RabbitMQ/queues — feed-fetch tasks
- `media/` — uploaded avatars, icons

## Backup

Multi-database — back up ALL of them:

```sh
# Postgres
docker exec newsblur-postgres pg_dump -U newsblur newsblur | gzip > nb-pg-$(date +%F).sql.gz

# Mongo (big)
docker exec newsblur-mongo mongodump --archive=/tmp/mongo.dump
docker cp newsblur-mongo:/tmp/mongo.dump ./nb-mongo-$(date +%F).dump

# Redis (cache; less critical — state can be rebuilt)
# Elasticsearch (reindexable from Mongo)
```

## Upgrade

1. Releases: <https://github.com/samuelclay/NewsBlur/releases> (and main-branch tags).
2. **Back up Postgres + Mongo first.**
3. Bump image tags, `docker compose pull && docker compose up -d`.
4. Run migrations: `python manage.py migrate`.
5. Occasional schema changes — follow release notes.

## Gotchas

- **This is a heavyweight self-host.** NewsBlur is designed for a SaaS company; the self-host story exists but is not minimal. If you want "a single Docker container that gives you RSS," try **Miniflux** or **FreshRSS** (both already cataloged) — those are 10x simpler to run.
- **RAM floor is ~6 GB** for comfortable single-user. Postgres + Mongo + Redis + ES + RabbitMQ + workers + web + frontend all fighting for resources on one box.
- **Celery queue must run** — without workers, feeds don't fetch. Common first-deploy gotcha: only starting web, not workers.
- **Feed refresh cadence** — by default, workers poll feeds at an interval based on "premium" flag. For single-user self-host, set yourself as premium in admin (otherwise you get long refresh intervals).
- **Mobile apps** — NewsBlur iOS + Android apps connect via API. **The app store versions default to `newsblur.com`**; there's community work to switch them to self-hosted but it's not officially supported in all versions. Expect friction.
- **OAuth + social logins**: disabled by default; configure in Django settings if wanted.
- **Fever API** compatibility — enables alternative clients (Reeder, Unread) to connect to your NewsBlur instance. Configure endpoint carefully.
- **Story text extraction** — uses `newspaper3k` or similar; some sites hide content; extraction is best-effort.
- **Hidden stories don't auto-purge** — classifier hides from view but keeps in DB. Disk grows over time. Periodic cleanup helps.
- **NewsBlur is polyglot** — Python (Django) + Node.js (realtime) + small ES + lots of templating. More moving parts = more to break. Read logs of each service when debugging.
- **Hosted upstream** (`newsblur.com`) is $36/year; funds development. If you just want a polished RSS reader, paying upstream and skipping ops might be the right call.
- **Community around self-hosted NewsBlur is small** — most users use hosted. Support + docs skew toward SaaS ops. Homelab community is stronger around Miniflux / FreshRSS / FreshReader / Stringer.
- **License**: MIT.
- **Alternatives worth knowing:**
  - **Miniflux** — minimalist, single Go binary, Postgres; the "just serve me RSS" pick (separate recipe)
  - **FreshRSS** — PHP, features-rich (folders, favicons, keyboard), friendly install (separate recipe — likely)
  - **Tiny Tiny RSS (tt-rss)** — older PHP reader; still used
  - **Reeder / Unread / Feedbin / Inoreader / Feedly** — SaaS / commercial
  - **Stringer** — Ruby; lightweight
  - **Commafeed** — Java; enterprise-y
  - **FreshReader** — newer entry
  - **Choose NewsBlur if:** you want the intelligence-classifier + Blurblog social + polished mobile apps.
  - **Choose Miniflux if:** you want dead-simple, low-resource, do-one-thing-well self-hosting.
  - **Choose FreshRSS if:** you want features + middle ground; great community.
  - **Choose hosted NewsBlur if:** you want the product without the ops.

## Links

- Repo: <https://github.com/samuelclay/NewsBlur>
- Website (hosted): <https://www.newsblur.com>
- Docker images: <https://hub.docker.com/u/newsblur>
- Releases: <https://github.com/samuelclay/NewsBlur/releases>
- Docs: <https://github.com/samuelclay/NewsBlur/tree/master/docs>
- iOS app: <https://apps.apple.com/us/app/newsblur/id463981119>
- Android app: <https://play.google.com/store/apps/details?id=com.newsblur>
- Developer blog: <https://blog.newsblur.com>
- Miniflux alternative: <https://miniflux.app>
- FreshRSS alternative: <https://freshrss.org>
- OPML spec: <http://opml.org>
