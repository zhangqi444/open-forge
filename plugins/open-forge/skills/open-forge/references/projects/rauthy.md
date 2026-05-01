---
name: Rauthy
description: "Self-hosted OIDC/OAuth 2.0/PAM identity provider. Docker. Rust. sebadob/rauthy. Passkeys, passwordless, HA via Hiqlite/Postgres, brute-force protection, geo-blocking, client branding, MFA, PAM, events/auditing. Security-audited. Apache 2.0."
---

# Rauthy

**Lightweight self-hosted OIDC/OAuth 2.0/PAM identity provider.** SSO for your self-hosted services — a Keycloak alternative that runs on a Raspberry Pi. Rust-written for minimal footprint (~35–65 MB RAM). Passkeys and passwordless login as first-class citizens. Built-in HA via embedded Hiqlite (no external DB required). Security-audited. Brute-force + geo-blocking. Events and auditing. Client branding. PAM for IoT/CLI.

Built + maintained by **sebadob (Sebastian Dobe)**. Apache 2.0 license.

**Security audit:** Independent audit by [Radically Open Security](https://www.radicallyopensecurity.com/) via NGI Zero Core funding. Report: see README link.

- Upstream repo: <https://github.com/sebadob/rauthy>
- Docs: <https://sebadob.github.io/rauthy/>
- Docker Hub: <https://hub.docker.com/r/ghcr.io/sebadob/rauthy>
- GHCR: `ghcr.io/sebadob/rauthy`
- Changelog: <https://github.com/sebadob/rauthy/blob/main/CHANGELOG.md>

## Architecture in one minute

- **Rust** binary — single executable
- **Hiqlite** (default, embedded HA) — no external DB needed; creates its own distributed SQLite-based cluster
- **PostgreSQL** (optional) — for existing Postgres installations or preference
- Ports: **8080** (HTTP) + **8443** (HTTPS); admin port configurable
- HA mode: multiple Rauthy instances form a Hiqlite raft cluster
- Resource: **very low** — ~35 MB RAM (PostgreSQL mode), ~57–65 MB (Hiqlite single/HA)

## Compatible install methods

| Infra      | Runtime                     | Notes                                             |
| ---------- | --------------------------- | ------------------------------------------------- |
| **Docker** | `ghcr.io/sebadob/rauthy`    | **Primary** — GHCR; multi-arch                    |
| **Binary** | GitHub Releases             | Pre-built Rust binary; all platforms              |
| **K8s**    | Helm chart + Docker         | See docs for Kubernetes deployment                |

Quickstart: <https://sebadob.github.io/rauthy/getting_started/k8s.html>

## Install via Docker

```bash
# Create config dir and minimal rauthy.cfg
mkdir -p rauthy-data
cat > rauthy.cfg << 'EOF'
# Minimal config - see full reference at docs
RAUTHY_ADMIN_EMAIL=admin@example.com
RAUTHY_ADMIN_PASSWORD_INIT=changeme_initial
EOF

docker run -d \
  --name rauthy \
  -p 8080:8080 \
  -v ./rauthy-data:/app/data \
  -v ./rauthy.cfg:/app/rauthy.cfg \
  ghcr.io/sebadob/rauthy:latest
```

Visit `http://localhost:8080/auth/v1/`.

Full Docker install: <https://sebadob.github.io/rauthy/getting_started/docker.html>

## First boot

1. Configure `rauthy.cfg` with admin credentials + any custom settings.
2. Start container.
3. Visit `http://localhost:8080/auth/v1/` → admin login.
4. **Register an OIDC client**:
   - Admin UI → Clients → New Client
   - Set `client_id`, redirect URIs, allowed flows
   - Choose `ed25519` (default, most secure) or `RS256` for token signing
5. Configure your applications to use Rauthy as the OIDC provider.
6. Set up user accounts or configure an upstream identity provider.
7. Enable Passkeys for passwordless login.
8. Put behind TLS (nginx/Caddy).

## Auth flows supported

- Authorization Code (with PKCE S256 by default)
- Client Credentials
- Device Code (for IoT/CLI via PAM)
- Implicit (legacy; disabled by default)
- Refresh Token

## Key features

| Feature | Details |
|---------|---------|
| OIDC + OAuth 2.0 | Full compliance; JWT tokens |
| Passkeys (FIDO2) | WebAuthn passwordless; hardware key support |
| Passkey-only accounts | No password at all; pure passkey login |
| MFA | TOTP + Passkeys |
| PAM | IoT/headless CLI SSO via Device Code flow |
| Hiqlite HA | Embedded distributed DB; no external DB for HA |
| PostgreSQL | Optional alternative to Hiqlite |
| Client branding | Custom colors + logo per OIDC client |
| UI translations | Multiple languages (admin UI + login page) |
| Events + auditing | All auth events; email/Matrix/Slack alerts by severity |
| Brute-force protection | Auto-blacklist IPs after too many failed logins |
| Geo-blocking | Block requests by geolocation |
| Admin UI | Full management UI |
| User dashboard | Self-service account management |
| App passwords | For legacy apps that don't support OIDC |
| Groups + roles | For OIDC claims mapping |

## Passkeys architecture

Rauthy's Passkeys are designed to avoid discoverable credentials:

- You enter your email (autofilled after first login)
- Passkey verification completes the authentication
- Hardware keys (Yubikey, etc.) work without consuming a key slot — Rauthy passkeys don't use discoverable credentials

Two modes:
1. **Password + Security Key** — password login + optional hardware key (cookie remembered for trusted devices)
2. **Passkey-Only Account** — no password; FIDO2 UV (User Verification) required; strongest security

## Token signing algorithms

| Algorithm | Notes |
|-----------|-------|
| `ed25519` | **Default** — modern, fast, secure; not compatible with very old OIDC clients |
| `RS256` | RSA; wider compatibility; disable ed25519 if client doesn't support it |

## Hiqlite HA

Rauthy runs HA with multiple instances forming a Hiqlite raft consensus cluster. No external DB, no Redis, no external state — just multiple Rauthy instances pointing at each other. See the HA docs for node count and deployment configuration.

## Gotchas

- **`ed25519` default may break old OIDC clients.** Rauthy defaults to `ed25519` for token signing — it's the most secure but not all OIDC clients support it (especially older or embedded clients). Switch to `RS256` in the client settings if you hit "unsupported algorithm" errors.
- **S256 PKCE enforced by default.** New clients have PKCE S256 enforced. Older clients that don't support PKCE must have it disabled per-client.
- **Discoverable credentials NOT used.** This is intentional for security (Yubikey slot conservation). Users must enter their email for passkey login — they won't see a passkey prompt without entering email first.
- **Initial admin password.** Set `RAUTHY_ADMIN_PASSWORD_INIT` in config for the first run. Change it after first login — this variable only sets the initial password.
- **PAM for IoT/CLI.** The Device Code flow allows headless devices (Raspberry Pi, CLI tools) to authenticate with Rauthy via a browser-based authorization step. See the PAM docs.
- **Geo-blocking needs MaxMind data.** Geo-blocking requires a MaxMind GeoLite2 or GeoIP2 database file. Free tier available with registration at maxmind.com.
- **TLS required for Passkeys.** WebAuthn (Passkeys) requires HTTPS. Passkeys won't work over plain HTTP (except `localhost`). Use a reverse proxy with TLS.

## Backup

```sh
# Hiqlite mode: backup the data directory
docker stop rauthy
sudo tar czf rauthy-$(date +%F).tgz rauthy-data/
docker start rauthy

# PostgreSQL mode
pg_dump rauthy > rauthy-$(date +%F).sql
```

## Upgrade

1. Read CHANGELOG for breaking changes.
2. `docker pull ghcr.io/sebadob/rauthy:latest && docker restart rauthy`.
3. Rauthy handles DB migrations automatically.

## Project health

Active Rust development, GHCR, security-audited (NGI Zero Core), Hiqlite HA, Passkeys, PAM, geo-blocking, events/auditing, multiple languages, Helm chart. Solo-maintained by sebadob. Apache 2.0.

## Identity-provider-family comparison

- **Rauthy** — Rust, ~35–65 MB RAM, Passkey-first, Hiqlite HA (no external DB), security-audited, Apache 2.0
- **Keycloak** — Java, enterprise-grade, everything + kitchen sink; 300+ MB RAM; overkill for small setups
- **Authentik** — Python/Go, modern, extensive integrations; heavier than Rauthy
- **Authelia** — Go, SSO proxy + 2FA; no direct OIDC provider; different pattern
- **Casdoor** — Go, rich OIDC provider; more features than Rauthy; heavier
- **Dex** — Go, OIDC connector/fedrator; proxies to upstream IdPs; different use case

**Choose Rauthy if:** you want a lightweight, security-first, Passkey-native OIDC/OAuth 2.0/PAM identity provider that runs on minimal resources (even a Raspberry Pi) with built-in HA via Hiqlite.

## Links

- Repo: <https://github.com/sebadob/rauthy>
- Docs: <https://sebadob.github.io/rauthy/>
- GHCR: `ghcr.io/sebadob/rauthy`
- Security audit report: see README
- Changelog: <https://github.com/sebadob/rauthy/blob/main/CHANGELOG.md>
