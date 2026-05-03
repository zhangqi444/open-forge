---
name: Password Pusher
description: "Self-hosted secure ephemeral sharing of passwords, text, files, URLs. Self-deleting one-time links with expiry by views/time + audit log + MFA. Ruby on Rails. Pglombardo + pwpush.com hosted. OSS license (BSD-Anti-Malware)."
---

# Password Pusher

Password Pusher is **"a secure self-destructing link for passwords/secrets/files"** — you push a secret (password, text, file, URL) to your Password Pusher instance and get a one-time link. Recipient clicks, views once (or N times), then it's gone. Encrypted at rest. Full audit log. Official hosted service at pwpush.com + self-hostable. Solves the "how do I send this password over chat?" problem (answer: you don't; you push it).

Built + maintained by **Peter Giacomo Lombardo (pglombardo)** + community + commercial backing (pwpush.com Pro tier). License: check repo (typically BSD-Anti-Malware). Active; v2.6 stable; docs at docs.pwpush.com; official CLI + Chrome extension; 31 languages; Docker/K8s/Helm deployments; MFA-required option.

Use cases: (a) **onboarding new hire** — send SSO/VPN/Wi-Fi creds without emailing them (b) **password resets** — helpdesk sends new password via expiring link (c) **MSP client credential handoff** — hand off server passwords to clients securely (d) **contractor access grants** — time-limited API key sharing (e) **secure file delivery** — PII documents to accountant/lawyer (f) **journalist source communication** — one-time tip files (g) **family password sharing** — streaming service / Wi-Fi with auto-expire (h) **security audit reports** — deliver pentest findings without persistent attack-surface.

Features (per README):

- **Encrypted at rest**
- **Expiry** by views + time
- **Passphrase protection** optional
- **MFA** (TOTP) with backup codes + `PWP__REQUIRE_MFA=true` for instance-wide
- **Audit logging** — full trail
- **Unbranded delivery page**
- **31 languages** + light/dark themes
- **JSON API** + **official CLI** + **Chrome extension**
- **Docker Compose** with automatic SSL/TLS
- **Database or ephemeral** (stateless mode)
- **Admin dashboard**
- **White-label** theming + 26 Bootswatch themes + custom CSS

- Upstream repo: <https://github.com/pglombardo/PasswordPusher>
- Hosted: <https://pwpush.com>
- Docs: <https://docs.pwpush.com>
- Docker: <https://hub.docker.com/r/pglombardo/pwpush>
- Chrome extension: <https://docs.pwpush.com/docs/chrome-extension/>
- CLI: <https://docs.pwpush.com/docs/cli/>
- v2.0 upgrade guide: <https://github.com/pglombardo/PasswordPusher/blob/master/UPGRADE-2.0.md>

## Architecture in one minute

- **Ruby on Rails** app
- **PostgreSQL / MySQL / SQLite** — DB (or ephemeral)
- **Redis** — optional (caching / rate-limiting)
- **Resource**: moderate — 300-500MB RAM (Rails-typical)
- **Port 5100** default

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Hosted**         | **pwpush.com**                                                  | **Zero-maintenance**                                                                        |
| **Docker Compose** | **`pglombardo/pwpush:latest`**                                  | **Primary self-host**                                                                        |
| Kubernetes         | Helm chart                                                       | K8s                                                                                   |
| Heroku             | One-click deploy                                                                    | Cloud                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `pwpush.example.com`                                        | URL          | **TLS MANDATORY** (receiving unencrypted secrets = defeating purpose)                                                                                    |
| DB                   | Postgres/MySQL/SQLite                                       | DB           |                                                                                    |
| `SECRET_KEY_BASE`    | Rails signing                                               | **CRITICAL** | **IMMUTABLE**                                                                                    |
| `PWP_MASTER_KEY`     | Encryption-at-rest key                                      | **CRITICAL** | **IMMUTABLE — losing it = all existing secrets unreadable**                                                                                    |
| Admin creds          | First-boot                                                                                 | Bootstrap    | Strong + MFA                                                                                    |
| SMTP                 | Optional for audit notifications                                                                                  | Email        |                                                                                                            |
| `PWP__REQUIRE_MFA=true` | Organization-wide MFA                                                                                                            | Security     | **STRONGLY RECOMMENDED**                                                                                                                            |

## Install via Docker

```yaml
services:
  pwpush:
    image: pglombardo/pwpush:v2.6.3        # **pin version — v2.0 breaking changes from v1**
    ports: ["5100:5100"]
    environment:
      DATABASE_URL: "postgresql://pwpush:${DB_PASSWORD}@db:5432/pwpush"
      SECRET_KEY_BASE: ${SECRET_KEY_BASE}
      PWP_MASTER_KEY: ${PWP_MASTER_KEY}
      PWP__REQUIRE_MFA: "true"
    depends_on: [db]

  db:
    image: postgres:17
    environment:
      POSTGRES_DB: pwpush
      POSTGRES_USER: pwpush
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes: [pgdata:/var/lib/postgresql/data]

volumes: {pgdata: {}}
```

## First boot

1. Start → browse `:5100`
2. Register admin; enable MFA immediately
3. Create first push; test delivery
4. Configure SMTP (for audit-log notifications)
5. Configure theme + logo (white-label)
6. Put behind TLS reverse proxy
7. Consider IP-allowlist for admin panel
8. Back up DB

## Data & config layout

- DB — pushes (encrypted-at-rest) + users + audit log
- `PWP_MASTER_KEY` — environment var; stored OUT of DB (encryption root)

## Backup

```sh
docker compose exec db pg_dump -U pwpush pwpush > pwpush-$(date +%F).sql
# PWP_MASTER_KEY must be backed up separately (encrypted in secrets manager)
```

## Upgrade

1. Releases: <https://github.com/pglombardo/PasswordPusher/releases>. Active; v2.0 MAJOR.
2. **v2.0 UPGRADE = READ UPGRADE-2.0.md FIRST** — breaking changes + config migration
3. Docker: pull + restart; migrations auto-run
4. Back up DB + `PWP_MASTER_KEY` before upgrade

## Gotchas

- **CROWN-JEWEL Tier 1 — CREDENTIAL-TRANSFER-SERVICE (13th tool)**:
  - Password Pusher's entire purpose is relaying credentials
  - Compromise = attacker can:
    - Read all active pushes (pre-expiry)
    - Read audit log (metadata about every credential shared)
    - Impersonate senders to malicious recipients
  - **64th tool in hub-of-credentials family — CROWN-JEWEL Tier 1 (13th tool)** — joins Octelium, Guacamole, Homarr, pgAdmin, WGDashboard, Lunar, Dagu, GrowChief, Mixpost, Vito, Sshwifty, Speakr
  - **NEW sub-category: "credential-transfer-service"** (Password Pusher 1st)
- **TLS = NON-NEGOTIABLE**:
  - Point of Password Pusher is secure delivery
  - HTTP = secrets-in-plaintext-on-network = WORSE than email (at least email has STARTTLS)
  - **Enforce HTTPS only**; HSTS; modern cipher suites; consider TLS 1.3-only
- **ENCRYPTION-AT-REST DEPENDS ON `PWP_MASTER_KEY`**:
  - Losing `PWP_MASTER_KEY` = ALL ENCRYPTED PUSHES ARE UNREADABLE (forever)
  - Changing `PWP_MASTER_KEY` without migration = same outcome
  - **Back up `PWP_MASTER_KEY` in a SECRETS MANAGER** (Bitwarden, 1Password, HashiCorp Vault, AWS Secrets Manager)
  - **Recipe convention: "master-encryption-key-immutability" callout** — CRITICAL for any at-rest-encryption tool
  - **NEW sub-convention** of immutability-of-secrets — **43rd tool in family** with SPECIAL encryption-key-class
- **MFA = MANDATORY FOR ADMIN**:
  - `PWP__REQUIRE_MFA=true` for instance-wide enforcement
  - Admin-without-MFA on a credential-transfer service = fundamental risk
- **AUDIT LOG = BOTH FEATURE + RISK**:
  - Audit log shows WHO shared WHAT with WHOM and WHEN
  - Critical for compliance + security incident review
  - BUT: audit log is itself sensitive metadata
  - Treat audit log with same protection as DB content
- **EPHEMERAL-MODE (NO-DB)**:
  - Rails app can run stateless (in-memory pushes only)
  - Restart = all pushes lost (by design)
  - Use case: minimize attack surface; accept that pushes die on restart
  - **Recipe convention: "ephemeral-mode-as-security-feature"** — intentional statelessness as threat-model reduction
  - **NEW positive-signal convention**
- **COMMERCIAL-TIER (pwpush.com)**:
  - Pro tier: customization, white-label, enterprise features
  - OSS self-host = fully-functional, no gated core features
  - **Commercial-tier-taxonomy: open-core-with-fully-functional-OSS** (Tianji 100 + Worklenz 100 precedents)
  - **50th tool in institutional-stewardship — 50-TOOL MILESTONE** 🎯 — founder-with-commercial-tier-funded-development sub-tier
- **CREDENTIAL LEAK BY VIEWED-BY-WRONG-RECIPIENT**:
  - Password Pusher doesn't authenticate recipients by default
  - Anyone with the link can view
  - **Mitigation**: passphrase-protection + IP-logging + short view-count
  - Use Signal/secure-messenger to send the LINK + passphrase via separate channels
- **EMAIL FORWARD RISK**:
  - Sender emails recipient the push URL
  - Email gets forwarded (accidentally or maliciously) → link usable by new recipient
  - **Mitigation**: passphrase + view-count=1 + short expiry; recipient accesses ASAP
- **ONE-VIEW MODEL EDGE-CASE**: browser prefetchers / email-scanner-preview-bots visit the URL first → secret consumed by bot → recipient sees "already viewed" error
  - Outlook's "Safe Links" feature is a known offender
  - Password Pusher has detection + workarounds
  - **Recipe convention: "email-prefetcher-anti-pattern" warning** — applies to all one-time-link tools
- **DATA-DESTRUCTION-ON-EXPIRY**:
  - README says "sensitive data is removed entirely once expired"
  - Verify this is TRUE via source audit (not just flagged as expired in DB)
  - Some tools "soft-delete" which ≠ cryptographic erasure
- **TRANSPARENT-MAINTENANCE**: active + v2.0-released + docs + CLI + Chrome-ext + 31-languages + commercial-tier-funded. **57th tool in transparent-maintenance family.**
- **SECRET_KEY_BASE IMMUTABILITY**: **43rd tool** (counted above with PWP_MASTER_KEY).
- **INSTITUTIONAL-STEWARDSHIP MILESTONE: 50 tools** 🎯 — founder-with-commercial-tier-funded-development.
- **SELF-HOST VS HOSTED pwpush.com**:
  - **Self-host**: max privacy, your infra, your audit log
  - **Hosted pwpush.com**: zero-maintenance, Pro tier features, but creator sees metadata
  - **Hybrid**: self-host the instance, use official CLI/Chrome extension
- **ALTERNATIVES WORTH KNOWING:**
  - **Bitwarden Send** — integrated with Bitwarden password manager
  - **1Password secure document sharing** — commercial
  - **Yopass** — OSS; Go; simpler
  - **snappass** — OSS; Python; simpler
  - **PrivateBin** — OSS; PHP; paste-oriented but similar concept
  - **sh.tsukiyo** — OSS; minimal
  - **onetimesecret.com** — hosted
  - **Vaultwarden Send** — Bitwarden-compatible + send feature
  - **Choose Password Pusher if:** you want comprehensive + Rails + MFA + audit + commercial-backed.
  - **Choose Yopass if:** you want simpler + Go.
  - **Choose PrivateBin if:** you want paste-oriented workflow.
  - **Choose Bitwarden Send if:** you're already Bitwarden-native.
- **PROJECT HEALTH**: active + v2.0 released + commercial-backed + CLI + Chrome-ext + comprehensive docs + active Discord + 31 languages. EXCELLENT signals.

## Links

- Repo: <https://github.com/pglombardo/PasswordPusher>
- Hosted: <https://pwpush.com>
- Docs: <https://docs.pwpush.com>
- Docker: <https://hub.docker.com/r/pglombardo/pwpush>
- v2.0 upgrade: <https://github.com/pglombardo/PasswordPusher/blob/master/UPGRADE-2.0.md>
- Yopass (alt): <https://github.com/jhaals/yopass>
- PrivateBin (alt): <https://privatebin.info>
- Bitwarden Send: <https://bitwarden.com/products/send/>
- Vaultwarden (Bitwarden-compatible): <https://github.com/dani-garcia/vaultwarden>
- snappass (alt): <https://github.com/pinterest/snappass>
- onetimesecret.com (hosted alt): <https://onetimesecret.com>
