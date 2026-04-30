---
name: Typebot
description: "Visual chatbot builder — drag-and-drop 34+ building blocks (text, buttons, conditions, webhooks, OpenAI) to create conversational flows. Embed as container/popup/bubble on any site. Fair-Source (FSL) license — NOT OSI-approved open source."
---

# Typebot

Typebot is a visual chatbot builder: drag blocks onto a canvas to design a conversation (ask name → email → show options → branch → call an API → save to Google Sheets). Then embed the bot on your website as an inline container, popup, or chat bubble. Great for forms, lead capture, customer onboarding, quizzes, and AI-enhanced conversations.

What makes Typebot stand out:

- **Visual flow builder** — no-code for makers; still lets developers drop in JS
- **34+ block types**:
  - **Bubbles**: text, image/GIF, video, audio, embed
  - **Inputs**: text, email, phone, buttons, picture choice, date, payment (Stripe), file upload
  - **Logic**: conditional branching, URL redirects, JS scripting, A/B testing
  - **Integrations**: Webhook/HTTP, OpenAI, Google Sheets/Analytics, Meta Pixel, Zapier, Make, Chatwoot
- **Embed anywhere** — custom JS lib (no iframe; zero perf impact), popups, bubbles, full-page
- **Custom domain** — `chat.example.com` per bot
- **Advanced theming** — fonts, colors, shadows + custom CSS
- **Results + analytics** — drop-off rates, completion rates, CSV export
- **REST API** — execute bots via HTTP

**License caveat (critical)**: Typebot uses the **Fair Source License** (Functional Source License). This is NOT OSI-approved open source — it's source-available with restrictions. Confirm before deploying for business use.

- Upstream repo: <https://github.com/baptisteArno/typebot.io>
- Website: <https://typebot.io>
- Docs: <https://docs.typebot.io>
- Hosted SaaS: <https://app.typebot.io>
- Self-hosting docs: <https://docs.typebot.io/self-hosting/get-started>
- Docker Hub (builder): <https://hub.docker.com/r/baptistearno/typebot-builder>
- Docker Hub (viewer): <https://hub.docker.com/r/baptistearno/typebot-viewer>
- License terms: <https://docs.typebot.io/self-hosting#license-requirements>

## Architecture in one minute

Typebot is a **two-app** system:

- **Builder** — the admin UI where you design bots; Next.js; visible to you only
- **Viewer** — the public runtime where visitors chat with your bot; Next.js; very lightweight
- **PostgreSQL** — stores bots, results, users
- **Optional**: Redis, S3-compatible storage for file uploads

The split lets you put the Viewer on a CDN/edge and keep the Builder behind auth/VPN.

## Compatible install methods

| Infra       | Runtime                                          | Notes                                                            |
| ----------- | ------------------------------------------------ | ---------------------------------------------------------------- |
| Single VM   | Docker Compose (builder + viewer + postgres + minio) | **Most common** — upstream provides compose                     |
| Kubernetes  | Community manifests                                  | Stateless apps + Postgres                                            |
| Managed     | Hosted <https://app.typebot.io>                        | Paid plans; fair-source means revenue supports upstream                      |

## Inputs to collect

| Input                       | Example                                | Phase     | Notes                                                       |
| --------------------------- | -------------------------------------- | --------- | ----------------------------------------------------------- |
| `NEXTAUTH_URL`              | `https://builder.typebot.example.com`  | URL       | Builder auth callback                                          |
| `NEXT_PUBLIC_VIEWER_URL`    | `https://chat.typebot.example.com`      | URL       | Where embedded bots run; CORS target                               |
| `DATABASE_URL`              | `postgres://...`                         | DB        | Postgres required                                                   |
| `ENCRYPTION_SECRET`         | `openssl rand -hex 32`                   | Security  | Encrypts integration credentials in DB; losing = re-enter all creds      |
| `NEXTAUTH_SECRET`           | `openssl rand -hex 32`                   | Security  | Builder session signing                                                        |
| SMTP creds                  | host + port + user + pass                 | Email     | Required for admin sign-in emails (magic link)                                       |
| S3 creds                    | MinIO or AWS S3                           | Storage   | For file-upload blocks; local MinIO is typical                                          |
| `ADMIN_EMAIL`               | first admin email                         | Bootstrap | First user matching this email becomes admin                                                 |
| Social auth                 | Google/GitHub OAuth                       | Auth      | Optional; replaces magic-link                                                                    |

## Install via Docker Compose

Upstream provides a ready compose at <https://github.com/baptisteArno/typebot.io/tree/main/self-hosting>. Minimal sketch:

```yaml
services:
  typebot-db:
    image: postgres:17-alpine
    container_name: typebot-db
    restart: unless-stopped
    environment:
      POSTGRES_DB: typebot
      POSTGRES_USER: typebot
      POSTGRES_PASSWORD: <strong>
    volumes:
      - typebot-pg:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U typebot"]
      interval: 10s

  typebot-builder:
    image: baptistearno/typebot-builder:latest   # pin to version in prod
    container_name: typebot-builder
    restart: unless-stopped
    depends_on:
      typebot-db: { condition: service_healthy }
    ports:
      - "8080:3000"
    environment:
      DATABASE_URL: postgresql://typebot:<strong>@typebot-db:5432/typebot
      ENCRYPTION_SECRET: <openssl rand -hex 32>
      NEXTAUTH_URL: https://builder.typebot.example.com
      NEXT_PUBLIC_VIEWER_URL: https://chat.typebot.example.com
      ADMIN_EMAIL: admin@example.com
      # SMTP for magic-link auth
      SMTP_HOST: smtp.example.com
      SMTP_USERNAME: admin@example.com
      SMTP_PASSWORD: <smtp-pass>
      SMTP_FROM: Typebot <noreply@example.com>
      # Social auth (optional)
      # GITHUB_CLIENT_ID: ...
      # GITHUB_CLIENT_SECRET: ...

  typebot-viewer:
    image: baptistearno/typebot-viewer:latest
    container_name: typebot-viewer
    restart: unless-stopped
    depends_on:
      typebot-db: { condition: service_healthy }
    ports:
      - "8081:3000"
    environment:
      DATABASE_URL: postgresql://typebot:<strong>@typebot-db:5432/typebot
      ENCRYPTION_SECRET: <SAME as builder>
      NEXTAUTH_URL: https://builder.typebot.example.com
      NEXT_PUBLIC_VIEWER_URL: https://chat.typebot.example.com
      NEXT_PUBLIC_SMTP_FROM: Typebot <noreply@example.com>

  # File uploads
  minio:
    image: minio/minio:latest
    container_name: typebot-minio
    restart: unless-stopped
    command: server /data --console-address ":9001"
    environment:
      MINIO_ROOT_USER: minio
      MINIO_ROOT_PASSWORD: <strong>
    volumes:
      - typebot-minio:/data

volumes:
  typebot-pg:
  typebot-minio:
```

Front builder at `builder.typebot.example.com`, viewer at `chat.typebot.example.com` (two separate subdomains).

## First use

1. Browse builder → enter your admin email → magic link sent via SMTP
2. Create workspace → create bot → drag blocks
3. Publish → get embed snippet (script tag or iframe variant)
4. Paste snippet into your website → visitors see chat bubble
5. Results appear in builder's Results tab; export to CSV

## Embedding

Typebot's JS lib is lightweight (no iframe):

```html
<script type="module">
  import Typebot from 'https://chat.typebot.example.com/embed.js'
  Typebot.initBubble({
    typebot: 'my-bot',
    theme: { button: { backgroundColor: '#0042DA' } },
    prefilledVariables: { email: 'user@example.com' }
  })
</script>
```

Container / popup variants in docs.

## Data & config layout

- Postgres — bots, workspaces, users, results
- MinIO / S3 — uploaded files from visitors
- Encrypted at rest in Postgres: integration credentials (Google, Stripe, OpenAI keys) using `ENCRYPTION_SECRET`

## Backup

```sh
# DB
docker compose exec -T typebot-db pg_dump -U typebot typebot | gzip > typebot-db-$(date +%F).sql.gz

# MinIO (file uploads)
docker run --rm -v typebot-minio:/src -v "$PWD":/backup alpine \
  tar czf /backup/typebot-minio-$(date +%F).tgz -C /src .

# ENCRYPTION_SECRET - BACK UP SEPARATELY
# losing it = can't decrypt integration credentials in DB
```

## Upgrade

1. Releases: <https://github.com/baptisteArno/typebot.io/releases>. Active.
2. `docker compose pull` (both builder + viewer images) → `docker compose up -d`.
3. Prisma migrations run on startup; back up DB first.
4. Keep builder + viewer on the **same version** — they share Prisma schema.

## Gotchas

- **License is Fair Source / Functional Source License — NOT OSS.** The FSL restricts competing hosted offerings against Typebot's commercial SaaS. Self-hosting for your own use is fine; offering Typebot-as-a-service to others is restricted. **Read the license** before commercial use. Details: <https://docs.typebot.io/self-hosting#license-requirements>.
- **Two separate subdomains required**: builder (internal/team) and viewer (public). Don't try to path-mount them on the same domain — CORS + Next.js basePath complexity.
- **`ENCRYPTION_SECRET` must match builder + viewer** — they share it to decrypt integration credentials. Back it up; losing = re-enter all OpenAI keys, Stripe keys, etc.
- **`NEXT_PUBLIC_*` vars are baked at build time**. If you change `NEXT_PUBLIC_VIEWER_URL`, you must rebuild the Docker image OR use the env-substitution approach upstream recommends. Check release notes.
- **Magic-link sign-in needs working SMTP** — without it, nobody can log into the builder. Test SMTP before going live.
- **Admin bootstrap** — the email in `ADMIN_EMAIL` is granted admin role on first login. Don't rely on arbitrary first-user becoming admin.
- **OpenAI block** sends user input to OpenAI — don't use in GDPR-sensitive / high-security flows without awareness.
- **`Stripe payment` block** requires TLS on viewer domain + Stripe account — test-mode first.
- **Embed script is served from viewer subdomain** — if you CDN the viewer, invalidate cache on bot publish.
- **Results retention** — stored in Postgres forever unless you prune. For GDPR compliance, set up deletion policies (builder UI has per-bot retention).
- **No built-in A/B conversion tracking** — use Meta Pixel / GA integrations.
- **Multi-language bots** — supported via conditional blocks + variables; not a first-class feature.
- **Export bot as JSON** — for version control or migration; no git-sync built in.
- **Webhook block** is the escape hatch — anything not built in can be a webhook to your own server.
- **Database resource usage** grows with bot runs (each run = a row in `result` + rows in `answer`). For high-traffic bots, plan DB storage.
- **No self-host for enterprise SSO** — OIDC/SAML are managed-tier features; self-host has magic-link + OAuth (Google/GitHub) built in.
- **Alternatives worth knowing:**
  - **Botpress** — OSS chatbot platform (MIT); more traditional conversational AI
  - **Rasa** — Python; ML-based NLU; enterprise-grade; more complex
  - **Landbot** — SaaS competitor; no self-host
  - **ManyChat / Chatfuel** — marketing chatbot SaaS
  - **Chatwoot** — customer support platform (integrates with Typebot) (separate recipe)
  - **Tock** — French-govt-backed OSS chatbot framework
  - **Voiceflow / Botkit** — other builders
  - **Open-source form builders** (if you mostly want multi-step forms): Formbricks, Tally, SurveyJS, Formkit — simpler fit
  - **Choose Typebot if:** you want a slick visual builder + self-hosted + OK with Fair-Source licensing.
  - **Choose Botpress if:** you want a pure-OSS chatbot platform.
  - **Choose Formbricks if:** you primarily want forms/surveys, not conversational chatbots.

## Links

- Repo: <https://github.com/baptisteArno/typebot.io>
- Website: <https://typebot.io>
- Docs: <https://docs.typebot.io>
- Self-hosting guide: <https://docs.typebot.io/self-hosting/get-started>
- Docker self-host docs: <https://docs.typebot.io/self-hosting/guides/docker>
- License details: <https://docs.typebot.io/self-hosting#license-requirements>
- Hosted SaaS: <https://app.typebot.io>
- Builder Docker image: <https://hub.docker.com/r/baptistearno/typebot-builder>
- Viewer Docker image: <https://hub.docker.com/r/baptistearno/typebot-viewer>
- Releases: <https://github.com/baptisteArno/typebot.io/releases>
- Discord: <https://typebot.io/discord>
- Status: <https://status.typebot.io>
- Author: <https://twitter.com/baptisteArno>
- Fair Source License info: <https://fair.io> / <https://fsl.software>
