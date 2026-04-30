---
name: BookWyrm
description: "Federated social network for reading + books + reviews. ActivityPub-based; federates with Mastodon/Pleroma/other BookWyrm instances. Python/Django. Community-governed; Patreon-funded; AGPL. 'Small, high-trust communities' design philosophy."
---

# BookWyrm

BookWyrm is **"Goodreads / StoryGraph — but federated + small-scale + OSS + community-governed"** — a social network for tracking reading, reviewing books, writing reviews, discovering what to read. **Federation** via ActivityPub allows BookWyrm instances to inter-operate with each other and with Mastodon/Pleroma/other ActivityPub services. Philosophy: "small, trusted communities" (vs monolithic Goodreads/Twitter). Run an instance for your book club; follow friends on other instances or on Mastodon.

Built + maintained by **bookwyrm-social community** + Patreon-funded. License: AGPL-3.0 (check). Active; Mastodon presence; docs at docs.joinbookwyrm.com; Ruff CI; Python/Django. README has explicit "please do not submit AI-generated code" directive — respect human-made contributions.

Use cases: (a) **book club instance** — private group + own ActivityPub identity (b) **replace Goodreads** — escape Amazon-owned walled-garden (c) **federated reading-network** — follow friends across instances (d) **genre-focused community** — sci-fi-only / lit-fic-only instance (e) **classroom / university instance** — course reading-lists (f) **privacy-respecting reading tracker** — no ad-targeting (g) **cross-platform conversation** — Mastodon users can reply to BookWyrm reviews (h) **collaborative book database** — federated metadata sharing.

Features (per README + docs):

- **Social reading network**
- **Book reviews + quotes + reading-status**
- **Federation via ActivityPub** — inter-operates with Mastodon, Pleroma, other BookWyrm
- **Lists** — share reading lists
- **Book database** — collaboratively maintained, federated
- **Python/Django**
- **Self-governed** small-instance philosophy

- Upstream repo: <https://github.com/bookwyrm-social/bookwyrm>
- Project home: <https://joinbookwyrm.com>
- Docs: <https://docs.joinbookwyrm.com>
- Patreon: <https://patreon.com/bookwyrm>
- FEDERATION.md: <https://github.com/bookwyrm-social/bookwyrm/blob/main/FEDERATION.md>

## Architecture in one minute

- **Python + Django**
- **PostgreSQL** DB
- **Redis**
- **Celery** (task queue)
- **Nginx** reverse-proxy typical
- **ActivityPub federation**
- **Resource**: moderate — 1-2GB RAM

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker Compose** | **Upstream**                                                    | **Primary**                                                                        |
| Source             | Python/Django                                                                            | Dev                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `books.example.com`                                         | URL          | **IMMUTABLE** (federation identity)                                                                                    |
| Admin creds          | First-boot                                                  | Bootstrap    | Strong                                                                                    |
| PostgreSQL           | Data                                                        | DB           |                                                                                    |
| Redis                | Cache + queue                                               | Infra        |                                                                                    |
| `SECRET_KEY` (Django) | Signing                                                    | **CRITICAL** | **IMMUTABLE** — leaked = session-forge                                                                                    |
| Email (SMTP)         | Account emails, federation-recovery                         | Notifications |                                                                                    |
| Federation allowlist/blocklist | Per-instance policy                                                                         | Config       |                                                                                    |
| S3 (opt)             | Media storage                                                                                                          | Storage      |                                                                                    |

## Install via Docker

Follow upstream docs — docker-compose with Django + Celery + Postgres + Redis + Nginx.

## First boot

1. Follow <https://docs.joinbookwyrm.com> carefully
2. Configure domain + SECRET_KEY + DB + SMTP BEFORE starting
3. Start stack → run initial migrations + create admin
4. Configure email verification
5. Set federation policy (open / invite-only / private)
6. Test local posting first
7. Test federation to a known remote instance
8. Set up content-moderation policy
9. Back up DB + media religiously

## Data & config layout

- PostgreSQL — users, books, reviews, lists, federation state
- Redis — cache + Celery queue
- Media — user uploads (avatars, cover images) — local OR S3

## Backup

```sh
docker compose exec db pg_dump -U bookwyrm bookwyrm > bookwyrm-$(date +%F).sql
sudo tar czf bookwyrm-media-$(date +%F).tgz media/
```

## Upgrade

1. Releases: <https://github.com/bookwyrm-social/bookwyrm/releases>. Active.
2. **Read release notes** — federated software requires migration-discipline
3. Docker pull + migrate
4. ActivityPub-protocol-compatibility = critical at major versions

## Gotchas

- **ACTIVITYPUB FEDERATION = IDENTITY-BOUND DOMAIN**:
  - Domain is part of your ActivityPub identity (`@user@books.example.com`)
  - **Changing domain breaks all federation** — followers lose connection
  - **Recipe convention: "IMMUTABLE-domain-for-federated-services"** — extended (prior: Mastodon, Pixelfed, Lemmy, Matrix)
  - Pick carefully; don't change
- **FEDERATED-SOCIAL-NETWORK-CATEGORY (ActivityPub ecosystem):**
  - **BookWyrm** — books + reviews
  - **Mastodon** — microblog
  - **Pleroma** — microblog (alt implementation)
  - **Pixelfed** — photos
  - **PeerTube** — video
  - **Funkwhale** — music
  - **WriteFreely** — blog
  - **Lemmy** — forums
  - **Kbin** — forums
  - **Mobilizon** — events
  - **Friendica / Hubzilla** — general-purpose
  - **Movim** — XMPP-based social
- **CONTENT MODERATION BURDEN**:
  - Instance admin is responsible for hosted content
  - Abusive content, illegal content, harassment from federated sources
  - **Recipe convention: "federated-instance-moderation-burden" callout** — extended from Mastodon precedent
- **INSTANCE BLOCK/ALLOW POLICY**:
  - Defederate abusive/bad-actor instances
  - Requires policy + review + action
  - **Recipe convention: "federation-allowlist-blocklist-discipline"** — standard
- **92nd HUB-OF-CREDENTIALS TIER 2**:
  - User accounts + OAuth tokens + reading-history + reviews
  - **Reading-history + annotations = personal-insight data**
  - **Reading-annotations-intimate-personal-data convention** (from Grimmory 105) applies
  - **92nd tool in hub-of-credentials family — Tier 2**
- **COMMUNITY-GOVERNED + PATREON = SUSTAINABILITY MODEL**:
  - Patreon-funded core development
  - Community governance (bookwyrm-social org, not single-maintainer)
  - **NEW institutional-stewardship sub-tier: "community-governed-ActivityPub-project"** — is this really new? Similar to Lemmy's "LemmyNet community governance"
  - Verify against prior Mastodon / Lemmy / Pixelfed records — likely already categorized
  - **Recipe convention: "community-governed-ActivityPub-project" if new; otherwise reuse prior sub-tier**
- **AGPL NETWORK-SERVICE**:
  - Self-host + serve = AGPL disclosure applies
  - **17th tool in AGPL-network-service-disclosure**
- **BOOK-METADATA SCRAPING LEGALITY**:
  - BookWyrm pulls book metadata from Open Library / similar
  - Generally fine (open databases) — but commercial scraping limits apply
  - Not same risk-profile as Grimmory-at-Goodreads (anti-scraping + TOS)
  - **Recipe convention: "open-metadata-source-positive-signal"** — neutral
- **PROMPT-INJECTION-FRIENDLY DIRECTIVE IN README**:
  - Explicit "please do NOT submit AI-generated code" directive
  - Respect author's human-made-content norm
  - **Recipe convention: "no-AI-code-contribution-norm" callout** — respect
  - **NEW recipe convention** (BookWyrm 1st formally)
- **SMALL-INSTANCE PHILOSOPHY**:
  - Design-intent: runyourown.social style; 50-500 users not 50,000
  - Don't expect to scale an instance to Goodreads-size
  - **Recipe convention: "small-scale-instance-design-intent positive-signal"** — intentional design
  - **NEW positive-signal convention**
- **TECH.LGBT MASTODON PRESENCE**:
  - Community presence on LGBTQ+-friendly Mastodon instance
  - Signals inclusive community norm
  - **Recipe convention: "inclusive-community-signal"** — soft positive
- **INSTITUTIONAL-STEWARDSHIP**: bookwyrm-social org + Patreon + community. **78th tool — community-governed-ActivityPub-project sub-tier** (reuses Lemmy/Mastodon-style governance pattern).
- **TRANSPARENT-MAINTENANCE**: active + Ruff CI + docs + Patreon + Mastodon-presence + FEDERATION.md + inclusive-community. **86th tool in transparent-maintenance family.**
- **ALTERNATIVES WORTH KNOWING:**
  - **Goodreads** (Amazon) — if you want the network effect
  - **StoryGraph** — if you want modern commercial alternative
  - **LibraryThing** — if you want cataloguing-first
  - **Open Library** — if you want public book database
  - **Calibre / Calibre-Web** (prior batches) — if you want personal ebook library
  - **Choose BookWyrm if:** you want federation + OSS + community + small-scale + ActivityPub integration.
- **PROJECT HEALTH**: active + community-governed + Patreon + docs + Mastodon + federation + CI. Strong.

## Links

- Repo: <https://github.com/bookwyrm-social/bookwyrm>
- Home: <https://joinbookwyrm.com>
- Docs: <https://docs.joinbookwyrm.com>
- Grimmory (batch 105; similar reading-risk): <https://github.com/grimmory-io/grimmory>
- Mastodon: <https://joinmastodon.org>
- StoryGraph (commercial alt): <https://www.thestorygraph.com>
- runyourown.social: <https://runyourown.social>
