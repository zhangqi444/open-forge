---
name: GLAuth
description: "Go-lang LDAP authentication server. Lightweight alternative to OpenLDAP/AD for homelab/dev. Configurable backends: file, S3, SQL (MySQL/Postgres), or proxy. Transparent 2FA. MIT. Glauth org + fusion/Chris Lu maintainer. Active."
---

# GLAuth

GLAuth is **"OpenLDAP / Active Directory — but Go + simple + file/SQL/S3-backed + homelab-friendly"** — a lightweight LDAP authentication server for developers, homelabs, and small teams. Centralize account management + SSH keys + Linux account creds across infrastructure. Configurable backends: file-based config, S3-backed config, SQL (MySQL/PostgreSQL/SQLite) DB, or proxy-to-existing-LDAP. Transparent 2FA (TOTP) applications don't need to know about. Backends can chain to inject features.

Built + maintained by **GLAuth org** + **Chris F. Ravenscroft (fusion)** — also maintains Kittendns + Wing VPN (prolific-coherent-toolset pattern). License: **MIT**. Active; GitHub Actions; Docker Hub; releases page; active community; multiple backend-plugins.

Use cases: (a) **homelab SSO-backbone** — one LDAP for Jenkins + Nextcloud + Gitea + Graylog + Apache/nginx (b) **developer LDAP for testing** — spin up LDAP locally for app-dev (c) **lightweight AD-alternative** — small teams without need for full AD (d) **SSH key centralization** — Linux accounts + SSH keys pulled from LDAP (e) **chain-backend-architecture** — file + SQL + proxy layered for fallback (f) **proxy-to-existing-LDAP + 2FA overlay** — add 2FA to legacy LDAP (g) **S3-backed config** — HA config-distribution (h) **replace Keycloak/Authelia for pure-LDAP scenarios**.

Features (per README):

- **LDAP v3** server in Go
- **Backends**: file, S3, SQL (MySQL/Postgres/SQLite), or LDAP-proxy
- **Backend chaining** — layer backends
- **Transparent 2FA** (TOTP) — applications see classic LDAP
- **SSH key serving** via LDAP
- **Configurable via config file OR env**
- **Single binary**

- Upstream repo: <https://github.com/glauth/glauth>
- Website: <https://glauth.github.io>
- Quickstart config: <https://github.com/glauth/glauth/blob/master/v2/sample-simple.cfg>
- Releases: <https://github.com/glauth/glauth/releases>
- Related: kittendns + wing-vpn (fusion)

## Architecture in one minute

- **Go** single binary
- **Ports**: 389 (LDAP plaintext), 636 (LDAPS)
- **Resource**: very low — 30-100MB RAM
- **Config**: single `.cfg` file OR env vars
- **Backends plug in** — file / SQL / S3 / LDAP-proxy

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Binary**         | **Download + systemd**                                          | **Primary**                                                                        |
| **Docker**         | **`glauth/glauth`**                                             | **Containerized**                                                                        |
| **Source**         | `go build` from master / dev                                    | Dev                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| LDAP port            | 389 (plain) / 636 (LDAPS)                                   | Network      | **TLS MANDATORY** for production                                                                                    |
| TLS cert + key       | PEM files                                                   | TLS          |                                                                                    |
| Backend choice       | config / SQL / S3 / proxy                                   | Backend      |                                                                                    |
| Initial users        | `sample-simple.cfg` format                                  | Bootstrap    | **bcrypt password hashes**                                                                                    |
| Groups / OUs         | LDAP tree structure                                         | Bootstrap    |                                                                                    |
| 2FA secrets (opt)    | TOTP per user                                               | Auth         |                                                                                    |
| SQL connection (opt) | Postgres / MySQL URL                                                                                   | Backend      |                                                                                    |
| S3 bucket (opt)      | For S3-backed config                                                                                                      | Backend      |                                                                                                                                            |

## Install via Docker

```yaml
services:
  glauth:
    image: glauth/glauth:v2        # **pin version**
    ports:
      - "389:389"
      - "636:636"
    volumes:
      - ./config:/app/config:ro
      - ./tls:/app/tls:ro
    restart: unless-stopped
```

```sh
# Test:
ldapsearch -LLL -H ldap://host:389 \
  -D "cn=serviceuser,ou=svcaccts,dc=example,dc=com" -w "$SVC_PASSWORD" \
  -x -b "dc=example,dc=com" "cn=alice"
```

## First boot

1. Start GLAuth with example config
2. Test with `ldapsearch` (sanity check)
3. Replace example config with your users + bcrypt hashes
4. Enable LDAPS (TLS) — NEVER run plaintext-only in production
5. Configure clients (Jenkins, Nextcloud, Gitea, etc.) to bind to GLAuth
6. Test 2FA flow (append TOTP to password)
7. Back up config

## Data & config layout

- Config file or env — all users + groups + passwords + keys
- `tls/cert.pem`, `tls/key.pem`
- If SQL: DB becomes source-of-truth
- If S3: S3 bucket becomes source-of-truth
- If LDAP-proxy: upstream LDAP is source-of-truth

## Backup

```sh
sudo cp -a config backups/config-$(date +%F)
# If SQL-backed: pg_dump or mysqldump
```

## Upgrade

1. Releases: <https://github.com/glauth/glauth/releases>. Active.
2. `v2` is current major; check CHANGELOG for breaking changes
3. Binary replacement + restart

## Gotchas

- **LDAP = IDENTITY-PROVIDER CROWN-JEWEL**:
  - GLAuth stores PASSWORDS + SSH KEYS + 2FA SECRETS for entire infrastructure
  - Compromise = every application depending on LDAP is compromised
  - **77th tool in hub-of-credentials family — Tier 1 CROWN-JEWEL** — reinforces "IdP/auth-service" sub-category
  - **CROWN-JEWEL Tier 1 sub-category reinforced: IdP-auth-service** — 3+ tools (Octelium-zero-trust-bastion, Authentik-if-listed, GLAuth-LDAP) — **now formal "IdP/auth-service" sub-category**
  - **NEW or reinforced CROWN-JEWEL sub-category: "IdP-auth-service-central-directory"** — GLAuth 1st named explicitly
  - **CROWN-JEWEL Tier 1: 18 tools; 16 sub-categories**
- **LDAP PLAINTEXT = CRITICAL SECURITY RISK**:
  - Port 389 is plaintext LDAP
  - Passwords, queries travel cleartext
  - **MANDATORY**: LDAPS (636) + STARTTLS
  - **Recipe convention: "LDAPS-mandatory" callout** — no plaintext LDAP in production
  - **NEW recipe convention** (GLAuth 1st formally)
- **BCRYPT PASSWORD HASHING**:
  - GLAuth config supports bcrypt hashes (not plaintext)
  - **Recipe convention: "bcrypt-config-passwords positive-signal"** — config hashes not plain
  - **NEW positive-signal convention**
- **TRANSPARENT 2FA**:
  - Apps bind to LDAP unchanged; GLAuth validates TOTP on the back
  - **Recipe convention: "transparent-2FA-retrofit positive-signal"** — 2FA without app changes
  - **NEW positive-signal convention**
- **S3-BACKED CONFIG = HA DISTRIBUTION**:
  - Config stored in S3; GLAuth pulls
  - Update S3 → all GLAuth instances pull updated config
  - **Recipe convention: "S3-as-config-distribution" positive-signal**
  - But: config in S3 = S3 credentials are now crown-jewel too
- **BACKEND CHAINING**:
  - Chain: file-for-admin + SQL-for-users + proxy-for-legacy
  - Powerful; complex to debug
  - **Recipe convention: "pluggable-backend-chaining" positive-signal**
- **PROXY-BACKEND = LDAP-TO-LDAP**:
  - Use GLAuth to retrofit 2FA onto existing AD
  - Or as an LDAP-cache in front of flaky LDAP
  - **Recipe convention: "LDAP-proxy-as-2FA-retrofit" pattern**
  - **NEW recipe convention** (GLAuth 1st)
- **SSH-KEY-SERVING VIA LDAP**:
  - OpenSSH can authenticate using keys from LDAP
  - Centralizes SSH-key-management
  - **Centralize ONLY if you're comfortable — LDAP outage = no SSH**
  - **Recipe convention: "LDAP-single-point-of-failure" callout** (extends YunoHost 104 precedent to general tools)
- **PROLIFIC-MAINTAINER: fusion/Chris Lu**:
  - Kittendns + Wing VPN + GLAuth
  - Coherent tool-suite: DNS + VPN + LDAP = infrastructure-primitives
  - **3rd tool in prolific-sole-maintainer-with-coherent-toolset**: qdm12 (101) + mtlynch (103) + **fusion/chrislu (104)**
  - **Prolific-sole-maintainer-with-coherent-toolset: 3 tools** — solidifying
- **DEV-BRANCH FOR PRs**:
  - README: "base all PRs on dev not master"
  - Signals active release-engineering discipline
  - **Recipe convention: "dev-branch-PR-gate positive-signal"**
  - **NEW positive-signal convention**
- **INSTITUTIONAL-STEWARDSHIP**: glauth org + fusion + community. **63rd tool — prolific-sole-maintainer-with-coherent-toolset sub-tier (3rd tool).**
- **TRANSPARENT-MAINTENANCE**: active + GHA + Docker + releases + website + related-projects + v2-major-versioning. **71st tool in transparent-maintenance family.**
- **LDAP-CATEGORY:**
  - **GLAuth** — Go; lightweight; dev-focused
  - **OpenLDAP** — C; enterprise-mature
  - **389 Directory Server (Red Hat)** — C; enterprise
  - **lldap** — Rust; lightweight with web UI; homelab-friendly
  - **Samba AD DC** — AD-compatible
  - **FreeIPA** — Red Hat; enterprise
  - **Authentik** — full IdP (OIDC + LDAP outpost)
  - **Authelia** — IdP; LDAP-client-not-server
- **ALTERNATIVES WORTH KNOWING:**
  - **lldap** — if you want web UI + Rust + even simpler
  - **OpenLDAP** — if you need full enterprise LDAP
  - **Authentik** — if you want OIDC + LDAP + full IdP
  - **Choose GLAuth if:** you want Go + pluggable-backends + transparent-2FA + coherent-toolset.
  - **Choose lldap if:** you want Rust + web UI + simpler homelab focus.
- **PROJECT HEALTH**: active + prolific-maintainer + coherent-toolset + releases + community. Strong.

## Links

- Repo: <https://github.com/glauth/glauth>
- Website: <https://glauth.github.io>
- Kittendns: <https://github.com/fusion/kittendns>
- Wing VPN: <https://github.com/fusion/wing-vpn>
- lldap (alt): <https://github.com/lldap/lldap>
- OpenLDAP (alt): <https://www.openldap.org>
- Authentik (alt IdP): <https://goauthentik.io>
