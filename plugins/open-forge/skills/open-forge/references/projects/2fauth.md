---
name: 2FAuth
description: "Self-hosted web-based 2FA TOTP/HOTP/Steam-Guard code generator — Google Authenticator/Authy alternative. QR-scan, manual entry, WebAuthn login, DB encryption. Single-user-by-design. Laravel. AGPL-3.0."
---

# 2FAuth

2FAuth is **"your 2FA codes, in a web app you own"** — a self-hosted web application that stores your TOTP / HOTP / Steam Guard seeds, generates the 6-digit codes in the browser, and works on mobile + desktop. An alternative to Google Authenticator, Authy, Microsoft Authenticator — without the phone-lock-in + cloud-sync-to-a-vendor anxiety. The pitch: **"did you ever lose a phone with all your 2FA codes in Google Authenticator? I did. So I built this."**

Built + maintained by **Bubka** (solo). **AGPL-3.0**. Laravel backend + Vue-ish frontend. **Single-user by design** — not a team / multi-user product.

**Important threat-model context:** storing 2FA seeds on a server defeats one purpose of 2FA (out-of-band second factor). If an attacker gets BOTH your password manager AND your 2FAuth backup, they get everything. **2FAuth is for CONVENIENCE, not for max security.** For max-security personal 2FA: keep seeds on a dedicated hardware token (YubiKey) or an offline-only authenticator app. For everyday convenience with desktop + mobile access: 2FAuth is a reasonable tradeoff that the author acknowledges.

Use cases: (a) **desktop-user** tired of picking up phone for every login (b) **multi-device access** to same 2FA accounts (c) **phone-loss resilient backup** — DB is portable + restorable (d) **self-hosted privacy** vs Authy's account-based sync (e) **personal + low-to-medium-sensitivity threat model**.

Features:

- **TOTP + HOTP + Steam Guard** code generation
- **RFC-compliant** (RFC 4226 HOTP, RFC 6238 TOTP via Spomky-Labs/OTPHP)
- **QR scan** (camera + uploaded image) + manual entry
- **Edit imported accounts**
- **Groups** for organization
- **WebAuthn / security-key login** (YubiKey, Titan) — can DISABLE password login entirely
- **Data encryption at rest** — optional; protects DB from db-compromise
- **Auto-logout** after inactivity
- **Import from**: Google Auth (QR), Aegis, 2FAS Auth, 2FAuth JSON
- **Single-user enforced** — no multi-tenant
- **i18n** (English + French; Crowdin for contributions)
- **Mobile + desktop responsive UI**

- Upstream repo: <https://github.com/Bubka/2FAuth>
- Docs: <https://docs.2fauth.app>
- Self-hosted install: <https://docs.2fauth.app/getting-started/installation/self-hosted-server/>
- Docker install: <https://docs.2fauth.app/getting-started/installation/docker/docker-compose/>
- Upgrade guide: <https://docs.2fauth.app/getting-started/upgrade/>
- Import guide: <https://docs.2fauth.app/getting-started/usage/import/>
- Demo: <https://demo.2fauth.app> (`demo@2fauth.app` / `demo`)
- OTPHP library: <https://github.com/Spomky-Labs/otphp>
- Translations (Crowdin): <https://crowdin.com/project/2fauth>

## Architecture in one minute

- **Laravel (PHP 8.4+)** backend
- **DB** — any Laravel-supported (SQLite default; MySQL / Postgres also)
- **Single-container** Docker image
- **Resource**: small — 150-300MB RAM
- **Port 8000** default (via `php artisan serve`) or 80 in Docker

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Docker Compose     | `2fauth/2fauth` / docker-compose path                           | **Upstream-primary**                                                               |
| Docker (CLI)       | Single `docker run`                                                       | Fine for quick trial                                                                       |
| Self-hosted server | PHP-FPM + nginx/Apache + DB                                                            | Documented                                                                                 |
| Heroku             | Upstream-provided                                                                                   | Supported                                                                                             |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `2fa.example.com`                                           | URL          | **TLS MANDATORY** — 2FA seeds in transit = disaster                                                                         |
| `APP_KEY`            | `php artisan key:generate`                                                    | Secret       | **IMMUTABLE** — rotating destroys access to encrypted 2FA seeds                                                                              |
| DB                   | SQLite default / MySQL / Postgres                                                    | DB           | SQLite fine for single-user                                                                                                |
| Data encryption      | Optional but **strongly recommended**                                                                            | Setup        | Encrypts DB-stored 2FA seeds; controlled by `APP_KEY`                                                                                                          |
| First admin user     | Created on first access                                                                                              | Bootstrap    | Single-user — only ONE account allowed                                                                                                                      |
| WebAuthn (opt)       | YubiKey / Titan / platform-auth                                                                                                                   | Auth         | Can replace password login entirely                                                                                                                                  |

## Install via Docker Compose

Per <https://docs.2fauth.app/getting-started/installation/docker/docker-compose/>. Minimal:

```yaml
services:
  2fauth:
    image: 2fauth/2fauth:latest              # **pin version** in prod
    restart: unless-stopped
    environment:
      APP_NAME: 2FAuth
      APP_KEY: ${APP_KEY}                     # php artisan key:generate
      SITE_OWNER: you@example.com
      APP_URL: https://2fa.example.com
      IS_DEMO_APP: "false"
      ENABLE_CREDENTIAL_BROKER: "true"        # WebAuthn
    volumes:
      - ./2fauth-data:/2fauth
    ports: ["8000:8000"]
```

**Always run behind TLS** — seeds in plaintext over HTTP = catastrophic.

## First boot

1. Deploy → browse URL → create YOUR account (single-user — register once)
2. Settings → enable **Data Encryption** BEFORE adding any 2FA accounts (encrypts seeds at rest)
3. Settings → set up WebAuthn security key (optional but recommended)
4. Add 2FA accounts: scan QR from services, or import from Google Auth / Aegis / 2FAS
5. Test: verify code matches what the service expects
6. Backup: export 2FAuth JSON + back up APP_KEY separately
7. Put behind TLS reverse proxy + strict IP allowlist if possible
8. Consider: dedicated subdomain + no path-based prefix (simpler TLS)

## Data & config layout

- **DB** (SQLite / MySQL / Postgres) — 2FA seeds (encrypted at rest if enabled)
- **`.env`** — `APP_KEY` + SMTP + other config
- **Uploaded QR images** (if any) — stored on filesystem
- **WebAuthn creds** — stored in DB

## Backup

```sh
# DB
docker exec 2fauth sqlite3 /2fauth/database/database.sqlite ".backup /2fauth/backup.db"
# Or mysqldump / pg_dump for external DB

# APP_KEY / .env — CRITICAL
sudo cp .env .env-$(date +%F).backup

# Export via UI → Settings → Export → JSON (keeps seeds decrypted)
# Store both backups in a SEPARATE, SECURE location (password manager's secure notes; offline encrypted drive)
```

**If you lose `APP_KEY` AND all decrypted exports, your 2FA seeds are gone forever.** Re-setup every 2FA on every service.

## Upgrade

1. Releases: <https://github.com/Bubka/2FAuth/releases>. Active cadence.
2. Docker: bump tag; migrations run on boot.
3. **Back up DB + APP_KEY FIRST.** Always.
4. Follow <https://docs.2fauth.app/getting-started/upgrade/> for major versions.

## Gotchas

- **`APP_KEY` IMMUTABILITY — this is THE critical secret.** Laravel `APP_KEY` is used to encrypt the 2FA seeds in the database. **Rotating APP_KEY without re-encrypting = PERMANENT LOSS of all stored 2FA accounts.** Back it up separately from the DB. **10th tool in immutability-of-secrets family** (Black Candy, Lychee, Forgejo, Fider, FreeScout, Nexterm, Wakapi, Statamic, Vikunja, PMS — now +2FAuth). **Crown-jewel tier.** Same Laravel-APP_KEY pattern as Statamic (77), FreeScout (82), Lychee (83).
- **TLS MANDATORY — no exceptions.** If your 2FA seeds transit in cleartext ONCE, assume they're compromised. `http://` 2FAuth deployments are actively dangerous. Let's Encrypt + reverse proxy; don't rely on "it's only my LAN" — your LAN has IoT devices, guest phones, maybe a compromised router.
- **Self-hosted 2FA THREAT-MODEL tradeoff** — honest framing:
  - **vs Google Authenticator on phone**: 2FAuth is **less secure** (seeds on a server you admin; attackable at network + app + DB layers) BUT **more resilient** (lose phone, DB still has seeds). Different risk profile.
  - **vs Authy**: 2FAuth is **more private** (no vendor sync) BUT **requires your infra**.
  - **vs YubiKey hardware**: 2FAuth is **vastly less secure** (software vs tamper-resistant hardware) BUT **vastly more convenient** (no hardware token to lose / travel with).
  - **Choose deliberately.** For high-value accounts (bank, email, cloud-admin), YubiKey > 2FAuth. For convenience (Netflix, Reddit), 2FAuth is great.
- **Storing 2FA on the SAME machine as your password manager = concentration risk.** If the threat is "compromise of my server", both get stolen. Consider: 2FAuth on a DIFFERENT host than your Vaultwarden; or keep the highest-value 2FA codes on a dedicated hardware token instead.
- **Data encryption is OPTIONAL + off by default.** **ENABLE IT FIRST.** Without DB encryption, anyone with read access to the DB file (backup, accidental leak, compromised host) has all your 2FA seeds in plaintext. Setting is in app settings; takes effect on next-added account (existing accounts need re-encrypt).
- **Single-user enforcement** — upstream blocks creating a second user on the same instance. If you want multi-user 2FA storage, deploy one instance per user. Same single-tenant assumption as PMS (this batch).
- **WebAuthn-only login mode** is a powerful hardening option: disable the password login form entirely + require YubiKey/Titan/platform-auth. After your YubiKey + backup YubiKey are set up, remove the password path. **Keep backup WebAuthn credentials + exported JSON in case both keys are lost.**
- **Auto-logout on copy** option: when enabled, after you copy a 2FA code, the app logs you out. Reduces accidental "forgot to log out" exposure on shared devices. Worth enabling.
- **Import from Google Authenticator** is well-supported via QR-code export (Google Auth → Export → QR). Straightforward migration path.
- **AGPL-3.0 license** — same AGPL family as Synapse, Papra, Forgejo, MiroTalk, etc. Self-hosting privately = fine; running 2FAuth-as-a-service for others requires upstream-compliance.
- **Provider/service dependence**: 2FAuth generates codes correctly only if the service's 2FA setup is standard TOTP/HOTP. Some services (Amazon, certain banks) use proprietary flows that 2FAuth can't handle; fall back to their native app.
- **Steam Guard** support is an unusual + welcome feature (Steam uses a nonstandard TOTP variant). Not all authenticators do this.
- **Backup-rehearsal discipline** — **TEST YOUR BACKUPS** by restoring to a clean instance and verifying a code matches what the service expects. A backup you've never restored = not a backup.
- **Project health**: Bubka solo + active + AGPL + well-documented + translation contributions + Crowdin. Bus-factor-1 mitigated by (a) clean Laravel codebase (b) standard OTP protocols (RFC-compliant) — data is portable out of 2FAuth into any standards-compliant authenticator.
- **Alternatives worth knowing:**
  - **Aegis Authenticator** (Android, GPLv3) — offline-only, encrypted backups, F-Droid — **highest-privacy mobile option**
  - **Raivo OTP** (iOS, discontinued)
  - **Ente Auth** — open-source cross-platform with E2E encrypted sync (Ente Inc.)
  - **Vaultwarden / Bitwarden** — stores TOTP codes alongside passwords (convenience + concentration-risk combined)
  - **KeePassXC** — desktop password + TOTP
  - **YubiKey / Titan** — hardware-based second factor
  - **Google Authenticator / Authy / Microsoft Authenticator** — commercial SaaS
  - **Choose 2FAuth if:** you want self-hosted web-based TOTP + desktop convenience + AGPL.
  - **Choose Aegis if:** Android + want max-privacy + offline-only.
  - **Choose Ente Auth if:** you want cross-device E2E-encrypted sync without self-hosting.
  - **Choose YubiKey if:** high-value accounts + max security.

## Links

- Repo: <https://github.com/Bubka/2FAuth>
- Docs: <https://docs.2fauth.app>
- Install (self-hosted): <https://docs.2fauth.app/getting-started/installation/self-hosted-server/>
- Install (Docker Compose): <https://docs.2fauth.app/getting-started/installation/docker/docker-compose/>
- Upgrade: <https://docs.2fauth.app/getting-started/upgrade/>
- Import: <https://docs.2fauth.app/getting-started/usage/import/>
- Demo: <https://demo.2fauth.app>
- OTPHP library: <https://github.com/Spomky-Labs/otphp>
- Aegis (alt, Android): <https://getaegis.app>
- Ente Auth (alt, cross-platform): <https://ente.io/auth>
- Vaultwarden (alt, password manager + TOTP): <https://github.com/dani-garcia/vaultwarden>
- YubiKey: <https://www.yubico.com>
