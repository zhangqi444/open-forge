---
name: Mail-Archiver
description: "Email archiving system — archive/search/export emails from multiple accounts. .NET + PostgreSQL + Bootstrap. OIDC auth. Mobile + desktop + multilingual. Dark mode. s1t5/mail-archiver. mail-archiver.org. Ko-Fi + Buy Me a Coffee funded."
---

# Mail-Archiver

Mail-Archiver is **"Open Archiver / Mailpiler — but .NET + simpler + personal-grade"** — an email archiving system for automated archiving, advanced search, export as mbox or zipped-EML. Multi-account. OIDC SSO integration. Mobile + desktop responsive with dark mode + multi-language.

Built + maintained by **s1t5**. .NET + PostgreSQL + Bootstrap. mail-archiver.org website. Ko-Fi + Buy Me a Coffee dual-funding. Docker-deployable.

Use cases: (a) **personal multi-account email archive** (b) **family/small-team email backup** (c) **legacy-account export before closing** (d) **Gmail archive to local + searchable** (e) **mbox/EML export for eDiscovery** (f) **OIDC-integrated email archive** (g) **dark-mode-friendly archive UX** (h) **multilingual archive for polyglot households**.

Features (per README):

- **Automated archiving** of incoming + outgoing
- **Multi-account** support
- **Mobile + desktop responsive** + dark mode + multilingual
- **OIDC** authentication
- **Advanced search**
- **Preview + attachment list**
- **Export** as mbox or zipped EML
- **Bulk or individual** export

- Upstream repo: <https://github.com/s1t5/mail-archiver>
- Website: <https://mail-archiver.org>
- Ko-Fi: <https://ko-fi.com/s1t5dev>
- Buy Me a Coffee: <https://www.buymeacoffee.com/s1t5>

## Architecture in one minute

- **.NET** backend
- **PostgreSQL**
- **Bootstrap** UI
- **Docker** deploy
- **Resource**: moderate — scales with archive size
- **Port**: HTTP

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | Upstream                                                                                                               | **Primary**                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `mail-archive.example.com`                                  | URL          | **TLS MANDATORY**                                                                                    |
| IMAP creds           | Per-account                                                 | Secret       | **App-passwords for Gmail/etc.**                                                                                    |
| PostgreSQL           | Data                                                        | DB           |                                                                                    |
| OIDC provider        | Optional                                                    | Auth         |                                                                                    |
| Storage              | Attachments                                                 | Storage      |                                                                                    |

## Install via Docker

See docs at mail-archiver.org. Typical:
```yaml
services:
  postgres:
    image: postgres:15
  mail-archiver:
    image: s1t5/mail-archiver:latest        # **pin**
    depends_on: [postgres]
    ports: ["5000:5000"]
    volumes:
      - ./mail-archiver-data:/data
    environment:
      - DATABASE_URL=...
```

## First boot

1. Start
2. Create admin (or via OIDC)
3. Add IMAP account(s) — use app-passwords
4. Configure archive schedule
5. Test sync + search
6. Try export flow
7. Put behind TLS
8. Back up DB + /data

## Data & config layout

- Postgres — users, account configs, email indexes
- /data — attachments + archived email blobs

## Backup

```sh
pg_dump mail_archiver > mail-archiver-$(date +%F).sql
sudo tar czf mail-archiver-data-$(date +%F).tgz mail-archiver-data/
# Contains ALL archived emails — **ENCRYPT**
```

## Upgrade

1. Releases: <https://github.com/s1t5/mail-archiver/releases>
2. Docker pull + restart
3. DB migrations

## Gotchas

- **178th HUB-OF-CREDENTIALS CROWN-JEWEL TIER 1 — MULTI-ACCOUNT-EMAIL-ARCHIVE**:
  - Holds: **all archived emails from all accounts**, IMAP app-passwords (long-lived!), attachments
  - Distinct from Open Archiver (122) — Mail-Archiver is **personal/small-team scale**, Open Archiver is **enterprise workspace-delegation**
  - **178th tool in hub-of-credentials family — Tier 1 CROWN-JEWEL**
  - Matures sub-cat: **"email-archive-aggregator": 2 tools** (Open Archiver + Mail-Archiver) 🎯 **2-TOOL MILESTONE — MATURED sub-category**
  - **CROWN-JEWEL Tier 1: 61 tools / 54 sub-categories** (sub-cat matured, not new)
- **APP-PASSWORD-OVER-OAUTH**:
  - IMAP-password = long-lived credential
  - Gmail/Outlook prefer OAuth2
  - **Recipe convention: "IMAP-app-password-vs-OAuth-tradeoff callout"**
  - **NEW recipe convention** (Mail-Archiver 1st formally)
- **PERSONAL-VS-ENTERPRISE-SCOPE**:
  - Personal-scale sensitivity: user's own account(s)
  - No workspace-delegation god-mode risk (unlike Open Archiver)
  - **Recipe convention: "scope-tier-personal-vs-workspace distinction"**
  - **NEW recipe convention** (Mail-Archiver 1st formally)
- **OIDC-SUPPORT**:
  - SSO integration via OIDC
  - **Recipe convention: "OIDC-SSO-integration-support positive-signal"**
  - **NEW positive-signal convention** (Mail-Archiver 1st formally — joins VoidAuth-perspective-flipped)
- **KO-FI + BUY-ME-A-COFFEE DUAL-FUNDING**:
  - **Ko-Fi-funding: 3 tools** (Notediscovery+Versitygw+Mail-Archiver) 🎯 **3-TOOL MILESTONE**
  - **BuyMeACoffee-funding: 1 tool** 🎯 **NEW FAMILY** (Mail-Archiver)
  - **Multi-platform-funding: 2 tools** (Podsync+Mail-Archiver) 🎯 **2-TOOL MILESTONE**
- **DARK-MODE-MULTI-LANGUAGE**:
  - UI polish
  - **Recipe convention: "dark-mode-plus-i18n-UI-polish positive-signal"**
  - **NEW positive-signal convention** (Mail-Archiver 1st formally)
- **MBOX-EML-STANDARD-EXPORT**:
  - Open formats
  - **Recipe convention: "standard-format-export-portability"** — reinforces Podsync (124)
- **INSTITUTIONAL-STEWARDSHIP**: s1t5 + mail-archiver.org website + dual-funding + OIDC + Docker + active. **164th tool — sole-dev-with-branded-website sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + website + releases + Docker + OIDC + dual-funding. **170th tool in transparent-maintenance family** 🎯 **170-TOOL TRANSPARENT-MAINTENANCE MILESTONE at Mail-Archiver**.
- **EMAIL-ARCHIVE-CATEGORY:**
  - **Mail-Archiver** — .NET; personal/small-team; OIDC
  - **Open Archiver** — TypeScript; workspace-domain-delegation; enterprise (b121)
  - **Mailpiler** — PHP; MTA-capture; mature
  - **MailArchiva** — commercial
  - **archivemail** — CLI
- **ALTERNATIVES WORTH KNOWING:**
  - **Open Archiver** — if you need workspace/M365 ingest + petabyte-scale
  - **Mailpiler** — if you want MTA-capture
  - **Choose Mail-Archiver if:** you want .NET + IMAP + OIDC + personal/small-team scope.
- **PROJECT HEALTH**: active + website + docs + dual-funding. Strong sole-dev.

## Links

- Repo: <https://github.com/s1t5/mail-archiver>
- Website: <https://mail-archiver.org>
- Open Archiver (alt enterprise): <https://github.com/LogicLabs-OU/OpenArchiver>
- Mailpiler (alt): <https://github.com/jsuto/piler>
