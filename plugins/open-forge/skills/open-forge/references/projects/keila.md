---
name: Keila
description: "Open-source newsletter tool — Mailchimp/Sendinblue alternative. Campaign editor; sign-up forms; IMAP/SMTP/AWS SES/Sendgrid/Mailgun/Postmark. Elixir. pentacent. GitHub Sponsors. Hosted cloud option. AGPL likely."
---

# Keila

Keila is **"Mailchimp/Sendinblue — but open-source + self-hosted"** — open-source newsletter tool. Send campaigns + create sign-up forms. For small newsletters: use your own email inbox. For larger: **AWS SES, Sendgrid, Mailgun, Postmark** + SMTP supported. WYSIWYG campaign editor. Also available as hosted service at app.keila.io.

Built + maintained by **pentacent**. License: check (likely AGPL). GitHub Sponsors + Mastodon + Bluesky presence. Elixir-based (implied by ecosystem + hosted offering). Active CI.

Use cases: (a) **self-hosted newsletter-tool** — GDPR-friendly (b) **escape Mailchimp pricing** (c) **indie-creator subscriber-list** (d) **community-project newsletter** (e) **sign-up form + double-opt-in** (f) **small list via own SMTP** (g) **large list via SES/Sendgrid** (h) **GDPR-compliant EU subscribers**.

Features (per README):

- **Campaign editor** (WYSIWYG)
- **Sign-up forms**
- **Multi-provider** — IMAP, SMTP, AWS SES, Sendgrid, Mailgun, Postmark
- **Hosted option** at app.keila.io
- **Open-source for self-host**

- Upstream repo: <https://github.com/pentacent/keila>
- Website: <https://www.keila.io>
- Docs: <https://www.keila.io/docs/installation>
- Hosted: <https://app.keila.io>

## Architecture in one minute

- **Elixir / Phoenix**
- **PostgreSQL**
- **Sending provider**: SES/Sendgrid/Mailgun/Postmark/SMTP
- **Resource**: low-moderate — Elixir is efficient
- **Port**: web UI

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker Compose** | **App + PG**                                                    | **Primary**                                                                        |
| **Hosted SaaS**    | `app.keila.io`                                                                                                         | Alt (commercial-parallel)                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `mail.example.com`                                          | URL          | TLS                                                                                    |
| Admin creds          | First-boot                                                  | Bootstrap    | Strong                                                                                    |
| PostgreSQL           | Data                                                        | DB           |                                                                                    |
| Sending provider     | SES/Sendgrid/Mailgun/Postmark/SMTP                          | **CRITICAL** | **API key or SMTP creds — emailing credentials**                                                                                    |
| From domain          | For SPF/DKIM/DMARC                                          | Deliverability|                                                                                    |
| List subscribers     | Ingested over time                                          | Data         | PII                                                                                    |

## Install via Docker

See <https://www.keila.io/docs/installation> and <https://github.com/pentacent/keila/blob/main/ops/docker-compose.yml>.

```yaml
services:
  db:
    image: postgres:17
    environment:
      POSTGRES_USER: keila
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: keila
    volumes: [pgdata:/var/lib/postgresql/data]

  keila:
    image: pentacent/keila:latest        # **pin version**
    environment:
      DATABASE_URL: "ecto://keila:${DB_PASSWORD}@db/keila"
      URL_HOST: "mail.example.com"
      SECRET_KEY_BASE: ${SECRET_KEY_BASE}
      MAILER_TYPE: smtp
      MAILER_SMTP_HOST: smtp.example.com
      MAILER_SMTP_USER: user
      MAILER_SMTP_PASS: ${SMTP_PASSWORD}
    ports: ["4000:4000"]
    depends_on: [db]

volumes:
  pgdata: {}
```

## First boot

1. Generate SECRET_KEY_BASE: `openssl rand -base64 48`
2. Start stack
3. Create admin account
4. Configure SPF/DKIM/DMARC for your from-domain
5. Send test campaign
6. Embed sign-up form on your site
7. Put behind TLS
8. Back up PG

## Data & config layout

- **PostgreSQL** — subscribers, campaigns, templates, deliveries
- **Config** — via env

## Backup

```sh
docker compose exec db pg_dump -U keila keila > keila-$(date +%F).sql
# **Contains PII (all subscriber emails + maybe names/IPs) — ENCRYPT, comply with GDPR**
```

## Upgrade

1. Releases: <https://github.com/pentacent/keila/releases>. Active.
2. DB migrations — read release notes
3. Docker pull + restart

## Gotchas

- **140th HUB-OF-CREDENTIALS CROWN-JEWEL TIER 1 — SUBSCRIBER-LIST + EMAIL-SENDING-CREDS**:
  - PII: all subscriber emails, names, interaction data (opens, clicks)
  - Send-credentials: SES/Sendgrid/Mailgun API keys
  - **140th tool in hub-of-credentials family — Tier 1 CROWN-JEWEL**
  - **140-TOOL HUB-OF-CREDENTIALS MILESTONE at Keila**
  - **NEW CROWN-JEWEL Tier 1 sub-category: "newsletter-tool + subscriber-PII-plus-sending-creds"** (1st — Keila)
  - **CROWN-JEWEL Tier 1: 42 tools / 39 sub-categories**
- **GDPR-COMPLIANCE-BURDEN**:
  - EU subscribers = GDPR responsibilities
  - Data export + deletion + consent + audit
  - **Recipe convention: "GDPR-subscriber-data-rights-discipline callout"**
  - **NEW recipe convention** (Keila 1st formally)
- **EMAIL-DELIVERABILITY-COMPLEXITY**:
  - SPF + DKIM + DMARC required for reputable sending
  - Reinforces AliasVault (112) self-hosted-email-deliverability
  - **Self-hosted-email-deliverability-complexity: 2 tools** (AliasVault+Keila) 🎯 **2-TOOL MILESTONE**
- **ABUSE-POTENTIAL (if open signup to editors)**:
  - Self-hosted newsletter platforms can be abused for spam
  - If you allow multi-user signup, you're a spam-vector
  - **Recipe convention: "multi-tenant-newsletter-abuse-mitigation callout"**
  - **NEW recipe convention** (Keila 1st formally)
- **SENDING-PROVIDER-CREDENTIAL-ROTATION**:
  - Compromised SES key = attacker can send mass-spam from YOUR domain = reputation-ruin
  - **Recipe convention: "sending-provider-key-rotation-discipline callout"**
  - **NEW recipe convention** (Keila 1st formally)
- **COMMERCIAL-PARALLEL (app.keila.io)**:
  - Hosted SaaS at app.keila.io
  - OSS self-host option preserved
  - **Commercial-parallel-with-OSS-core: 10 tools** (+Keila) 🎯 **10-TOOL MILESTONE**
- **ELIXIR/PHOENIX-STACK**:
  - Low-resource + fault-tolerant
  - **Elixir/Phoenix-stack: 1 tool** 🎯 **NEW FAMILY** (Keila)
- **MASTODON + BLUESKY PRESENCE**:
  - Follows project on decentralized socials
  - **Recipe convention: "fediverse-plus-bluesky-presence positive-signal"**
  - **NEW positive-signal convention** (Keila 1st formally)
- **INSTITUTIONAL-STEWARDSHIP**: pentacent + GitHub Sponsors + website + hosted-option + Mastodon + Bluesky + docs + CI. **126th tool — commercial-org-with-fediverse-presence sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + CI + hosted-option + docs + releases + socials. **132nd tool in transparent-maintenance family.**
- **NEWSLETTER-TOOL-CATEGORY:**
  - **Keila** — Elixir; multi-provider; hosted-option
  - **Listmonk** — Go; mature; high-perf
  - **Mautic** — PHP; full marketing-automation
  - **Sendy** — PHP (commercial)
- **ALTERNATIVES WORTH KNOWING:**
  - **Listmonk** — if you want Go + mature + high-performance
  - **Mautic** — if you want full marketing automation (heavy)
  - **Choose Keila if:** you want Elixir + multi-provider + hosted-option.
- **PROJECT HEALTH**: active + commercial-parallel + website + socials + docs. Strong.

## Links

- Repo: <https://github.com/pentacent/keila>
- Website: <https://www.keila.io>
- Hosted: <https://app.keila.io>
- Listmonk (alt): <https://github.com/knadh/listmonk>
- Mautic (alt): <https://github.com/mautic/mautic>
