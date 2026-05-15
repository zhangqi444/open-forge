---
name: VoidAuth
description: "Single sign-on + user management for self-hosted apps. OpenID Connect provider. ForwardAuth proxy. Passkeys, user invitation, self-registration, email. voidauth org. voidauth.app."
---

# VoidAuth

VoidAuth is **"Authelia / Authentik / Keycloak — but simpler + purpose-built for self-hosted"** — an SSO authentication + user management provider that stands guard in front of your self-hosted apps. Admin-friendly + end-user-friendly. Passkeys, user invitation, self-registration, email support.

Built + maintained by **voidauth** org. voidauth.app website. GitHub-Actions CI. Active releases.

Use cases: (a) **SSO for homelab apps** (b) **replace per-app authentication** (c) **ForwardAuth with nginx/Traefik** (d) **OIDC for self-hosted apps** (simpler than Keycloak) (e) **user invitations + self-reg flow** (f) **passkey-friendly auth** (g) **small-team SSO** (h) **family/household auth hub**.

Features (per README):

- **OpenID Connect (OIDC) Provider**
- **Proxy ForwardAuth**
- **Passkeys**
- **User invitation**
- **Self-registration**
- **Email support**

- Upstream repo: <https://github.com/voidauth/voidauth>
- Website: <https://voidauth.app>

## Architecture in one minute

- Likely Node.js or similar
- SQL database (SQLite probably)
- SMTP for email
- **Resource**: low — typical for auth service
- **Port**: web UI + OIDC endpoints

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | Upstream                                                        | **Primary** (per website)                                                                        |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `auth.example.com`                                          | URL          | **TLS MANDATORY — SSO = credential-path**                                                                                    |
| SMTP                 | For emails                                                  | Email        | Password-reset, invites                                                                                    |
| OIDC clients         | Per-app                                                     | Config       | One per downstream app                                                                                    |
| ForwardAuth config   | Reverse-proxy integration                                   | Config       | nginx/Traefik/Caddy                                                                                    |
| Admin bootstrap      | First-boot admin                                            | Bootstrap    | Strong                                                                                    |

## Install via Docker

See <https://voidauth.app/> for exact config. Typical:
```yaml
services:
  voidauth:
    image: voidauth/voidauth:1.12.4        # **pin version**
    ports: ["3000:3000"]
    volumes:
      - ./voidauth-data:/data
    environment:
      - SMTP_HOST=...
      - SMTP_USER=...
      - SMTP_PASS=${SMTP_PASS}
    restart: unless-stopped
```

Reverse-proxy ForwardAuth pattern (Traefik):
```yaml
# middleware snippet
middlewares:
  voidauth:
    forwardAuth:
      address: "http://voidauth:3000/api/forward-auth"
```

## First boot

1. Start; create admin via first-boot flow
2. Configure SMTP; send test email
3. Add OIDC client for first app
4. Configure app to trust VoidAuth as OIDC provider
5. Test login end-to-end
6. Enable passkey for admin
7. Configure self-reg if desired
8. Back up `/data`
9. **TLS mandatory**

## Data & config layout

- `/data/` — SQLite + configs

## Backup

```sh
sudo tar czf voidauth-$(date +%F).tgz voidauth-data/
# Contains password hashes + OIDC secrets + passkey credentials — **ENCRYPT**
```

## Upgrade

1. Releases: <https://github.com/voidauth/voidauth/releases>
2. Read release notes
3. Docker pull + restart

## Gotchas

- **159th HUB-OF-CREDENTIALS CROWN-JEWEL TIER 1 — IDENTITY-PROVIDER-FOR-FLEET**:
  - Holds: **every-user-credential for every-app behind it**
  - Compromise = breach of ALL downstream apps
  - Passkey + TOTP + password + OIDC-session-tokens + refresh-tokens
  - **159th tool in hub-of-credentials family — Tier 1 CROWN-JEWEL**
  - **Identity-provider-SSO: N tools** — reinforces Authelia/Keycloak/Authentik family (continuing)
  - **CROWN-JEWEL Tier 1: 53 tools / 48 sub-categories**
- **SINGLE-POINT-OF-FAILURE**:
  - VoidAuth down = all apps inaccessible
  - HA/backup-auth plan critical
  - **Recipe convention: "SSO-single-point-of-failure-plan callout"**
  - **NEW recipe convention** (VoidAuth 1st formally)
- **PASSKEY-WEBAUTHN-BACKUP**:
  - Lost device = lost passkey
  - Need fallback auth
  - **Recipe convention: "passkey-device-loss-recovery-plan callout"**
  - **NEW recipe convention** (VoidAuth 1st formally)
- **FORWARDAUTH-REVERSE-PROXY-COUPLING**:
  - Tight coupling to reverse proxy
  - Misconfig = bypass
  - **Recipe convention: "forward-auth-proxy-misconfig-bypass-risk callout"**
  - **NEW recipe convention** (VoidAuth 1st formally)
- **SELF-REGISTRATION-ABUSE**:
  - If self-reg enabled on public-facing, spam/abuse vector
  - Whitelist domains or invitations-only
  - **Recipe convention: "self-registration-abuse-mitigation callout"**
  - **NEW recipe convention** (VoidAuth 1st formally)
- **SMTP-DEPENDENCY**:
  - Password-reset via email
  - SMTP breach = auth-reset abuse
  - **Recipe convention: "SMTP-for-password-reset-hardening callout"**
  - **NEW recipe convention** (VoidAuth 1st formally)
- **OIDC-CLIENT-SECRET-ROTATION**:
  - Per-app secrets need rotation
  - **Recipe convention: "OIDC-client-secret-rotation-discipline"** — reinforces JWT-rotation family (112)
- **PASSKEY-SUPPORT POSITIVE-SIGNAL**:
  - Modern WebAuthn support
  - **Recipe convention: "passkey-WebAuthn-built-in positive-signal"**
  - **NEW positive-signal convention** (VoidAuth 1st formally)
- **USER-INVITATION-FLOW**:
  - Invite-only mode for controlled growth
  - **Recipe convention: "invitation-based-user-creation-flow positive-signal"**
  - **NEW positive-signal convention** (VoidAuth 1st formally)
- **INSTITUTIONAL-STEWARDSHIP**: voidauth org + website + CI + active releases. **145th tool — purpose-built-selfhost-auth sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + CI + releases + website. **151st tool in transparent-maintenance family.**
- **SSO-IDP-CATEGORY:**
  - **VoidAuth** — simple; purpose-built for self-hosted
  - **Authelia** — popular in homelabs; YAML-config
  - **Authentik** — feature-rich; Django
  - **Keycloak** — enterprise Java; dominant
  - **Zitadel** — Go; modern enterprise
  - **Casdoor** — Go; multi-tenant
- **ALTERNATIVES WORTH KNOWING:**
  - **Authelia** — if you want simple + YAML + homelab-proven
  - **Authentik** — if you want feature-rich
  - **Keycloak** — if you want enterprise-grade
  - **Choose VoidAuth if:** you want simple + self-hosted-focused + passkey-first.
- **PROJECT HEALTH**: active + CI + releases + website. Emerging; watch version stability.

## Links

- Repo: <https://github.com/voidauth/voidauth>
- Website: <https://voidauth.app>
- Authelia (alt): <https://github.com/authelia/authelia>
- Authentik (alt): <https://github.com/goauthentik/authentik>
