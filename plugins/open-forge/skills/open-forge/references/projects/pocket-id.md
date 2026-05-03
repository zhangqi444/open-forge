---
name: Pocket ID
description: "Simple, passkey-only OIDC provider for self-hosters. 'Keycloak but tiny, and no passwords ever'. Web UI for users + apps; OIDC clients for any self-hosted service. WebAuthn/passkey authentication only. Go + SvelteKit + SQLite. MIT."
---

# Pocket ID

Pocket ID is a **simple, passkey-only, self-hosted OIDC provider**. Set it up once, connect all your self-hosted services (Immich, Nextcloud, Jellyfin, Grafana, Gitea, Portainer, anything supporting OIDC) → log in everywhere with a passkey (touch-ID / face-ID / YubiKey / Windows Hello). **No passwords in your life**, across all your self-hosted services.

The pitch vs alternatives:

- **Keycloak** — powerful but complex (realms, clients, roles, groups, adapters, Wildfly). Overkill for homelab / small team.
- **ORY Hydra** — library-first; you bring your own UI. Not a drop-in user-facing SSO.
- **Authelia / Authentik** — great, broader feature sets, more complex. Passwords + TOTP + LDAP + more.
- **Pocket ID** — passkey-only, minimal, dead-simple. You lose flexibility (no LDAP, no password, no TOTP fallback); you gain zero password risk + simple setup.

Who it's for:

- Homelab users who want SSO across a dozen services
- Small teams that fully embrace passkeys
- "Just me and my family" setups — 2-10 users max

Features:

- **Passkey-only** (WebAuthn) — YubiKey, Windows Hello, Face ID, Touch ID, iCloud Keychain
- **OIDC provider** — authorization code flow + PKCE
- **Multi-user** — invite users, manage in admin UI
- **Groups** — for role-based scopes
- **Audit logs**
- **Backup / restore** — export/import all data as a single file
- **Custom branding** (colors, logo)
- **API** — REST
- **Docker-first** deployment
- **SQLite** by default — single file, zero DB setup

- Upstream repo: <https://github.com/pocket-id/pocket-id>
- Website: <https://pocket-id.org>
- Docs: <https://docs.pocket-id.org>
- Demo: <https://demo.pocket-id.org>

## Architecture in one minute

- **Go** backend (single binary)
- **SvelteKit** frontend (bundled)
- **SQLite** (default) or **Postgres** (optional for HA)
- **No external dependencies** beyond a DB
- **Resource**: ~50 MB RAM, negligible CPU
- **Great fit for Pi**, tiny VPS, etc.

## Compatible install methods

| Infra          | Runtime                                          | Notes                                                          |
| -------------- | ------------------------------------------------ | -------------------------------------------------------------- |
| Single host    | **Docker** (upstream official)                       | **The way**                                                        |
| Bare metal     | Go binary                                                | Runs as systemd service                                              |
| Raspberry Pi   | arm64 Docker / binary                                        | Lightweight; works great                                                   |
| Kubernetes     | Small manifest                                                     | Works                                                                            |

## Inputs to collect

| Input              | Example                            | Phase      | Notes                                                          |
| ------------------ | ---------------------------------- | ---------- | -------------------------------------------------------------- |
| Domain             | `id.example.com`                     | URL        | **Public + HTTPS is mandatory** for WebAuthn to work                |
| TLS                | Let's Encrypt                            | Security   | **Required** — passkeys don't work without HTTPS                          |
| Admin email        | set via env or first-boot wizard             | Bootstrap  | Becomes first admin                                                          |
| Passkey device     | YubiKey / Face ID / Touch ID / Windows Hello    | Auth       | You MUST register at least one before logging out                                    |
| App integrations   | OIDC clients (per service)                               | Integration| Each service = one OIDC client config                                                    |
| Database           | SQLite (default) or Postgres                                   | Storage    | SQLite is fine for <100 users                                                                            |

## Install via Docker Compose

```yaml
services:
  pocket-id:
    image: ghcr.io/pocket-id/pocket-id:v2.6.2   # pin specific version
    container_name: pocket-id
    restart: unless-stopped
    environment:
      PUBLIC_APP_URL: https://id.example.com
      TRUST_PROXY: "true"
      # DB (SQLite default; set for Postgres)
      # DB_PROVIDER: postgres
      # DB_CONNECTION_STRING: postgres://user:pass@db/pocket_id?sslmode=disable
      MAXMIND_LICENSE_KEY: <optional>           # for IP geolocation in logs
    volumes:
      - ./data:/app/backend/data
    ports:
      - "1411:1411"
```

Front with Caddy/Traefik/nginx for TLS.

## First boot

1. Browse `https://id.example.com/`
2. First-time wizard → create admin account
3. **Register a passkey** — YubiKey (plug+touch) or platform authenticator (Face ID / Touch ID / Windows Hello)
4. **Register a second passkey** — recovery (different device!). **Do NOT skip this.** Losing your only passkey = locked out of Pocket ID = locked out of every service you connected.
5. Admin panel → Applications → + Add → configure OIDC for first service (e.g., Immich)
6. Each app: note Client ID + Client Secret → paste into that app's OIDC settings
7. Log out of Pocket ID → log back in with passkey (test the flow)
8. Try OIDC login to your integrated app

## Configuring an OIDC app (example: Immich)

In Pocket ID admin:

- Create new client "Immich"
- Callback URL: `https://photos.example.com/auth/login`
- Logout URL: `https://photos.example.com/`
- Scopes: `openid profile email`
- Copy Client ID + Client Secret

In Immich settings:

- Enable OAuth → Issuer URL `https://id.example.com/`
- Client ID: paste
- Client Secret: paste
- Save → log out → log in via "Sign in with Pocket ID"

Repeat pattern for every OIDC-supporting service.

## Data & config layout

- `data/` — SQLite DB + uploaded files (logos, branding)
- If using Postgres: external DB, `data/` only holds config

## Backup

```sh
# Stop during backup for consistency
docker compose stop pocket-id
tar czf pocket-id-$(date +%F).tgz data/
docker compose start pocket-id

# Pocket ID also has an in-app backup feature: Admin → Backup → download .zip
```

**Back up before every upgrade.** Losing the DB = every user must re-register passkeys + every app's OIDC setup must be recreated.

## Upgrade

1. Releases: <https://github.com/pocket-id/pocket-id/releases>. Active.
2. **Back up data first** (or use the in-app backup).
3. Bump image tag → `docker compose pull && docker compose up -d`.
4. Migrations run on boot.
5. Read release notes — early-project breaking changes possible.

## Gotchas

- **HTTPS is MANDATORY.** WebAuthn (passkeys) does not work over plain HTTP — browsers refuse. You MUST deploy Pocket ID behind TLS (Let's Encrypt + reverse proxy). No workaround.
- **Register AT LEAST TWO passkeys per user.** The "I lost my phone and my YubiKey is at work" scenario is real. Require a hardware key + a platform passkey (e.g., Windows Hello on desktop + YubiKey as backup) per account.
- **Admin recovery if you lose ALL passkeys**: there's a CLI recovery command to re-add an admin. Document it + test it in advance. Without it, you're rebuilding from backups.
- **Passkey-only = no SMS, no TOTP, no email link fallback by design.** Users who aren't passkey-fluent need hand-holding for enrollment. Plan for family/team member onboarding.
- **Passkey portability**:
  - iCloud Keychain syncs across Apple devices automatically
  - Google Password Manager syncs across Android + Chrome
  - 1Password / Bitwarden / Keeper sync across platforms
  - YubiKey / hardware keys = per-device (register separately on each account)
- **Browser support** — all modern browsers (Chrome 67+, Firefox 60+, Safari 14+, Edge 79+). Old corporate browsers = no.
- **Public key must match domain** — if you change domain, existing passkeys invalidate. Plan for domain stability.
- **Relying Party ID (RP ID)**: set to the apex domain (`example.com`) to allow multiple subdomain apps to share passkeys. Bootstrap this correctly at install.
- **Multi-device login UX**: "I want to log in from my desktop but my passkey is on my phone" → passkey providers (Apple/Google/1Password) offer cross-device QR flow. It works; users need to be taught.
- **Audit logs** include IP + user-agent; enable + monitor for unexpected logins.
- **Groups + scopes** — currently simple (admin vs user, plus groups). If you need fine-grained RBAC, look at Authelia/Authentik.
- **No LDAP / no AD sync** — Pocket ID is standalone; not designed to federate with corporate identity.
- **No SAML** — OIDC only. Services that only speak SAML (old corporate apps) need a different IdP.
- **No password fallback** — some services (Gitea, Nextcloud, Jellyfin) keep local passwords active by default when you also add OIDC. Disable local login if you want Pocket ID to be the only path.
- **v2.x major upgrade** — v2.6.2 is current; v1→v2 is a major version change. Back up database before upgrading and read upstream release notes.
- **Commercial use**: MIT license is permissive; OK for companies.
- **Alternatives worth knowing:**
  - **Keycloak** — feature-rich enterprise SSO; complex (separate recipe)
  - **Authelia** — YAML-configured auth with 2FA; broader than Pocket ID (separate recipe)
  - **Authentik** — Keycloak-alternative with broader flows and LDAP/SAML; heavier (separate recipe)
  - **ORY Hydra / Kratos** — library-first; you bring UI
  - **Zitadel** — modern OIDC + OAuth server
  - **FusionAuth** — commercial free tier
  - **Dex** — federating OIDC; works with other IdPs
  - **Choose Pocket ID if:** you want passkey-only, dead-simple SSO for <20 users + <20 apps.
  - **Choose Authelia if:** you want broader auth (TOTP, LDAP, 2FA fallback).
  - **Choose Authentik if:** you want a Keycloak-ish feature set with a modern UI.
  - **Choose Keycloak if:** you need enterprise features + have ops capacity.

## Links

- Repo: <https://github.com/pocket-id/pocket-id>
- Website: <https://pocket-id.org>
- Docs: <https://docs.pocket-id.org>
- Demo: <https://demo.pocket-id.org>
- Releases: <https://github.com/pocket-id/pocket-id/releases>
- Docker image: <https://ghcr.io/pocket-id/pocket-id>
- OIDC spec: <https://openid.net/specs/openid-connect-core-1_0.html>
- WebAuthn spec: <https://www.w3.org/TR/webauthn-2/>
- Passkeys explainer: <https://www.passkeys.io>
- Keycloak alternative: <https://www.keycloak.org>
- ORY Hydra alternative: <https://www.ory.sh/hydra/>
