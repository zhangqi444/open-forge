---
name: Kill the Newsletter!
description: "Tiny self-hosted tool: converts email newsletters into Atom/RSS feeds. Subscribe via unique catch-all email address; server renders emails as feed entries. Node.js; part of radically-straightforward monorepo. Hosted at kill-the-newsletter.com. License: check repo."
---

# Kill the Newsletter!

Kill the Newsletter! is **"a micro-tool: email → RSS/Atom feed"** — a minimalist self-hosted server that creates a unique catch-all email address per feed. Any email sent to that address becomes a feed entry. Subscribe in your RSS reader (Feedly, Miniflux, FreshRSS, NetNewsWire, etc.) and read newsletters like any other feed — no more inbox clutter from Substack/The Hustle/Morning Brew/Stratechery.

Built + maintained by **leafac** (Leandro Facchinetti) within the radically-straightforward monorepo. License: check repo. Active; public hosted service at kill-the-newsletter.com (use it if you don't want to self-host); Node.js-based; part of a larger ecosystem of radically-straightforward tools (Courselore, Kill the Newsletter!, others).

Use cases: (a) **inbox hygiene** — route Substack/newsletters to RSS reader instead of email (b) **RSS-first workflow** — consolidate reading in one tool (Miniflux/FreshRSS/Feedly) (c) **family-shared newsletter feeds** — public feed URL; everyone subscribes (d) **newsletter archiving** — RSS reader stores full newsletter archive (e) **newsletter-to-Readwise pipeline** — many Readwise users use this as entry point (f) **searchable newsletters** — RSS reader search beats Gmail search (g) **write-protection** — emails can't be spam-phished if they come via RSS.

Features (from upstream README):

- **Converts emails → Atom feeds**
- **Unique catch-all email per feed** (you sign up to newsletters with that address)
- **Hosted public service available** (kill-the-newsletter.com)
- **Self-hostable**
- **Part of radically-straightforward monorepo** (Node.js ecosystem)

- Upstream repo: <https://github.com/leafac/kill-the-newsletter>
- Hosted service: <https://kill-the-newsletter.com>
- Deployment guide: <https://github.com/radically-straightforward/radically-straightforward/blob/main/guides/deployment.md>
- Development guide: <https://github.com/radically-straightforward/radically-straightforward/blob/main/guides/development.md>

## Architecture in one minute

- **Node.js** (TypeScript likely)
- **SQLite** — DB (likely, given minimalist bent)
- **SMTP server** — receives emails on a port you expose
- **HTTP server** — serves Atom feed
- **Resource**: very low — 50-100MB RAM
- **DNS MX records** — route newsletter-domain emails to Kill-the-Newsletter server

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Hosted service** | **kill-the-newsletter.com**                                     | **Zero-maintenance — first choice**                                                                        |
| **Self-host**      | **Node.js per radically-straightforward deployment guide**      | **For max privacy / custom domain**                                                                        |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `newsletters.example.com`                                   | URL          | **MX records point to your server**                                                                                    |
| SMTP port            | 25 (classic) or 587                                         | Network      | **Port 25 blocked on most cloud VPS** — often need port 587 forwarded                                                                                    |
| DNS control          | Add A + MX records                                          | **CRITICAL** |                                                                                    |
| TLS cert             | For SMTP + HTTP                                             | Security     | Let's Encrypt                                                                                    |

## Install

Follow radically-straightforward deployment guide:
<https://github.com/radically-straightforward/radically-straightforward/blob/main/guides/deployment.md>

High-level:

1. Deploy Node.js app on VPS
2. Configure DNS: A record for web + MX for email
3. Open port 25 (or configure provider to allow it)
4. Start server; browse to generate first feed
5. Sign up to a newsletter with the generated email
6. Subscribe to the generated Atom feed URL in your RSS reader
7. Back up SQLite DB

## Data & config layout

- SQLite DB — newsletters + entries
- Attachment storage (if any) — likely on filesystem
- Logs

## Backup

```sh
sudo cp kill-the-newsletter.db "ktn-$(date +%F).db"
```

## Upgrade

1. Upstream is part of a monorepo; changes may be infrequent but should pull + redeploy per the deployment guide.
2. Back up DB before upgrade.

## Gotchas

- **MICRO-TOOL CATEGORY** — rare in the self-host world:
  - Does ONE thing well (email → RSS)
  - ~300-byte README; self-documented concept
  - **Recipe convention: "micro-tool single-purpose" category**
  - Related: single-purpose philosophy (UNIX-philosophy alignment)
- **HOSTED VS SELF-HOST TRADE-OFF**:
  - Hosted (kill-the-newsletter.com): free + zero-maintenance + creator runs it
  - Self-host: custom domain + privacy + no third-party seeing newsletter content
  - **Pattern recommendation**: most users should just use hosted; self-host only if:
    - You want custom domain (e.g., @newsletters.yourdomain.com)
    - You care deeply about newsletter content privacy (some newsletters track open rates via tracking pixels)
    - You're in a high-compliance environment (legal / medical where 3rd-party-email-forwarding is restricted)
- **SMTP-RECEIVING = OPERATIONAL COMPLEXITY**:
  - Running an internet-facing SMTP server is non-trivial
  - **Port 25 typically blocked on home ISPs + cloud providers** (DigitalOcean, AWS EC2 by default)
  - Need MX records configured correctly
  - Need TLS for STARTTLS compliance (spam filters reject plain SMTP)
  - Need anti-spam posture (Kill-the-Newsletter is receive-only → simpler than outbound SMTP, but still)
  - **Recipe convention: "SMTP-receiving-operational-complexity" callout**
- **SPAM MAGNET = GUARANTEED**:
  - Catch-all email addresses attract spam
  - Your RSS feed will fill with spam entries
  - **Mitigation**: per-feed addresses + delete unused feeds; some filtering
  - Well-configured spam filters help but some spam slips through
- **NEWSLETTER-TRACKING-PIXELS**:
  - Many newsletters (Substack, ESPs) embed tracking pixels (open-rate tracking)
  - RSS reader fetching pixels = you're still tracked
  - **Mitigation**: RSS reader that blocks external images / proxies images
- **PRIVACY: NEWSLETTER CONTENT IN YOUR DB**:
  - All newsletter content stored locally
  - **60th+ tool in hub-of-credentials family — Tier 3** (newsletter content)
  - Generally low-sensitivity (public-facing newsletters) but occasionally:
    - Exclusive newsletters with personal info
    - Paid newsletters (their tracking reveals your subscription)
    - Legal: you're effectively archiving copyrighted content
- **AUTH MODEL**: typically no-auth or public-by-default (feed-URL is secret-enough)
  - Anyone with feed URL reads your newsletter content
  - **Keep feed URLs private** (treat like passwords)
  - More secure: put behind HTTP auth / reverse-proxy auth
- **INSTITUTIONAL-STEWARDSHIP**: leafac + community. **46th tool in institutional-stewardship — sole-maintainer-with-community sub-tier (24th tool).**
- **TRANSPARENT-MAINTENANCE**: monorepo + public hosted service + concise README + deployment guide. **53rd tool in transparent-maintenance family.**
- **LICENSE CHECK**: verify LICENSE (convention).
- **RADICALLY-STRAIGHTFORWARD MONOREPO**:
  - Leafac's broader project collection
  - Related: Courselore (course-management)
  - Philosophy: minimalist tools that do one thing well
  - **Recipe convention: "ecosystem-from-shared-monorepo" note**
- **ALTERNATIVES WORTH KNOWING:**
  - **Feedbin newsletters** — commercial; integrates with Feedbin RSS reader
  - **Readwise** — commercial; built-in email-to-library workflow
  - **Postmark Inbound** — generic email-to-webhook service
  - **Forward email + self-write-feed** — DIY
  - **Follow.it** — commercial newsletter-to-RSS service
  - **Kill the Newsletter!** — Leafac's; OSS; self-hostable or hosted
  - **Choose Kill the Newsletter! if:** you want OSS + free + self-host-optional + minimal.
  - **Choose Feedbin if:** you want polished + commercial + integrated-RSS.
  - **Choose Readwise if:** you want library-building + highlighting workflow.
- **PROJECT HEALTH**: stable + public-hosted-service funded by creator + minimal-surface-area = low-maintenance burden + high-reliability.

## Links

- Repo: <https://github.com/leafac/kill-the-newsletter>
- Hosted: <https://kill-the-newsletter.com>
- Deployment guide: <https://github.com/radically-straightforward/radically-straightforward/blob/main/guides/deployment.md>
- Development guide: <https://github.com/radically-straightforward/radically-straightforward/blob/main/guides/development.md>
- Leafac's projects: <https://github.com/leafac>
- Miniflux (RSS reader): <https://miniflux.app>
- FreshRSS (RSS reader): <https://freshrss.org>
- Feedly (commercial alt): <https://feedly.com>
- Readwise (commercial email-to-library): <https://readwise.io>
- Follow.it (commercial newsletter-to-RSS): <https://follow.it>
