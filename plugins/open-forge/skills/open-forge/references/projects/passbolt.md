---
name: Passbolt
description: "Security-first open-source password manager for teams. User-owned secret keys + end-to-end encryption (OpenPGP). Annually audited, public findings. PHP/CakePHP + MariaDB. EU-headquartered (Luxembourg). AGPL-3.0 (Community); commercial Pro."
---

# Passbolt

Passbolt is **the security-first, open-source team password manager** — distinct from consumer managers like Bitwarden/Vaultwarden in its **user-owned secret key model** (OpenPGP) and explicit focus on **team/org credentials sharing**. Each user generates their own GPG key; Passbolt never sees plaintext secrets; sharing is via OpenPGP-encrypted envelopes per-recipient.

**Key differentiators:**

- **User-owned OpenPGP keys** (not derived from master password) — a familiar crypto model for security-first teams
- **Headquartered in EU (Luxembourg)** — GDPR-native, no US-jurisdiction issues
- **Annual security audits** — findings published publicly
- **No telemetry / no personal data collection**
- **Works in air-gapped deployments**

Features:

- **Team password manager** — shared passwords with fine-grained permissions (Read/Update/Owner)
- **Groups** — org hierarchy; inherit permissions
- **Folders** (Pro) — nested organization
- **Browser extensions** — Chrome, Firefox, Edge, Brave (required for daily use — not just web app)
- **Mobile apps** — iOS, Android
- **Desktop app** — macOS, Windows, Linux
- **CLI** — for automation
- **Password generator**
- **Audit logs** — who accessed what
- **SSO** — OIDC/SAML/AD (Pro)
- **Directory sync** — LDAP/AD (Pro)
- **MFA** — TOTP + YubiKey + Duo (Pro)
- **Passkey / WebAuthn** support (evolving)
- **Self-hosted** Community Edition + commercial Pro

- Upstream (API server): <https://github.com/passbolt/passbolt_api>
- Client (web frontend / extensions): <https://github.com/passbolt/passbolt_styleguide>
- Website: <https://www.passbolt.com>
- Docs: <https://www.passbolt.com/docs>
- Security (code review findings): <https://help.passbolt.com/faq/security/code-review>
- Community: <https://community.passbolt.com>
- Roadmap: <https://community.passbolt.com/c/roadmap>
- Discord: <https://community.passbolt.com/t/passbolt-on-discord>

## Architecture in one minute

- **PHP/CakePHP** server (API + admin)
- **MariaDB/MySQL** (primary DB)
- **JavaScript** client (web UI + browser extensions)
- **Server-side GPG** for verifying signatures (server has its own key + user public keys)
- **Client-side GPG** for encryption/decryption (user's private key lives in browser extension)
- **HTTPS mandatory** — passwords cross the wire encrypted but TLS is required architecture-wide

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Single VM          | **Native on Ubuntu/Debian/RHEL** via official repos                | **Upstream-recommended**                                                           |
| Single VM          | **Docker Compose** (`passbolt/passbolt` image)                                  | Well-documented                                                                                |
| Single VM          | Snap / distro package                                                                       | Ubuntu native                                                                                               |
| Kubernetes         | Helm chart + community manifests                                                                           | Supported                                                                                                                |
| Managed            | **Passbolt Cloud** (SaaS, Pro only)                                                                                      | Paid hosted                                                                                                                             |

## Inputs to collect

| Input                 | Example                                | Phase       | Notes                                                                   |
| --------------------- | -------------------------------------- | ----------- | ----------------------------------------------------------------------- |
| Domain                | `passbolt.example.com`                       | URL         | **Do not change later** — tied to server GPG key fingerprint                    |
| TLS                   | Let's Encrypt                                    | Security    | **Mandatory** — extensions refuse cleartext                                                 |
| DB                    | MariaDB                                             | DB          | Bundled or external                                                                              |
| Server GPG key        | generated on install                                       | Crypto      | Server identity — **back up + treat like CA key**                                                                    |
| Admin account         | created via `cake passbolt register_user --admin`                     | Bootstrap   | First user via CLI                                                                                                       |
| SMTP                  | for invites + password resets                                          | Email       | **Critical** — new users invited via signed email link                                                                                                          |
| SSO (Pro)             | OIDC/SAML/AD config                                                              | Auth        | Commercial tier                                                                                                                                       |

## Install via Docker Compose (Community)

Upstream's Docker repo has a prod compose. Abbreviated:

```yaml
services:
  db:
    image: mariadb:10.11
    environment:
      MYSQL_RANDOM_ROOT_PASSWORD: "true"
      MYSQL_DATABASE: passbolt
      MYSQL_USER: passbolt
      MYSQL_PASSWORD: CHANGE_ME
    volumes:
      - ./db:/var/lib/mysql
  passbolt:
    image: passbolt/passbolt:latest-ce                # use versioned tag in prod
    restart: unless-stopped
    depends_on:
      - db
    environment:
      APP_FULL_BASE_URL: https://passbolt.example.com
      DATASOURCES_DEFAULT_HOST: db
      DATASOURCES_DEFAULT_USERNAME: passbolt
      DATASOURCES_DEFAULT_PASSWORD: CHANGE_ME
      DATASOURCES_DEFAULT_DATABASE: passbolt
      EMAIL_TRANSPORT_DEFAULT_HOST: smtp.example.com
      EMAIL_TRANSPORT_DEFAULT_PORT: 587
      EMAIL_TRANSPORT_DEFAULT_USERNAME: mailuser
      EMAIL_TRANSPORT_DEFAULT_PASSWORD: CHANGE_ME
      EMAIL_DEFAULT_FROM: "Passbolt <no-reply@example.com>"
    volumes:
      - ./gpg:/etc/passbolt/gpg
      - ./jwt:/etc/passbolt/jwt
    ports:
      - "443:443"
```

Register admin on first boot:

```sh
docker compose exec passbolt su -m -c "/usr/share/php/passbolt/bin/cake passbolt register_user -u you@example.com -f You -l Name -r admin" -s /bin/sh www-data
```

You'll get a setup URL; open it in Chrome/Firefox with the Passbolt extension installed.

## First boot

1. Install Passbolt browser extension
2. Open the admin setup URL → extension generates your OpenPGP key → set passphrase (**write this down**)
3. Download recovery kit (contains private key + backup passphrase)
4. Log in → invite team members via email → each generates their own GPG key
5. Create first password → share with a colleague → verify encrypted-per-recipient model
6. Enable 2FA for your account
7. Configure audit log retention

## Data & config layout

- MariaDB — user metadata + encrypted password records
- `/etc/passbolt/gpg/` — server GPG keys (private + public)
- `/etc/passbolt/jwt/` — JWT signing keys
- Env vars — DB + SMTP + URL

## Backup

```sh
# DB (encrypted at rest — only user GPG keys can decrypt; but auth metadata is critical)
docker exec passbolt-db mysqldump -u passbolt -p$DB_PASS passbolt | gzip > passbolt-db-$(date +%F).sql.gz
# Server GPG + JWT keys (CRITICAL)
sudo tar czf passbolt-keys-$(date +%F).tgz gpg/ jwt/
```

**Without the server GPG key**: users can still decrypt their own passwords (via client extension), but server-side signature verification breaks; Passbolt won't start. Back up offline.

## Upgrade

1. Releases: <https://github.com/passbolt/passbolt_api/releases>. Active; regular.
2. Read release notes carefully — major versions have migration steps.
3. Docker: bump tag → restart → migrations auto. **Back up DB + keys first**.
4. Extensions auto-update via browser.

## Gotchas

- **Browser extension is required for daily use.** Unlike Bitwarden's web vault, Passbolt's security model depends on client-side GPG in the extension. Web-only access is limited.
- **Users own their private keys.** If a user loses their private key + passphrase + recovery kit, *their shared passwords are decryptable only by them* — admin cannot recover them. This is the security model, not a bug. Teach users to keep their recovery kit safe.
- **Team onboarding is an explicit ceremony** — generate key, set passphrase, save recovery kit. Budget 10-15 min for each new hire.
- **Domain change after install** breaks GPG key fingerprints + users' saved setups. **Choose URL carefully up front.** Similar to Pixelfed federation domain + MeshCentral agent-trust-FQDN precedents.
- **Server GPG key is critical** — loss + DB corruption = end of Passbolt instance. Back up keys offline + multiple locations.
- **HTTPS mandatory** — extensions validate TLS; self-signed = disable cert pinning in browser = degraded trust.
- **Email deliverability**: invites rely on SMTP; delivery problems = new users can't onboard. Use transactional SMTP provider (SendGrid/Mailgun/SES).
- **Community Edition vs Pro**: CE has the core password management; Pro adds SSO, MFA (YubiKey/Duo), directory sync, folders, tags, advanced audit, priority support.
- **License**: Community Edition is **AGPL-3.0**; Pro is proprietary commercial.
- **Air-gap deployment** is officially supported — one of the few password managers that advertises this.
- **Audit log**: valuable for compliance (SOC 2 / ISO 27001). Configure retention per policy.
- **Not great for personal single-user use** — the ceremony + team-sharing architecture is overkill. Use Bitwarden/Vaultwarden or Keepass for personal.
- **Mobile apps**: iOS + Android; both require initial QR-code key import from browser extension.
- **Desktop app** (electron) — feature-complete; convenient for those who avoid browser extensions.
- **Rotate server keys** every few years per security best practice; migration tooling exists.
- **Don't lose your admin**: at least 2 admin accounts from day 1, so if one gets locked out the other can recover/unblock.
- **Password-sharing workflow**: when sharing, extension encrypts the secret once per recipient using their public key. Transparent + strong model; slightly slower than "insert into DB" for large teams.
- **Passkey / WebAuthn**: roadmap item; check current status.
- **Alternatives worth knowing:**
  - **Bitwarden / Vaultwarden** — easier to use; zero-knowledge but not user-owned-key model (separate recipe likely for Vaultwarden)
  - **KeePassXC** — desktop-only; file-based
  - **1Password / LastPass / Dashlane** — commercial SaaS
  - **Proton Pass** — new; Proton ecosystem
  - **Psono** — self-hostable enterprise; LGPL-3.0
  - **TeamPass** — old-school PHP team password manager
  - **HashiCorp Vault / OpenBao** — secrets management, different target (see batch 67 OpenBao recipe)
  - **Choose Passbolt if:** team password manager + security-first + EU data jurisdiction + user-owned PGP keys matter.
  - **Choose Vaultwarden if:** you want Bitwarden UX + easier onboarding + broader client ecosystem.
  - **Choose OpenBao if:** secrets for applications (not humans).
  - **Choose KeePassXC if:** personal + offline.

## Links

- Server repo: <https://github.com/passbolt/passbolt_api>
- Client repo: <https://github.com/passbolt/passbolt_styleguide>
- Website: <https://www.passbolt.com>
- Docs: <https://www.passbolt.com/docs>
- Installation (Docker): <https://www.passbolt.com/docs/hosting/install/ce/docker/>
- Installation (bare-metal): <https://www.passbolt.com/docs/hosting/install/ce/>
- Releases: <https://github.com/passbolt/passbolt_api/releases>
- Browser extensions: <https://www.passbolt.com/download>
- Security audits / code review: <https://help.passbolt.com/faq/security/code-review>
- Community forum: <https://community.passbolt.com>
- Pro / Cloud: <https://www.passbolt.com/pricing>
- Vaultwarden (alt): <https://github.com/dani-garcia/vaultwarden>
- Bitwarden (alt): <https://bitwarden.com>
- OpenBao (alt — app secrets): see batch 67 recipe
