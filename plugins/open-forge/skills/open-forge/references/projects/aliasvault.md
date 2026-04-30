---
name: AliasVault
description: "Privacy-first password + email alias manager with built-in email server. End-to-end encrypted. Self-hosted. Web + browser extensions + iOS + Android apps. lanedirt creator. Discord + OpenCollective + Crowdin. Zero 3rd-party dependencies."
---

# AliasVault

AliasVault is **"Bitwarden + SimpleLogin/AnonAddy + Proton Mail (built-in) — in ONE self-hosted package"** — a privacy-first password + email-alias manager with its OWN email server. Create unique identities per site (random name + DOB + address + email-alias + password). **Fully E2E encrypted** (zero-knowledge). **Built-in email server** so you can receive at `random-alias@your-domain.com` without relying on SimpleLogin/AnonAddy. Web app + browser extensions + native iOS + Android.

Built + maintained by **Leendert de Borst (@lanedirt)** + community. License: check LICENSE (likely AGPL). Active; Discord; Open Collective funding; Crowdin localization; cloud version at app.aliasvault.net.

Use cases: (a) **Bitwarden + email-alias combined** — one tool (b) **SimpleLogin-replacement** — own email server (c) **proton-replacement** — own domains + aliases (d) **identity-per-site** privacy workflow (e) **family/team password-manager** self-hosted (f) **anti-tracking across web** — different emails per site (g) **data-breach isolation** — breached-alias can be discarded (h) **small-business credential-hub** self-hosted.

Features (per README):

- **Password manager** (E2E encrypted)
- **Email alias manager** with BUILT-IN email server
- **Random identity generation** (name, DOB, address, etc.)
- **Browser extensions** (Chrome, Firefox)
- **Native iOS + Android apps**
- **Zero 3rd-party dependencies** (own email server)
- **Cloud version** available (managed)
- **Crowdin localization**
- **Community-driven** (Discord)

- Upstream repo: <https://github.com/aliasvault/aliasvault>
- Website: <https://aliasvault.net>
- Docs: <https://docs.aliasvault.net>
- Cloud: <https://app.aliasvault.net>
- Discord: <https://discord.gg/DsaXMTEtpF>
- Open Collective: <https://opencollective.com/aliasvault>

## Architecture in one minute

- **.NET** (C#) — likely
- **PostgreSQL** DB
- **Built-in SMTP + IMAP server**
- **Web + extensions + native apps**
- **Resource**: moderate — 400-800MB RAM
- **Ports**: web UI + SMTP 25 + IMAP 143/993

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker Compose** | **Upstream** install script                                     | **Primary** self-host                                                                        |
| **Cloud**          | Managed at app.aliasvault.net                                                                                          | Pay or free-tier                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Primary domain       | `av.example.com`                                            | URL          | TLS MANDATORY                                                                                    |
| **Email domain(s)**  | `aliases.example.com` (MX record)                           | **CRITICAL** | **Receives all alias email**                                                                                    |
| Master password      | **User-knowledge; never recoverable**                       | **CRITICAL** | **E2E key — loss = permanent data loss**                                                                                    |
| PostgreSQL           | Data                                                        | DB           |                                                                                    |
| SMTP relay (outbound)| For sending from aliases if needed                          | Config       |                                                                                    |
| DNS (SPF/DKIM/DMARC) | For alias deliverability                                    | **DNS**      | **Email-auth CRITICAL**                                                                                    |

## Install via Docker

Follow: <https://docs.aliasvault.net/self-hosting>

## First boot

1. Point DNS (A record + MX record) for email domain
2. Configure SPF/DKIM/DMARC on DNS
3. Run upstream install script
4. Create master account with strong master-password (SAVE IT — no recovery)
5. Install browser extension
6. Create first alias; test inbound email
7. Back up encrypted vault (even backup is encrypted — good)
8. Back up SMTP + master-key material
9. Consider mobile apps
10. Put behind strict TLS + monitoring

## Data & config layout

- PostgreSQL — encrypted vault data (zero-knowledge; admin can't read contents even from server)
- File storage — email bodies (encrypted)
- Keys — master key material client-side; derived server-side only for envelope

## Backup

```sh
docker compose exec db pg_dump -U aliasvault aliasvault > aliasvault-$(date +%F).sql
sudo tar czf aliasvault-data-$(date +%F).tgz data/
# ENCRYPT the backup again (belt-and-suspenders)
```

## Upgrade

1. Releases: <https://github.com/aliasvault/aliasvault/releases>. Active; E2E tests badge.
2. Read release notes — crypto changes = migration
3. Back up BEFORE upgrade — vault format changes are consequential

## Gotchas

- **115th HUB-OF-CREDENTIALS CROWN-JEWEL TIER 1 — PASSWORD-MANAGER + EMAIL-SERVER COMBINED**:
  - AliasVault holds: passwords + email-aliases + INCOMING EMAIL (potentially reset-links for other services!)
  - Compromise = **MFA-reset-emails intercept** + **full-password-vault access**
  - **115th tool in hub-of-credentials family — Tier 1 CROWN-JEWEL**
  - **NEW CROWN-JEWEL Tier 1 sub-category: "password-manager + email-server-combined"** (1st — AliasVault)
  - This is a PARTICULARLY CONCENTRATED risk — password + email reset-destination in one place
  - **CROWN-JEWEL Tier 1: 32 tools / 29 sub-categories**
- **E2E-ENCRYPTED-VAULT (ZERO-KNOWLEDGE) = EXCELLENT**:
  - Server cannot read vault contents
  - Server compromise ≠ vault compromise (unless client software is compromised)
  - **Recipe convention: "zero-knowledge-E2E-encrypted-vault positive-signal"** — reinforces
- **BUILT-IN EMAIL SERVER = HIGH OPS COMPLEXITY**:
  - Self-hosted SMTP = SPF/DKIM/DMARC discipline + deliverability + reputation + blocklist-management
  - Many consumers can't reliably deliver to Gmail/Yahoo/Outlook
  - **Recipe convention: "self-hosted-email-deliverability-complexity callout"** — universal
  - **NEW recipe convention** (AliasVault 1st formally)
  - **Self-hosted-email-server tools family**: AliasVault (now 1 known — Postal, Stalwart, Mailu, Mailcow are separate)
- **MASTER-PASSWORD = NO RECOVERY**:
  - Lose master password = lose ALL vaults + aliases
  - **Recipe convention: "master-password-no-recovery callout"** — universal for E2E tools
  - **NEW recipe convention** (AliasVault 1st formally)
- **MFA-RESET-EMAIL RISK**:
  - If aliases receive MFA reset emails, compromise = account-takeover cascade
  - Users should keep critical-account recoveries OFF the alias system
  - **Recipe convention: "MFA-reset-email-attack-surface callout"** — critical
  - **NEW recipe convention** (AliasVault 1st formally)
- **ALIAS-ECOSYSTEM LEGAL RISK**:
  - Anonymous aliases can be used for spam / fraud
  - Self-hosted server reputation = YOU
  - **Recipe convention: "anti-abuse-discipline-for-self-hosted-alias-service callout"**
  - **NEW recipe convention** (AliasVault 1st formally)
- **NATIVE iOS + ANDROID APPS**:
  - Rare for OSS (Apple dev-fee barrier)
  - **Recipe convention: "native-mobile-apps-OSS-rarity positive-signal"** — reinforces (Libredesk was web-only)
- **CLOUD VERSION AVAILABLE**:
  - Commercial-parallel-with-OSS-core: 6 tools (+ AliasVault) 🎯 **6-TOOL MILESTONE**
- **OPEN COLLECTIVE + DISCORD + CROWDIN**:
  - Open-Collective-transparent-finances: 3 tools (Silex+DockSTARTer+AliasVault) 🎯
  - Community-infrastructure-triple (OC+Discord+Crowdin) positive-signal
- **E2E-TESTS IN CI**:
  - Browser E2E + server E2E tests
  - **Recipe convention: "end-to-end-tests-in-CI positive-signal"**
  - **NEW positive-signal convention** (AliasVault 1st formally)
- **AGPL LIKELY**:
  - Check LICENSE — if AGPL: **20th AGPL-network-service-disclosure**
- **INSTITUTIONAL-STEWARDSHIP**: lanedirt creator + Discord + OC + Crowdin + cloud-parallel + E2E-tested. **101st tool 🎯 101-TOOL** in institutional-stewardship family.
  - **NEW sub-tier: "single-creator-with-community-triple-infrastructure"** (1st — AliasVault)
- **TRANSPARENT-MAINTENANCE**: active + CI + Discord + OC + Crowdin + docs + cloud-parallel + releases + E2E-tests. **109th tool in transparent-maintenance family.**
- **PASSWORD-MGR-CATEGORY:**
  - **AliasVault** — PW + email-alias COMBINED + E2E + self-hosted
  - **Bitwarden / Vaultwarden** — PW only; mature; E2E
  - **KeePass (+ variants)** — local file; most-conservative
  - **1Password** (commercial) — E2E; closed source
  - **ProtonPass** — E2E; closed source
  - **SimpleLogin** — alias-only (no PW)
  - **AnonAddy** — alias-only (no PW)
- **ALTERNATIVES WORTH KNOWING:**
  - **Vaultwarden + SimpleLogin + self-hosted-mail** — if you want separation
  - **Bitwarden + ProtonMail** — if you want cloud + proven
  - **Choose AliasVault if:** you want ALL-IN-ONE + self-hosted + E2E + own email.
- **PROJECT HEALTH**: active + community-rich + E2E-tested + cloud-parallel + mobile-apps + docs. EXCELLENT.

## Links

- Repo: <https://github.com/aliasvault/aliasvault>
- Docs: <https://docs.aliasvault.net>
- Cloud: <https://app.aliasvault.net>
- Vaultwarden (alt): <https://github.com/dani-garcia/vaultwarden>
- SimpleLogin (alt): <https://github.com/simple-login/app>
