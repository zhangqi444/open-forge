---
name: Rallly
description: "Self-hosted group-scheduling / meeting-poll tool — find the best date+time based on participants' availability. Next.js + Prisma + tRPC. PostgreSQL. AGPL-3.0. Commercial SaaS tier at rallly.co funds upstream."
---

# Rallly

Rallly (three 'l's) is **self-hosted Doodle** — create a meeting poll with candidate dates/times, share a link, participants mark availability, best slot wins. Clean modern UI, multi-language (Crowdin-localized), timezone-aware, built with Next.js + Prisma + tRPC + TailwindCSS. Developed by **Luke Vella (lukevella)**. Also offered as a hosted commercial SaaS at **rallly.co** which funds upstream development.

Positioning: Doodle / When2Meet / Meetcal alternative — privacy-first, no ads, no tracking, data in your database.

Features:

- **Meeting polls** — candidate date/time slots; participants vote
- **Timezone-aware** — each participant sees times in their local TZ
- **Anonymous or authenticated** participation
- **Finalized meeting** — once you pick, send calendar invites (.ics)
- **Email notifications** — new votes, finalization, reminders
- **Multi-language** — Crowdin-driven i18n
- **Multi-poll dashboard** for organizers
- **Short-link support**
- **Self-host or commercial managed (rallly.co)**

- Upstream repo: <https://github.com/lukevella/rallly>
- Self-hosting docs: <https://support.rallly.co/self-hosting>
- Config options: <https://support.rallly.co/self-hosting/configuration-options>
- Commercial managed: <https://rallly.co>
- Discord: <https://discord.gg/uzg4ZcHbuM>
- Crowdin: <https://crowdin.com/project/rallly>

## Architecture in one minute

- **Next.js** app (Node.js 20+)
- **Prisma** ORM → **PostgreSQL**
- **tRPC** for internal API
- **SMTP** or **SES/other provider** for transactional email
- **Resource**: modest — 200-400 MB RAM; Postgres separate
- **Official Docker image** on GHCR

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Single VM          | **Docker Compose (app + Postgres)**                                | **Upstream-recommended**                                                           |
| Raspberry Pi       | arm64 — works                                                              | Low load fits Pi                                                                            |
| Kubernetes         | Community manifests                                                                           | Works                                                                                                    |
| Managed SaaS       | **rallly.co** — directly funds upstream                                                                       | Good ethical-purchase path (same pattern as Write.as → WriteFreely batch 74)                                                                               |

## Inputs to collect

| Input                | Example                                           | Phase        | Notes                                                                    |
| -------------------- | ------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `polls.home.lan`                                       | URL          | TLS via reverse proxy                                                            |
| `DATABASE_URL`       | `postgresql://user:pass@pg:5432/rallly`                        | DB           | Dedicated Postgres recommended                                                            |
| `SECRET_PASSWORD`    | 32+ random chars                                              | Crypto       | Session + magic-link encryption                                                                           |
| `NEXT_PUBLIC_BASE_URL` | `https://polls.home.lan`                                                    | URL          | Absolute public URL                                                                                      |
| SMTP credentials     | `SUPPORT_EMAIL` + SMTP host/port/user/pass                                    | Email        | **Required for magic-link auth + notifications**                                                                                  |
| Admin email          | first user you create will be the admin                                                      | Bootstrap    | Register via the UI                                                                                                                      |

## Install via Docker Compose

```yaml
services:
  rallly:
    image: ghcr.io/lukevella/rallly:4.10.1               # pin specific version in prod
    container_name: rallly
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      DATABASE_URL: postgresql://rallly:CHANGE_ME@postgres:5432/rallly
      SECRET_PASSWORD: "GENERATE_32_PLUS_RANDOM_CHARS"
      NEXT_PUBLIC_BASE_URL: https://polls.example.com
      SUPPORT_EMAIL: noreply@example.com
      SMTP_HOST: smtp.example.com
      SMTP_PORT: "587"
      SMTP_USER: apikey
      SMTP_PWD: "SECRET"
      SMTP_SECURE: "true"
    depends_on:
      - postgres

  postgres:
    image: postgres:16
    restart: unless-stopped
    environment:
      POSTGRES_USER: rallly
      POSTGRES_PASSWORD: CHANGE_ME
      POSTGRES_DB: rallly
    volumes:
      - ./db:/var/lib/postgresql/data
```

Browse `https://polls.example.com/` → create first poll.

## First boot

1. Browse URL → register account (magic-link email — SMTP MUST work)
2. Create a test poll → verify email + share link
3. Test participant flow on anonymous browser → vote → verify results show
4. Put behind TLS reverse proxy
5. Configure email deliverability (SPF/DKIM/DMARC) — magic-link auth fails silently if deliverability is bad
6. Enable backups on Postgres

## Data & config layout

- **PostgreSQL** — all polls, votes, users, notifications
- No uploaded-file volumes (Rallly is text-only)

## Backup

```sh
pg_dump -U rallly rallly > rallly-$(date +%F).sql
```

Small DB; easy. Daily dumps + offsite copy.

## Upgrade

1. Releases: <https://github.com/lukevella/rallly/releases>. Active.
2. `pnpm db:migrate` / auto-migrate via Prisma on start depending on image.
3. **Back up DB before major versions.**
4. Docker: bump tag → restart → migrations auto (via Prisma).

## Gotchas

- **SMTP IS mandatory** — Rallly uses magic-link auth (no password option by default). Bad SMTP = no one can sign in. Test with `swaks` / a real inbox before rolling out to participants.
- **Email deliverability**: magic-link and notification emails are transactional. Use a reputable SMTP (Postmark, SendGrid, SES) + configure SPF/DKIM/DMARC on your sending domain. Home-rolled SMTP going to Gmail inboxes will land in spam.
- **`SECRET_PASSWORD`** must be strong + stable — rotating breaks existing sessions + magic links.
- **`NEXT_PUBLIC_BASE_URL`**: baked into emails + links. Set correctly before first use. Changing later means old magic-links break.
- **Timezone handling**: Rallly handles it well but only if participants' browsers report TZ correctly. Explicit TZ-picker is available.
- **Commercial managed vs self-hosted**: rallly.co is the commercial version. Using it directly supports upstream (same pattern as WriteFreely's write.as — batch 74). Self-hosted is free + AGPL.
- **AGPL-3.0**: if you modify + host publicly, publish changes. (Same as batch 74 WriteFreely + Zoraxy.)
- **No end-to-end encryption**: poll content is plaintext in your DB. Not suited for confidential scheduling that requires zero-knowledge.
- **Calendar integration**: finalization can generate `.ics` attachments. No direct OAuth integration to Google/Outlook calendars out of the box (check current docs — features evolving).
- **Public poll links**: share-by-link = anyone with link can vote. Good for openness; bad for secret polls. No per-participant auth in simple mode.
- **Abuse scaling**: public instance can be spammed with fake polls. Rate-limit at reverse proxy + require email verification for poll creation.
- **GDPR**: self-hosted = you're data controller. Document retention policy + add deletion endpoints for participants requesting removal.
- **Crowdin translations**: community-driven; some languages may lag features.
- **Single maintainer + commercial backing**: Luke Vella solo-develops with commercial SaaS income funding. Not bus-factor-1 in the dangerous sense (commercial cashflow = sustainability); but still one person. Similar to Cronicle→xyOps pattern (batch 71) — solo → commercial entity provides sustainability signal.
- **License**: **AGPL-3.0**.
- **Alternatives worth knowing:**
  - **Doodle** — original; commercial; ads in free tier
  - **When2Meet** — minimalist; free; privacy-questionable
  - **Cal.com** — booking-oriented; much larger feature scope; self-hostable
  - **Framadate** — French FOSS group-poll; ActivityPub-ish; older UX
  - **Dudle** — older FOSS Doodle-alt
  - **Nextcloud Polls** — if you already run Nextcloud
  - **Choose Rallly if:** dedicated group-polling + modern UX + self-host or commercial-managed options.
  - **Choose Cal.com if:** also need booking/appointment scheduling.
  - **Choose Framadate if:** French instance / minimal setup.
  - **Choose Nextcloud Polls if:** already in Nextcloud ecosystem.

## Links

- Repo: <https://github.com/lukevella/rallly>
- Self-hosting: <https://support.rallly.co/self-hosting>
- Config options: <https://support.rallly.co/self-hosting/configuration-options>
- Managed: <https://rallly.co>
- Discord: <https://discord.gg/uzg4ZcHbuM>
- Releases: <https://github.com/lukevella/rallly/releases>
- Container: <https://ghcr.io/lukevella/rallly>
- Crowdin: <https://crowdin.com/project/rallly>
- Cal.com (alt): <https://cal.com>
- Framadate (alt): <https://framadate.org>
