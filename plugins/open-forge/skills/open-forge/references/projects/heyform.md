---
name: HeyForm
description: "Open-source form builder for surveys, questionnaires, quizzes, and polls. Conversational Typeform-style UX, logic/branching, 20+ input types, webhooks, Zapier/Make integrations, visual theming, analytics, CSV export. Node + React + MongoDB. AGPL-3.0."
---

# HeyForm

HeyForm is an **open-source conversational form builder** — the self-hosted answer to Typeform, Jotform, Google Forms, Tally, and friends. Build surveys, quizzes, polls, lead-gen forms, and questionnaires with drag-and-drop ease; embed them on sites; collect responses with analytics. Conversational UX means forms show one question at a time (Typeform-style) rather than a wall of inputs.

Features:

- **20+ input types** — short text, long text, email, phone, number, select, multi-select, picture choice, rating, scale, date picker, file upload, signature, address, matrix, country, ranking
- **Logic + branching** — show/hide questions based on prior answers; URL redirect; calculator logic
- **Visual themes** — fonts, colors, backgrounds, custom CSS
- **Embed** — JS embed snippet (modal / inline / popup), shareable link, QR code
- **Integrations** — webhooks, Google Sheets, Zapier, Make.com, Slack, Discord, Notion, Airtable, Mailchimp, marketing platforms
- **Analytics** — completion rate, drop-off per question, conversion funnel, device breakdown, geolocation
- **Multi-user** workspaces + team invites
- **CSV + JSON export** of responses
- **Payment collection** (Stripe)
- **Multi-language** forms
- **Custom domain** support
- **API** for external integrations

- Upstream repo: <https://github.com/heyform/heyform>
- Website: <https://heyform.net>
- Hosted: <https://my.heyform.net> (managed; free + paid tiers)
- Docs: <https://docs.heyform.net>

## Architecture in one minute

- **Server**: Node.js + NestJS + MongoDB (primary DB)
- **Webapp**: React + Vite
- **Embed library**: tiny JS bundle
- **Pnpm workspace** — monorepo with `server`, `webapp`, `embed`, shared utilities
- **Storage**: MongoDB (form definitions, responses) + S3/local (file uploads) + optional Redis
- **Reverse proxy** required for TLS

## Compatible install methods

| Infra       | Runtime                                                  | Notes                                                           |
| ----------- | -------------------------------------------------------- | --------------------------------------------------------------- |
| Single VM   | **Docker Compose**                                         | **The way** — upstream-documented                                   |
| One-click   | Railway / Zeabur / Sealos / RepoCloud / Alibaba ComputeNest | Official templates                                                      |
| Managed     | HeyForm Cloud (`my.heyform.net`)                                  | Easiest; supports project                                                       |
| Kubernetes  | Community Helm (no official yet)                                     | DIY                                                                                 |

## Inputs to collect

| Input             | Example                         | Phase     | Notes                                                           |
| ----------------- | ------------------------------- | --------- | --------------------------------------------------------------- |
| Domain            | `forms.example.com`               | URL       | For form landing URLs + embed                                          |
| MongoDB           | `mongodb://user:pass@db/heyform`    | DB        | v4.4+; Atlas works too                                                         |
| Redis             | optional                                | Cache     | Speeds auth + rate limiting                                                              |
| Admin user        | via env or first-run                      | Bootstrap | Email + password                                                                                  |
| File storage      | local disk / S3 / R2                        | Uploads   | For file-upload inputs                                                                                      |
| Email (SMTP)      | host + port + creds                           | Email     | Notifications on new submissions + password reset                                                                     |
| Payment (opt)     | Stripe keys                                     | Billing   | For payment-collection forms                                                                                                   |
| Webhook URLs      | from integrated tools                              | Integrations | Zapier, Slack, custom                                                                                                          |

## Install via Docker Compose

Upstream provides an official compose file. Outline:

```yaml
services:
  heyform:
    image: heyform/community-edition:latest   # pin specific version tag in prod
    container_name: heyform
    restart: unless-stopped
    depends_on:
      mongo: { condition: service_healthy }
    ports:
      - "9513:9513"
    environment:
      APP_HOMEPAGE_URL: https://forms.example.com
      MONGO_URI: mongodb://mongo:27017/heyform
      SESSION_KEY: <random-32-chars>
      FORM_ENCRYPTION_KEY: <random-32-chars>
      # Optional:
      # REDIS_URL: redis://redis:6379
      # SMTP_HOST: smtp.example.com
      # SMTP_PORT: 587
      # SMTP_USER: user
      # SMTP_PASSWORD: <strong>
      # STORAGE_DRIVER: s3
      # AWS_S3_BUCKET: heyform-uploads
      # AWS_S3_REGION: us-east-1
      # AWS_S3_ACCESS_KEY_ID: ...
      # AWS_S3_SECRET_ACCESS_KEY: ...
    volumes:
      - heyform-data:/data

  mongo:
    image: mongo:6
    container_name: heyform-mongo
    restart: unless-stopped
    volumes:
      - heyform-mongo:/data/db
    healthcheck:
      test: ["CMD-SHELL", "echo 'db.runCommand({ping: 1})' | mongosh --quiet"]
      interval: 10s

volumes:
  heyform-data:
  heyform-mongo:
```

Front with Caddy / nginx + TLS. Browse `https://forms.example.com` → sign up.

## First boot

1. Register first account (becomes admin)
2. Create a workspace → invite team members
3. "New form" → pick blank or template → add questions → save
4. Design tab → customize theme (colors, fonts, background)
5. Logic tab → add branching (if Q1 = "yes", jump to Q5)
6. Share tab → copy link, or embed JS snippet
7. Integrations → connect Zapier, Slack, webhooks
8. Responses tab → view + export CSV

## Embedding

**Inline**:

```html
<div data-heyform-id="YOUR_FORM_ID"></div>
<script src="https://forms.example.com/embed.js"></script>
```

**Popup / modal / chat bubble** — variants documented at <https://docs.heyform.net/embed-form>.

## Data & config layout

- MongoDB — all forms, responses, users, workspaces, integrations
- `data/` — file uploads (if local storage; S3 recommended for production)
- Environment config — all runtime settings

## Backup

```sh
# MongoDB (CRITICAL — all forms + responses)
docker exec heyform-mongo mongodump --archive --gzip > heyform-$(date +%F).mongo.gz

# File uploads (if local)
docker run --rm -v heyform_heyform-data:/src -v "$(pwd):/backup" alpine \
  tar czf /backup/heyform-files-$(date +%F).tgz -C /src .
```

Treat form responses like customer data — back up daily, offsite.

## Upgrade

1. Releases: <https://github.com/heyform/heyform/releases>. Active.
2. Docker: pin current version → `docker compose pull && docker compose up -d`.
3. **Back up MongoDB first** — schema migrations happen.
4. Read CHANGELOG for breaking env-var or schema changes.

## Gotchas

- **MongoDB, not Postgres** — check compat if your infra team prefers Postgres. No Postgres support currently; rewrite would be significant.
- **Form responses are PII** — names, emails, potentially sensitive free-text answers. GDPR implications: consent on forms + right-to-delete flow for EU respondents. HeyForm has basic export + delete, but you need to operationalize it.
- **Spam is real** — public forms attract bots. Enable HeyForm's built-in reCAPTCHA/hCaptcha in Settings per form. Without it, expect 100s of junk submissions/day if the form is linked from anywhere searchable.
- **File upload input** — if enabled, quotas + antivirus (upstream does basic file-type filtering only). Malicious uploads possible; isolate storage.
- **Logic complexity** — HeyForm's logic is good for linear branching + URL redirects. It's not Typeform-grade power-user for very complex surveys (no calculation-heavy quizzes with weighted scoring like Typeform's). Fine for 95% of use cases.
- **Embed cross-origin**: JS embed works from any domain; CORS handled. Reverse proxy must allow cross-origin requests to the embed endpoint.
- **Session key + encryption key** — set them to strong random strings in env; rotating invalidates all sessions + breaks encrypted form answers.
- **HeyForm Cloud** is upstream's hosted offering (free tier + paid); supports the project financially. For low-volume users, cloud is often cheaper than self-hosting ops.
- **Analytics stack** — HeyForm's built-in analytics covers completion/drop-off; no integration with Plausible / PostHog / GA built in, but webhook + Zapier lets you forward events.
- **Custom domain per form** — not supported in community edition as of writing; all forms live at `forms.example.com/<form-id>`.
- **Payment forms** — Stripe integration for collecting payment as part of form flow. Subscribes + refunds are limited; don't build a full storefront.
- **Multi-language forms** — each form can have translated versions; users see their locale.
- **Data residency** — self-hosting = you control where data lives. HeyForm Cloud: check their terms for region options.
- **PDF export of responses** — currently via CSV export + external tools. No one-click PDF.
- **Team/workspace pricing** — the open-source community edition doesn't have feature flags; the hosted cloud has tiered plans. Community = everything.
- **AGPL-3.0** — strong copyleft; deploying a modified version = publish source.
- **Trendshift-featured** — rapid growth; check release notes regularly.
- **Founders are "the passionate duo"** — small-team project; prioritize community-contributed docs + be patient with feature requests.
- **Alternatives worth knowing:**
  - **Formbricks** — open-source "survey infrastructure"; React; similar space, different focus (product surveys, NPS, CSAT) (separate recipe likely)
  - **Typeform / Jotform / Tally / SurveyMonkey** — SaaS giants
  - **Google Forms / Microsoft Forms** — free SaaS
  - **LimeSurvey** — PHP; academic / research-grade; complex forms; older UI
  - **FormTools** — PHP; older
  - **Orbeon Forms** — Java; enterprise XForms
  - **OhMyForm** — self-hosted form builder; less active
  - **YouForm** / **EasyForms** — smaller OSS projects
  - **Choose HeyForm if:** you want a slick Typeform-like builder + self-hosted + active development.
  - **Choose Formbricks if:** you focus on product-embedded surveys (NPS / feedback in-app).
  - **Choose LimeSurvey if:** you need academic-grade complex questionnaires.

## Links

- Repo: <https://github.com/heyform/heyform>
- Website: <https://heyform.net>
- Hosted: <https://my.heyform.net>
- Docs: <https://docs.heyform.net>
- Self-hosting: <https://docs.heyform.net/open-source/self-hosting>
- Blog: <https://heyform.net/blog>
- Twitter: <https://twitter.com/HeyformHQ>
- Releases: <https://github.com/heyform/heyform/releases>
- Docker Hub: <https://hub.docker.com/r/heyform/community-edition>
- Railway template: <https://railway.app/template/f5vBKm>
- Zeabur template: <https://zeabur.com/templates/9YAUUO>
- Embed docs: <https://docs.heyform.net/open-source/embed-form>
