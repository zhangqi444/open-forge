---
name: Coral (Talk)
description: "Open-source commenting platform by Vox Media. Comment moderation; display; conversation quality. Node.js. coralproject/talk. Docker Hub. Docs + guides sites."
---

# Coral (Talk)

Coral is **"Disqus — but open-source, journalistic-grade, moderation-focused, by Vox Media"** — an open-source commenting platform designed to rethink moderation, comment display, and conversation quality for **safer, smarter discussions** around online articles. Used by news publishers.

Built + maintained by **Coral Project / Vox Media** (coralproject org). Long-running (decade-plus). Docker Hub. Docs site + community guides site. License: Apache-2.0 likely.

Use cases: (a) **newsroom commenting-system** — replace Disqus (b) **moderated public-discussion** — for editorial sites (c) **community-guidelines-enforced comments** (d) **Q&A style commenting** (e) **event live-blog commenting** (f) **independent-publication commenting** (g) **moderation-heavy platform** (abusive audiences) (h) **embedded-in-CMS commenting** (WordPress, etc.).

Features (per README + docs):

- **Rethinks moderation UX**
- **Rethinks display** of comments
- **Community guidelines** built-in
- **Embeddable** in sites/CMS
- **Docker-deployable**
- **Vox-Media-produced + used** (dogfooded)

- Upstream repo: <https://github.com/coralproject/talk>
- Website: <https://coralproject.net>
- Docs: <https://docs.coralproject.net>
- Community guides: <https://guides.coralproject.net>

## Architecture in one minute

- **Node.js** + GraphQL
- **MongoDB** data
- **Redis** cache
- **Docker** primary deploy
- **Resource**: ~1GB
- **Port**: web UI + embed JS

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **`coralproject/talk`**                                         | **Primary**                                                                        |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `comments.example.com`                                      | URL          | TLS                                                                                    |
| Embedded site(s)     | Your article-site URL(s)                                    | Config       | Per-site tenant                                                                                    |
| Admin creds          | First-boot                                                  | Bootstrap    |                                                                                    |
| MongoDB              | Data                                                        | DB           |                                                                                    |
| Redis                | Cache                                                       | Infra        |                                                                                    |
| SSO (opt)            | Auth                                                        | Integration  | For tenant-sites                                                                                    |
| Moderation team      | Humans!                                                     | Ops          |                                                                                    |

## Install via Docker

See <https://docs.coralproject.net/getting-started/>. Typical:
```yaml
services:
  mongo:
    image: mongo:4        # Older may be required — check Coral version
  redis:
    image: redis:6
  talk:
    image: coralproject/talk:latest        # **pin**
    ports: ["3000:3000"]
    environment:
      MONGODB_URI: mongodb://mongo:27017/coral
      REDIS_URI: redis://redis:6379
      SIGNING_SECRET: ${SIGNING_SECRET}
    depends_on: [mongo, redis]
```

Embed in your site:
```html
<script>
(function() {
  var d = document, s = d.createElement('script');
  s.src = 'https://comments.example.com/assets/js/embed.js';
  // ... see docs
})();
</script>
```

## First boot

1. Start
2. Create admin user
3. Configure tenant for each article-site
4. Embed JS on articles
5. Set community guidelines
6. Train moderators
7. Put behind TLS
8. Back up MongoDB

## Data & config layout

- MongoDB: comments, users, tenants, moderation actions
- Redis: cache + real-time events

## Backup

```sh
docker compose exec mongo mongodump --archive | gzip > coral-$(date +%F).gz
# Contains all user comments + PII — ENCRYPT
```

## Upgrade

1. Releases: <https://github.com/coralproject/talk/releases>
2. Migration guide for major versions
3. Docker pull + restart

## Gotchas

- **155th HUB-OF-CREDENTIALS CROWN-JEWEL TIER 1 — PUBLIC-COMMENT-MODERATION-LIABILITY**:
  - Holds: all public comments (user-generated content) + user accounts + moderation history
  - Legal exposure: defamatory comments, Section-230/equivalent
  - GDPR: user data + right-to-deletion
  - **155th tool in hub-of-credentials family — Tier 1 CROWN-JEWEL**
  - **NEW CROWN-JEWEL Tier 1 sub-category: "public-comment-moderation-platform-newsroom"** (1st — Coral)
  - **CROWN-JEWEL Tier 1: 50 tools / 47 sub-categories** 🎯 **50-TOOL CROWN-JEWEL MILESTONE**
- **USER-GENERATED-CONTENT-LEGAL-LIABILITY**:
  - Hosting comments = takedown-request handling
  - Moderator liability
  - **Recipe convention: "UGC-comment-platform-legal-exposure callout"**
  - **NEW recipe convention** (Coral 1st formally)
  - **Public-UGC-abuse-conduit: 9 tools** (+Coral) 🎯 **9-TOOL MILESTONE**
- **MODERATION-TEAM-REQUIREMENT**:
  - Self-moderation doesn't scale
  - Human moderators critical
  - **Recipe convention: "human-moderation-team-staffing callout"**
  - **NEW recipe convention** (Coral 1st formally)
- **EMBED-XSS-RISK**:
  - Third-party site embeds Coral JS
  - If Coral compromised, CHILDR could inject to all embedding sites
  - **Recipe convention: "embedded-tool-XSS-blast-radius callout"**
  - **NEW recipe convention** (Coral 1st formally)
- **VOX-MEDIA-PRODUCT-LINEAGE**:
  - Built and dogfooded by Vox Media
  - Maturity + real-production-use
  - **Recipe convention: "publisher-dogfooded-OSS positive-signal"**
  - **NEW positive-signal convention** (Coral 1st formally)
- **DECADE-PLUS-OSS**:
  - **Decade-plus-OSS: 9 tools** (+Coral) 🎯 **9-TOOL MILESTONE**
- **COMMUNITY-GUIDES-SITE**:
  - Separate guides.coralproject.net for community-building advice
  - **Recipe convention: "community-guides-companion-site positive-signal"**
  - **NEW positive-signal convention** (Coral 1st formally)
- **MONGODB-AGING**:
  - MongoDB is less-common now; licensing (SSPL)
  - **Recipe convention: "MongoDB-SSPL-licensing-awareness neutral-signal"**
  - **NEW neutral-signal convention** (Coral 1st formally)
- **INSTITUTIONAL-STEWARDSHIP**: Coral Project + Vox Media + decade-plus + dogfooded + docs + guides + Twitter. **141st tool — major-newsroom-dogfooded sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + CI + Docker + docs + guides + Twitter + decade-plus. **147th tool in transparent-maintenance family.**
- **COMMENTING-PLATFORM-CATEGORY:**
  - **Coral** — newsroom-focused; moderation-heavy
  - **Commento** — lighter; privacy-focused
  - **Remark42** — Go; minimalist
  - **Isso** — Python; simpler
  - **Giscus** — GitHub Discussions-backed
- **ALTERNATIVES WORTH KNOWING:**
  - **Remark42** — if you want Go + minimalist
  - **Commento** — if you want Disqus-style simple
  - **Giscus** — if you host on GH Pages / Docs
  - **Choose Coral if:** you're a newsroom or need heavy moderation UX.
- **PROJECT HEALTH**: active + decade-plus + Vox-Media-backed + docs + guides. Strong.

## Links

- Repo: <https://github.com/coralproject/talk>
- Website: <https://coralproject.net>
- Docs: <https://docs.coralproject.net>
- Guides: <https://guides.coralproject.net>
- Remark42 (alt): <https://github.com/umputun/remark42>
- Commento (alt): <https://gitlab.com/commento/commento>
