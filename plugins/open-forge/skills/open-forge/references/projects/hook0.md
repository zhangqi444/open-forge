---
name: Hook0
description: "Open-source webhooks-as-a-service server and UI. Rust + PostgreSQL. hook0/hook0. Fine-grained subscriptions, auto-retry, event/response persistence, JSON REST API. Cloud + self-hosted."
---

# Hook0

**Open-source webhooks-as-a-service.** Add outbound webhook delivery to your SaaS app — let your users subscribe to your application's events via webhook. Fine-grained event-type subscriptions, auto retry on failure, event and webhook-call persistence (for debugging), a modern management dashboard, and a JSON REST API. Self-host or use the free Hook0 Cloud tier.

Built + maintained by **Hook0 SAS** (French company). SSPL v1 license.

- Upstream repo: <https://github.com/hook0/hook0>
- Docs: <https://documentation.hook0.com>
- Cloud: <https://www.hook0.com>
- Discord: <https://www.hook0.com/community>
- API reference: <https://documentation.hook0.com/reference/>
- Roadmap: <https://gitlab.com/hook0/hook0/-/boards>

## Architecture in one minute

- **Rust** backend (monolith or microservices via the same binary)
- **PostgreSQL 18+** database (required)
- Docker + Dockerfile available
- REST API under `/api/v1/`
- Dashboard UI (modern web frontend)
- Resource: **low** — compiled Rust binary + Postgres; efficient at scale

## Compatible install methods

| Infra             | Runtime                   | Notes                                                                          |
| ----------------- | ------------------------- | ------------------------------------------------------------------------------ |
| **Docker**        | Docker Hub (`hook0/hook0`) | **Primary for self-hosting**; Dockerfile in repo                               |
| **Source**        | Rust + Postgres           | `cargo build --release`; requires Rust toolchain                               |
| **Hook0 Cloud**   | <https://hook0.com>       | Free tier; 90-second project creation; no self-hosting needed for evaluation  |

## Inputs to collect

| Input                        | Example                              | Phase    | Notes                                                                                  |
| ---------------------------- | ------------------------------------ | -------- | -------------------------------------------------------------------------------------- |
| PostgreSQL connection string | `postgres://user:pass@host:5432/db`  | Storage  | PostgreSQL 18+ required; can be external managed DB or local container                |
| Domain                       | `webhooks.example.com`               | URL      | Reverse proxy + TLS; used in webhook delivery headers                                 |
| Admin credentials            | email + password                     | Auth     | Set during initial setup                                                               |

## How Hook0 works

Hook0 sits between your application and your users' webhook endpoints:

```
Your app → [publishes events] → Hook0 → [delivers to] → User's webhook URL
```

1. **Your app** publishes events to Hook0's API (e.g. `user.created`, `payment.failed`).
2. **Your users** subscribe to event types they care about + provide their webhook URL.
3. **Hook0** delivers events to subscribed endpoints, retries on failure, and logs everything.

## Install via Docker

```bash
# Requires Postgres 18+ running externally or in compose
docker run -d \
  --name hook0 \
  -p 8080:8080 \
  -e DATABASE_URL="postgres://hook0:password@postgres:5432/hook0" \
  hook0/hook0:latest
```

See the [Hook0 documentation](https://documentation.hook0.com) for the full Docker Compose setup with Postgres.

## First boot

1. Deploy Hook0 + Postgres.
2. Visit the dashboard URL.
3. Create an **Organization** and initial **Application** (represents your SaaS app).
4. Define **event types** your app will emit (e.g. `user.created`, `invoice.paid`).
5. Integrate your app: call Hook0's API when events occur (e.g. POST to `/api/v1/organizations/{org}/applications/{app}/events`).
6. Users/subscribers add webhook subscriptions (via your UI or Hook0 dashboard) to their event types of interest.
7. Test with a webhook endpoint (e.g. webhook.site or requestbin).
8. Put behind TLS.

## Key API concepts

| Concept | Description |
|---------|-------------|
| **Organization** | Top-level namespace (your company/team) |
| **Application** | Your SaaS product within the organization |
| **Event type** | Named event your app emits (`user.created`, etc.) |
| **Event** | An instance of an event type with a payload |
| **Subscription** | A user's registration: "send me events of type X to URL Y" |
| **Webhook call** | One HTTP delivery attempt to a subscriber's endpoint |

## Backup

```sh
# Postgres dump (all events, subscriptions, delivery logs)
pg_dump postgres://hook0:password@postgres:5432/hook0 > hook0-$(date +%F).sql
```

Contents: event history, subscriber URLs + secrets, delivery logs. Subscriber webhook URLs may be sensitive (could accept arbitrary data). Protect accordingly.

## Upgrade

1. Releases: <https://github.com/hook0/hook0/releases>
2. `docker pull hook0/hook0:latest && docker compose up -d`
3. Run DB migrations (the binary handles this on startup — check release notes for manual steps).

## Gotchas

- **SSPL v1 license — not permissive.** SSPL is OSI-debated. The key restriction: **you cannot offer Hook0 as a managed service** to others without open-sourcing your entire service stack. For internal use (adding webhooks to your own SaaS), it's effectively free. For reselling webhooks-as-a-service, you need a commercial license from Hook0 SAS.
- **PostgreSQL 18+ required.** Newer than most distros ship by default. Use the official PostgreSQL Docker image or the Postgres.app; don't use a package manager Postgres without checking the version.
- **Primary development is on GitLab.** The GitHub repo mirrors the GitLab project (`gitlab.com/hook0/hook0`). Issues, roadmap, and MRs are primarily tracked in GitLab.
- **Retry behavior.** Auto-retry on webhook delivery failure uses exponential backoff. The persistence layer lets you see exactly which calls failed, what the response was, and when retries are scheduled.
- **Event scoping.** Hook0 supports event type scoping — subscribers can request only specific subtypes. Useful for noisy event streams where users don't want every variant.
- **View counts on events.** Events and webhook call responses are persisted indefinitely (unless you set a retention policy). This is essential for debugging but grows your DB over time — plan for retention or archiving.
- **Hook0 Cloud free tier** is the fastest evaluation path — spin up a project in 90 seconds, no Postgres to manage. Move to self-hosting when you need data sovereignty or budget control.

## Project health

Active Rust development, French company backing, Discord, docs, free cloud tier, PostgreSQL-backed, SSPL licensed. Issues/roadmap primarily in GitLab.

## Webhooks-infrastructure-family comparison

- **Hook0** — Rust + Postgres, SSPL, full webhook server + UI + API, fine-grained subscriptions, retry
- **Svix** — SaaS webhooks platform (not self-hosted); polished, generous free tier
- **Standard Webhooks** — spec/standard only; no server
- **Zapier / Make** — SaaS workflow automation; overlapping use case; not a webhook server
- **custom implementation** — most devs roll their own webhook queue (Postgres + worker); Hook0 replaces that

**Choose Hook0 if:** you're building a SaaS and want to add self-hostable webhook infrastructure for your users — with subscriptions, retries, delivery logs, and a dashboard — without building it yourself.

## Links

- Repo: <https://github.com/hook0/hook0>
- Docs: <https://documentation.hook0.com>
- API reference: <https://documentation.hook0.com/reference/>
- Cloud (free tier): <https://www.hook0.com>
- Discord: <https://www.hook0.com/community>
- GitLab (primary): <https://gitlab.com/hook0/hook0>
