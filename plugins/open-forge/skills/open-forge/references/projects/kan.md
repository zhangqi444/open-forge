---
name: Kan
description: "Open-source Trello alternative — kanban boards + workspace members + Trello import + labels/filters + comments + activity log + templates. Next.js + tRPC + Better Auth + Postgres + Drizzle. AGPL-3.0."
---

# Kan

Kan is **"the open-source Trello"** — a modern kanban project-management app for teams. Visibility-controlled boards, workspace members, Trello imports (migrate from real Trello), labels + filters, card comments, activity log, board templates. **Next.js + tRPC + Better Auth + Drizzle ORM + Postgres** stack — modern, maintainable, and fast.

Developed by **Henry Barreto (kanbn)**; growing community; AGPL-3.0 licensed; **official Railway partnership** for one-click deployment (revenue supports the project).

Features (per upstream):

- **Board visibility control** — public / workspace-only / private
- **Workspace members** — invite + collaborate
- **Trello imports** — one-click migration
- **Labels + filters** — organize large boards
- **Comments on cards** — team discussion
- **Activity log** — full audit trail of card changes
- **Board templates** — reuse common board structures
- **Custom white-labeling** (self-host)
- **Integrations (roadmap)** — upcoming
- **OIDC/SSO** — Google, Discord, GitHub, generic OIDC
- **File uploads** via S3-compatible storage
- **Email via SMTP** (sign-in emails, notifications)

- Upstream repo: <https://github.com/kanbn/kan>
- Homepage + managed: <https://kan.bn>
- Docs: <https://docs.kan.bn>
- Roadmap: <https://kan.bn/kan/roadmap>
- Railway deploy: <https://railway.com/deploy/kan>
- Discord: <https://discord.gg/e6ejRb6CmT>
- Contact: henry@kan.bn

## Architecture in one minute

- **Next.js** web app + **tRPC** API
- **Better Auth** for auth (supports email/password + OAuth + OIDC)
- **Drizzle ORM** → **Postgres**
- **Redis** (optional, for rate-limiting)
- **S3-compatible** object storage for file uploads (avatars + attachments)
- **SMTP** for emails
- **Resource**: modest — Next.js app + Postgres; scales horizontally

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Single VM          | **Docker Compose**                                                  | **Upstream-recommended**                                                           |
| Managed (hosted)   | **Kan.bn** (upstream SaaS) — commercial                                     | Directly funds upstream                                                                    |
| Railway            | **One-click deploy** (official partnership)                                           | Easiest cloud path; supports project                                                                        |
| Kubernetes         | Community manifests                                                                   | Works                                                                                                 |
| Bare-metal         | Node 20+ + Postgres + Redis + S3/R2                                                               | DIY stack                                                                                                 |

## Inputs to collect

| Input                        | Example                                                    | Phase        | Notes                                                                    |
| ---------------------------- | ---------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain                       | `kan.example.com`                                              | URL          | TLS via reverse proxy                                                            |
| Postgres                     | `postgres://user:pass@host:5432/kan`                                     | DB           | Managed or bundled                                                                       |
| Redis (opt)                  | `redis://...`                                                                     | Cache        | For rate limiting                                                                                     |
| `NEXT_PUBLIC_BASE_URL`       | `https://kan.example.com`                                                           | URL          | Must match domain — impacts auth callbacks                                                                        |
| `BETTER_AUTH_SECRET`         | 32+ char random string                                                                             | Secret       | **Immutable** — rotation invalidates all sessions/credentials                                                                                         |
| SMTP                         | `smtp.resend.com` / `smtp.sendgrid.net` / SES                                                                | Email        | Required for email-based auth + invitations                                                                                          |
| `EMAIL_FROM`                 | `"Kan <hello@mail.example.com>"`                                                                                       | Email        | Must be verified sender                                                                                                                        |
| OAuth providers (opt)        | Google / Discord / GitHub / generic OIDC                                                                                  | Auth         | Multiple concurrent providers OK                                                                                                                                     |
| S3 storage (for uploads)     | Cloudflare R2 / AWS S3 / MinIO / Backblaze B2                                                                                             | Storage      | `S3_ENDPOINT` + keys; separate buckets for avatars + attachments                                                                                                                                                    |
| `KAN_ADMIN_API_KEY`          | random string                                                                                                                                         | Admin        | For stats/admin endpoints                                                                                                                                                                            |

## Install via Docker Compose

Follow upstream compose. Core services:

```yaml
services:
  migrate:
    image: ghcr.io/kanbn/kan-migrate:latest       # pin specific version in prod
    environment:
      - POSTGRES_URL=${POSTGRES_URL}
    depends_on:
      postgres:
        condition: service_healthy
    restart: "no"

  web:
    image: ghcr.io/kanbn/kan:latest                # pin specific version in prod
    ports:
      - "3000:3000"
    env_file: .env
    depends_on:
      migrate:
        condition: service_completed_successfully
    restart: unless-stopped

  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: kan_db
      POSTGRES_USER: kan
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - kan_postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U kan -d kan_db"]
```

Migrate container runs first; web starts after. Browse `http://<host>:3000/`.

## First boot

1. Sign up → first account becomes admin
2. Create workspace; invite members
3. Configure OAuth if wanted (before many users sign up)
4. Create first board; test real-time updates across two browsers
5. Trello import: provide `TRELLO_APP_API_KEY` + `TRELLO_APP_API_SECRET`; import existing Trello board
6. Configure attachments (S3-compat) + test upload
7. Put behind TLS reverse proxy
8. Set `NEXT_PUBLIC_DISABLE_SIGN_UP=true` once your team is in (close open registration)

## Data & config layout

- Postgres — boards, cards, members, activity log, auth
- S3 — avatars + attachments (separate buckets)
- Redis — rate-limit counters
- Email — transient (SMTP side)

## Backup

```sh
pg_dump -Fc -U kan kan_db > kan-$(date +%F).dump
# S3 buckets: cloud-side lifecycle + versioning
```

Redis = ephemeral.

## Upgrade

1. Releases: <https://github.com/kanbn/kan/releases>. Active — frequent releases.
2. Bump tag on `kan` + `kan-migrate` images → restart → migrate container runs schema migrations.
3. **Back up Postgres before version bumps.**
4. Review release notes for schema-incompatible changes.

## Gotchas

- **`BETTER_AUTH_SECRET` rotation = logout everyone.** Like every JWT/session secret — set once, back it up, NEVER rotate in prod unless you're OK with all sessions dying. Same immutability class as Rallly SECRET_KEY (batch 75), Colanode JWT (this batch), Kener SECRET_KEY (batch 75).
- **`NEXT_PUBLIC_BASE_URL` must match actual public URL** — auth callbacks + email links derived from it. Change URL = update env + reconfigure OAuth clients.
- **Close open signup after rollout**: `NEXT_PUBLIC_DISABLE_SIGN_UP=true` — otherwise anyone on the internet can register on your Kan instance.
- **Email delivery = magic-link auth prerequisite.** Better Auth uses email for password-reset + magic-link. Email misconfigured = users locked out. Test SMTP before going live. Transactional email provider (Resend/SendGrid/SES/Postmark) strongly preferred over home SMTP.
- **S3 bucket policy = public read for avatars, private for attachments.** Attachments are user data; don't leak via public bucket. Avatars typically public for UI convenience. Two separate buckets recommended (upstream supports via separate env vars).
- **Railway one-click partnership**: deploying via Railway template generates referral code that supports upstream. Same sustainability-signal as Elestio for MediaCMS (batch 76), Write.as for WriteFreely (batch 74), rallly.co (batch 75).
- **Trello migration** requires Trello API key + secret. Trello's OAuth flow is specific; follow Kan docs exactly. Import is one-way + one-time typically.
- **Realtime**: card updates need to propagate. Ensure reverse proxy doesn't buffer/kill long-poll or WebSocket connections. Test multi-browser concurrent editing.
- **Rate limiting** (Redis): if Redis unreachable → rate-limiting may silently-degrade to no-limit. Consider alerting on Redis connection loss.
- **White-labeling**: `NEXT_PUBLIC_WHITE_LABEL_HIDE_POWERED_BY=true` removes "Powered by kan.bn". Ethical note: if you commercially deploy for clients, consider supporting upstream via Sponsors/Pro even when hiding branding.
- **AGPL-3.0 = public-hosting obligation.** If you offer Kan-as-a-service commercially, AGPL §13 requires source disclosure of any modifications. For internal workspace use, AGPL is identical to GPL (no extra obligation beyond modifying + distributing). Same pattern as WriteFreely/Zoraxy/Rallly (batch 74-75).
- **Growing project — bus factor watch**: Henry Barreto-led + growing community; Railway partnership + managed tier provide commercial sustainability. Healthy trajectory; not bus-factor-1 in severity.
- **Feature gap vs Trello**: Trello has more integrations + power-ups; Kan is actively adding features per roadmap. For basic kanban needs Kan is already ahead; for heavy-integration workflows check current feature parity.
- **Alternatives worth knowing:**
  - **Wekan** — older OSS Trello-alt; Meteor/Node; less active
  - **Planka** — Trello-like; React + Node; active
  - **Focalboard** — Mattermost-owned Trello-alt (commercially wind-down uncertain)
  - **Vikunja** — Go-based; kanban + list + Gantt
  - **Kanboard** — PHP; simple, stable, been around
  - **Restyaboard** — PHP commercial-with-OSS
  - **Choose Kan if:** modern Next.js stack + active dev + OAuth-ready + Trello-importable.
  - **Choose Wekan/Planka if:** you want an older/simpler alternative.
  - **Choose Vikunja if:** you want Gantt + other views beyond kanban.

## Links

- Repo: <https://github.com/kanbn/kan>
- Homepage: <https://kan.bn>
- Docs: <https://docs.kan.bn>
- Roadmap: <https://kan.bn/kan/roadmap>
- Discord: <https://discord.gg/e6ejRb6CmT>
- Releases: <https://github.com/kanbn/kan/releases>
- Railway template (official partnership): <https://railway.com/deploy/kan>
- Docker image: <https://ghcr.io/kanbn/kan>
- Migrate image: <https://ghcr.io/kanbn/kan-migrate>
- Better Auth: <https://better-auth.com>
- Planka (alt): <https://planka.app>
- Wekan (alt): <https://wekan.github.io>
- Vikunja (alt): <https://vikunja.io>
- Kanboard (alt): <https://kanboard.org>
