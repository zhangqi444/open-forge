---
name: Fider
description: "Open-source customer feedback + feature-request portal — self-hosted alternative to Canny / UserVoice / ProductBoard. Users post ideas, upvote, comment; team tracks + prioritizes. Go + Postgres. AGPL-3.0."
---

# Fider

Fider is **"the self-hosted feedback portal"** — a purpose-built web app for collecting customer feature requests and product feedback. Users submit ideas, other users upvote + comment, the team tracks status (Planned / Started / Completed / Declined), everyone stays in the loop. Replaces **Canny / UserVoice / ProductBoard / Nolt / FeatureUpvote** with a tool you own.

Built + maintained by **getfider** (Brazil-founded, now owned by TryGhost — the Ghost blogging-platform company acquired Fider in 2024). Fider Cloud is the managed SaaS; self-hosted is AGPL-3.0 + free forever. Commercial-tier-funds-upstream pattern: **Fider Cloud subscription revenue funds the project** under TryGhost's non-profit Ghost Foundation stewardship.

Features:

- **Post ideas** + vote + comment
- **Status tracking**: Planned, Started, Completed, Declined (with reason)
- **Tags + filters + search**
- **Private instances** (login-walled) or public boards
- **Multiple tenants** (Fider Cloud) or single-tenant (self-host)
- **Email notifications** on subscribed posts
- **Admin moderation** — merge duplicates, remove spam
- **OAuth login** + email-based
- **Custom domain** + branding
- **API** + webhooks
- **GDPR tools** (data export, delete)

- Upstream repo: <https://github.com/getfider/fider>
- Homepage: <https://fider.io>
- Docs: <https://docs.fider.io>
- Self-hosted docs: <https://docs.fider.io/self-hosted/>
- Fider Cloud (managed): <https://fider.io/#get-started>
- Demo: <https://demo.fider.io>
- Feedback board: <https://feedback.fider.io>
- OpenCollective (donations): <https://opencollective.com/fider>
- Docker Hub: <https://hub.docker.com/r/getfider/fider>

## Architecture in one minute

- **Go** backend + **React** frontend
- **PostgreSQL** — only supported DB
- **Resource**: tiny — 50-200 MB RAM
- **SMTP** for email notifications (built-in email is a hard requirement for meaningful UX)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Docker             | `getfider/fider` + Postgres                                | **Upstream-primary**                                                               |
| Docker Compose     | Official compose in docs                                                    | Bundled PG + Fider                                                                         |
| Kubernetes         | Community Helm charts                                                                | Works                                                                                                  |
| Bare-metal         | Go binary + systemd                                                                              | Simple; supported                                                                                                    |
| Fider Cloud        | Managed SaaS <https://fider.io>                                                                                 | Funds upstream                                                                                                                |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `feedback.example.com`                                          | URL          | TLS required                                                                             |
| `HOST_DOMAIN`        | same as above                                                           | Config       | Tells Fider its own URL                                                                          |
| PostgreSQL           | PG 10+                                                                 | DB           | External Postgres recommended for production                                                                    |
| SMTP                 | Host, port, user, pass                                                      | Email        | **Required for useful UX** — password reset, notifications all need email                                                                  |
| `JWT_SECRET`         | random 32+ chars                                                                    | Secret       | Immutability class — rotating invalidates all sessions                                                                                 |
| `EMAIL_NOREPLY`      | `noreply@example.com`                                                                            | Email        | From-address for outgoing mail                                                                                                      |
| OAuth providers (opt)| GitHub / Google / Facebook / Microsoft + custom OAuth2                                                          | SSO          | Fider has first-class OAuth                                                                                                                |

## Install via Docker Compose

```yaml
services:
  fider:
    image: getfider/fider:stable                    # or pin a version tag
    restart: always
    ports: ["3000:3000"]
    environment:
      BASE_URL: https://feedback.example.com
      DATABASE_URL: postgres://user:pass@db:5432/fider?sslmode=disable
      JWT_SECRET: ${JWT_SECRET}
      EMAIL_NOREPLY: noreply@example.com
      EMAIL_SMTP_HOST: smtp.example.com
      EMAIL_SMTP_PORT: 587
      EMAIL_SMTP_USER: ${SMTP_USER}
      EMAIL_SMTP_PASSWORD: ${SMTP_PASSWORD}
    depends_on: [db]
  db:
    image: postgres:15
    environment:
      POSTGRES_USER: fider
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: fider
    volumes: [pg_data:/var/lib/postgresql/data]

volumes:
  pg_data:
```

## First boot

1. Deploy with all required env vars set (SMTP required)
2. Browse to URL → sign up (first user becomes admin)
3. Configure organization name, theme, branding
4. Post a test feedback item → verify email notifications arrive
5. Configure OAuth providers if wanted
6. Put behind TLS
7. Decide: public board (anyone can post/vote) vs private (login required)
8. Back up Postgres

## Data & config layout

- **PostgreSQL** — all app data (ideas, votes, users, comments)
- **Uploaded attachments** — per config (may be DB BLOBs or S3/filesystem — check Fider version)
- **Env vars** — all config

## Backup

```sh
pg_dump -Fc -U fider fider > fider-$(date +%F).dump
```

## Upgrade

1. Releases: <https://github.com/getfider/fider/releases>. TryGhost-stewarded; moderate cadence.
2. Docker: bump tag; migrations run automatically on boot.
3. Read release notes for breaking env-var changes.
4. Back up Postgres first.

## Gotchas

- **SMTP is effectively required.** Fider without email notifications is a dead portal — users post, nobody sees responses, engagement dies. Set up SMTP before launching to users.
- **"Public" feedback portals = abuse magnets.** Open boards receive spam posts + comment floods + off-topic noise. Mitigations:
  - **Require email verification** before posting
  - **Moderation queue** for first posts (if available)
  - **Rate limiting** at reverse proxy
  - **reCAPTCHA** integration if configured
  - **Consider private board** (login-walled) for B2B tools
- **Feedback-portal politics**: public vote counts influence which features users EXPECT you to ship. If you can't deliver the top-voted feature, users resent the process. Transparent communication about what "votes" mean + how priorities actually get set is essential. Not a tool problem; a process one.
- **"Declined" is the HARD status.** Shipping a "no, we won't build this" update is harder than shipping code. Fider makes the status easy; the communication is the real work.
- **Competitive-intel exposure**: public feedback boards = competitors see your roadmap + what customers want. Some companies want this; others prefer private boards. Know your stance.
- **TryGhost acquisition (2024)**: Fider was acquired by TryGhost (Ghost blogging platform, non-profit Foundation). Good news: institutional stewardship, active maintenance, funded by Fider Cloud + Ghost revenue. Consistent with Ghost's mission. Bus-factor significantly mitigated. Same pattern as Mozilla-origin-now-community-stewarded (Kinto batch 80) but with active acquirer.
- **PostgreSQL-only** — no SQLite option. Production-grade choice; adds one piece of infrastructure to manage.
- **JWT_SECRET immutability** — rotating invalidates sessions. Same pattern as Wakapi salt (batch 81), Statamic APP_KEY (batch 77), etc. Immutability-of-secrets family.
- **Custom domain + branding is important** for customer-facing use — don't leave it as `feedback.yourdomain.fider.io`-style. Users trust your-brand more than Fider-brand.
- **API + webhooks** — integrate with PRD tools (Jira, Linear, Notion). Don't manually copy-paste.
- **GDPR compliance for customer-data**: if EU customers, Fider holds their feedback + contact info. Data-export + delete-account flows supported. Review + document your DPA.
- **Roadmap visibility tradeoff**: many teams HIDE "Declined" status from public and show only "Planned + Started + Completed" → filters the noise but reduces transparency. Decide deliberately.
- **Alternatives worth knowing:**
  - **Canny** — commercial SaaS; polished; expensive
  - **UserVoice** — commercial SaaS; enterprise
  - **FeatureUpvote** — commercial
  - **Frill** — commercial
  - **Nolt** — commercial
  - **ProductBoard** — PM-heavy; enterprise
  - **Discourse** — forum, not purpose-built but can do feedback via categories
  - **GitHub Discussions** — free if your users have GitHub accounts
  - **Choose Fider if:** want self-hosted + own your data + TryGhost-stewarded + free.
  - **Choose Canny if:** want polish + deep integrations + enterprise support + willing to pay.
  - **Choose GitHub Discussions if:** developer audience + GitHub is already a dependency.
- **License**: **AGPL-3.0** (self-host). Same class as MiroTalk (batch 80), AnonAddy (79), WriteFreely (74), Papra (81).
- **Ethical purchase**: Fider Cloud OR OpenCollective donation — funds TryGhost Foundation which stewards OSS.

## Links

- Repo: <https://github.com/getfider/fider>
- Homepage: <https://fider.io>
- Docs: <https://docs.fider.io>
- Self-hosted: <https://docs.fider.io/self-hosted/>
- Fider Cloud: <https://fider.io/#get-started>
- Demo: <https://demo.fider.io>
- Releases: <https://github.com/getfider/fider/releases>
- OpenCollective: <https://opencollective.com/fider>
- Docker Hub: <https://hub.docker.com/r/getfider/fider>
- TryGhost (new owner): <https://ghost.org>
- Canny (alt): <https://canny.io>
- Discourse (alt): <https://www.discourse.org>
