---
name: Formbricks
description: Open-source survey + feedback + experience-management platform. Embed in-product surveys (website, mobile, email, link), NPS/CSAT/CES, conditional logic, actions/triggers, team collaboration. Next.js + Postgres. AGPL-3.0 (self-host) / commercial (Enterprise cloud tier).
---

# Formbricks

Formbricks is the OSS Typeform / Qualtrics / Hotjar-ask-a-question competitor. Build surveys (link-based, website-embedded, in-app on mobile, email), trigger them by user action, segment by user attributes, and collect structured responses with conditional logic. Drag-and-drop survey builder, many question types (multi-choice, NPS, rating, file upload, open-text, CTA).

Positioned as "Customer Experience Platform" — beyond simple form tool: user identities, action triggers, product-led growth surveys.

- Upstream repo: <https://github.com/formbricks/formbricks>
- Website: <https://formbricks.com>
- Docs: <https://formbricks.com/docs>
- Self-hosting: <https://formbricks.com/docs/self-hosting/deployment>
- Cloud (free tier): <https://app.formbricks.com>

## Architecture in one minute

- **`formbricks/formbricks`** — Next.js + Node.js monolith (API + web UI + survey renderer)
- **Postgres 15+** — all state (users, orgs, surveys, responses, attributes, webhooks, API keys)
- **Redis (optional)** — caching + rate limits at scale
- **SMTP (optional)** — for invites, notifications, email surveys

JS snippet embeds in your website/product → talks to your Formbricks API → delivers surveys based on segmentation + triggers. iOS + Android SDKs for native apps.

## Compatible install methods

| Infra       | Runtime                                                     | Notes                                                                 |
| ----------- | ----------------------------------------------------------- | --------------------------------------------------------------------- |
| Single VM   | Docker Compose (upstream-documented)                        | **Recommended**                                                        |
| Single VM   | `one-click-deploy` script for Hetzner / DO / Railway / etc. | Upstream ships a `curl | sh` installer                                 |
| Kubernetes  | Helm chart                                                   | <https://formbricks.com/docs/self-hosting/advanced/kubernetes>         |
| Managed     | Formbricks Cloud                                             | <https://formbricks.com/pricing>                                       |
| PaaS        | Vercel / Render / Railway                                    | Stateless app + external Postgres                                      |

## Inputs to collect

| Input                   | Example                            | Phase     | Notes                                                       |
| ----------------------- | ---------------------------------- | --------- | ----------------------------------------------------------- |
| Public URL              | `https://surveys.example.com`       | DNS       | `WEBAPP_URL` — baked into survey links + embed snippet       |
| `NEXTAUTH_URL`          | same as public URL                 | Auth      | OAuth redirect base                                          |
| `NEXTAUTH_SECRET`       | `openssl rand -hex 32`             | Security  | NextAuth session signing                                     |
| `ENCRYPTION_KEY`        | `openssl rand -hex 32` (32 bytes)  | Security  | **Critical** — encrypts API keys + sensitive survey data     |
| Postgres                | user/pw/db                         | DB        | 15+ recommended                                              |
| `CRON_SECRET`           | `openssl rand -hex 32`             | Security  | For scheduled tasks                                           |
| OAuth (optional)        | Google / GitHub / Azure / custom OIDC | Auth    | Configure via env vars                                       |
| SMTP (optional)         | host/port/user/pw                   | Email     | For invites + email surveys                                  |
| S3 / cloud storage (opt)| bucket / region / keys              | Storage   | For file-upload question responses                           |

## Install via Docker Compose

Upstream publishes install docs at <https://formbricks.com/docs/self-hosting/deployment>. Typical compose:

```yaml
services:
  formbricks:
    image: ghcr.io/formbricks/formbricks:v3.x.x    # pin; check releases
    container_name: formbricks
    restart: unless-stopped
    depends_on:
      postgres: { condition: service_healthy }
    env_file: [.env]
    ports:
      - "3000:3000"
    volumes:
      - uploads:/home/nextjs/apps/web/uploads

  postgres:
    image: postgres:17-alpine
    container_name: formbricks-db
    restart: unless-stopped
    environment:
      POSTGRES_USER: formbricks
      POSTGRES_PASSWORD: <strong>
      POSTGRES_DB: formbricks
    volumes:
      - formbricks-db:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U formbricks"]
      interval: 10s
      retries: 5

volumes:
  formbricks-db:
  uploads:
```

`.env`:

```sh
WEBAPP_URL=https://surveys.example.com
NEXTAUTH_URL=https://surveys.example.com
NEXTAUTH_SECRET=<openssl rand -hex 32>
ENCRYPTION_KEY=<openssl rand -hex 32>
CRON_SECRET=<openssl rand -hex 32>
DATABASE_URL=postgresql://formbricks:<strong>@postgres:5432/formbricks
# Disable public signup after first admin:
SIGNUP_DISABLED=0    # set 1 after creating the first admin
# Optional
MAIL_FROM=surveys@example.com
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USER=...
SMTP_PASSWORD=...
SMTP_SECURE_ENABLED=1
```

## One-click install

```sh
curl -fsSL https://formbricks.com/setup.sh | bash
```

Installs Docker + pulls images + generates `.env` + starts the stack. Fine for quick demos; for prod, review the generated `.env`.

## First boot

1. Browse `https://surveys.example.com`
2. Create your admin account (first-user-is-admin)
3. Set `SIGNUP_DISABLED=1` in `.env` + restart to prevent public signups
4. Create a project → grab the `environmentId` + API host URL for the embed snippet
5. Embed the JS snippet on your site, or use the link surveys via public URLs

## Embedding

Formbricks has three touchpoints:

1. **Website surveys** — drop `<script>` on your site with `environmentId` + API host; segments users client-side
2. **In-app surveys** — for logged-in products; iOS/Android SDKs + JS SDK; triggers by user action/attribute
3. **Link surveys** — standalone URL, no embed needed (like Typeform); best for one-off campaigns

All flow through the same Formbricks backend.

## Data & config layout

- **All state in Postgres**: users, orgs, projects, surveys, responses, attributes, webhooks, actions, API keys, display logs
- **`uploads/`** — file-upload question responses (unless using S3/GCS/Azure)
- **Encryption**: API keys, OAuth secrets, and sensitive response data encrypted at rest with `ENCRYPTION_KEY`

## Backup

```sh
docker compose exec -T postgres pg_dump -U formbricks formbricks | gzip > formbricks-db-$(date +%F).sql.gz
docker run --rm -v uploads:/src -v "$PWD":/backup alpine tar czf /backup/formbricks-uploads-$(date +%F).tgz -C /src .

# Secrets — back up separately, off-host
grep -E '^ENCRYPTION_KEY|^NEXTAUTH_SECRET|^CRON_SECRET' .env > formbricks-secrets-$(date +%F).txt
```

**Losing `ENCRYPTION_KEY` = losing encrypted fields** (API keys, OAuth secrets, encrypted question answers). Back up separately.

## Upgrade

1. Releases: <https://github.com/formbricks/formbricks/releases>. Frequent (~weekly).
2. `docker compose pull && docker compose up -d`. Prisma migrations run on startup.
3. **Always back up DB before major version jumps.**
4. Check release notes — occasional breaking env-var renames.
5. v2 → v3 had a significant migration path (run pre-migration script per release notes).

## Gotchas

- **Encryption key ≥32 bytes (hex-encoded).** Losing it = data loss. First-class backup target.
- **`WEBAPP_URL` is baked into survey links.** Changing it after deploying embed snippets = broken snippets. Choose URL permanently.
- **First-user-is-admin.** Set `SIGNUP_DISABLED=1` after creating your admin. Forgetting this = anyone on the internet can sign up.
- **Rate-limit aware**: default API rate limits per-IP are conservative; bump for heavy survey ingestion.
- **Redis helpful at scale** (>1M responses/month). Small installs can skip.
- **Email is required for full functionality** (invites, magic links, email surveys). Single-user installs can skip SMTP and use the password login.
- **AGPL-3.0** — public SaaS-ification = source-sharing obligation. Internal use = fine.
- **"Enterprise" features on Cloud** include SSO (SAML), audit logs, advanced RBAC, SLA. Self-host is mostly feature-complete but without the SSO/SLA layers.
- **Mobile SDKs** (iOS, Android, React Native, Flutter) — pair with self-hosted backend via `apiHost` config.
- **Webhooks** per-survey fire on response; signature-verified.
- **File uploads** default to local `uploads/` — configure S3/GCS/Azure for prod.
- **GDPR-friendly**: response data stored in your DB, no third-party cookies from Formbricks itself.
- **Actions + triggers**: surveys fire on "user visits page X" / "clicks element Y" / "attribute Z changes" — configure in the UI, executes in the client SDK.
- **Display logic**: per-survey rules (don't show again for 30d, max 1x per session, etc.).
- **Multi-language surveys** native (v3+).
- **Environment separation**: each Formbricks project has dev + prod environments with separate API keys.
- **OSS licensing vs commercial "Enterprise Cloud"** — cloud tier has paid features not available in self-host (SSO, audit, white-label). Core survey feature set is fully in OSS.
- **Alternatives worth knowing:**
  - **Tally** — commercial Typeform clone with generous free tier
  - **Typeform / Qualtrics / SurveyMonkey** — commercial SaaS
  - **LimeSurvey** — OSS, PHP, older UI but battle-tested
  - **OhMyForm / Formily** — earlier OSS attempts, less maintained
  - **Listmonk** — newsletter, overlap on email only
  - **Budibase / Appsmith** — low-code tools with form features
  - **Hotjar / PostHog** — feedback via session replay (different angle)

## Links

- Repo: <https://github.com/formbricks/formbricks>
- Website: <https://formbricks.com>
- Docs: <https://formbricks.com/docs>
- Self-hosting deployment: <https://formbricks.com/docs/self-hosting/deployment>
- Kubernetes: <https://formbricks.com/docs/self-hosting/advanced/kubernetes>
- Environment variables: <https://formbricks.com/docs/self-hosting/advanced/environment-variables>
- Migration guide: <https://formbricks.com/docs/self-hosting/migration-guide>
- Cloud: <https://app.formbricks.com>
- Pricing: <https://formbricks.com/pricing>
- Releases: <https://github.com/formbricks/formbricks/releases>
- Docker image: <https://github.com/formbricks/formbricks/pkgs/container/formbricks>
- Discord: <https://formbricks.com/discord>
