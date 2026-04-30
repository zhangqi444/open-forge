---
name: Kanidm
description: "Simple + secure identity management — passkey-first OAuth2/OIDC provider + LDAPS gateway + RADIUS + Linux/Unix integration (TPM-protected offline auth, SSH key distribution). Rust, replicated, self-healing. Designed to replace Keycloak + FreeIPA. MPL-2.0."
---

# Kanidm

Kanidm (pronounced "kar-nee-dee-em" — from _kani_ = crab in Japanese + idm) is **a modern, Rust-based, all-in-one identity provider** — built to replace the typical "LDAP + Keycloak + 389-ds + RADIUS + OpenSSH-LDAP + PAM" stack with **one cohesive daemon**. Developed by **William Brown (Firstyear)** and team; high code-quality bar; strong defaults.

**Design philosophy:** *"You should not need any other components (like Keycloak) when you use Kanidm"* — upstream explicitly aims to BE the complete IdP. Strict defaults, simple config, self-healing.

Features (per upstream):

- **Passkeys (WebAuthn)** — phishing-resistant primary auth; attested passkeys supported for high-security envs
- **Application portal** — user-facing launcher for linked apps
- **OAuth2 / OIDC** provider (SSO for modern apps) + OAuth2 client (token exchange services)
- **Linux/Unix integration** with **TPM-protected offline auth** — log in without network reachable to Kanidm
- **SSH key distribution** — managed SSH public keys per user; systems pick up via Kanidm client
- **RADIUS** for network + VPN authentication
- **Read-only LDAPS gateway** — for legacy apps that only speak LDAP
- **Complete CLI tooling** (admin via CLI; Web UI for user self-service)
- **Two-node HA via database replication** (not raft-cluster — active-passive / active-active per topology)
- **User self-service Web UI** (password/passkey enrollment, MFA, profile)

- Upstream repo: <https://github.com/kanidm/kanidm>
- Docs ("Kanidm book"): <https://kanidm.github.io/kanidm/stable/>
- Support guidelines: <https://github.com/kanidm/kanidm/blob/master/book/src/support.md>
- Matrix/Gitter: <https://app.gitter.im/#/room/#kanidm_community:gitter.im>
- GitHub Discussions: <https://github.com/kanidm/kanidm/discussions>
- Code of Conduct + Ethics: explicit in repo
- LDAP bindings: <https://github.com/kanidm/ldap3>

## Architecture in one minute

- **Rust** single daemon (`kanidmd`)
- **Sled** embedded database (no external DB required)
- **Self-contained** — zero PostgreSQL/MySQL/Redis dependency
- **TPM-aware** — Linux client can store offline auth credentials in TPM
- **Unix client** (`kanidm-unixd`) — caches users + groups for PAM/nsswitch/sshd integration
- **Resource**: small — ~200 MB RAM for small/medium deployments; scales modest

## Compatible install methods

| Infra              | Runtime                                                         | Notes                                                                          |
| ------------------ | --------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Single VM          | **Container (`docker.io/kanidm/server`)** OR binary                 | **Upstream-recommended**                                                           |
| Kubernetes         | Helm charts available                                                       | Works; replication-aware                                                                    |
| HA pair            | Two nodes with DB replication                                                          | Upstream model for HA                                                                                   |
| Bare-metal         | Rust build OR pre-built binaries                                                                    | Requires Rust 1.x; `cargo build --release`                                                                                                  |
| Raspberry Pi       | arm64 images                                                                                        | Works for home-lab scale                                                                                                                   |

## Inputs to collect

| Input                | Example                                               | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `idm.example.com`                                          | URL          | **Production requires valid HTTPS certificate** — no self-signed                 |
| TLS cert             | Let's Encrypt / internal CA (full chain + key)                        | TLS          | Kanidm terminates TLS itself                                                              |
| Origin domain        | `example.com`                                                         | Config       | OAuth2/OIDC needs consistent origin                                                                      |
| Admin password       | auto-generated at init — **secure the initial admin creds**                            | Bootstrap    | Read from logs on first init                                                                                             |
| Replication peer     | (for HA) second node hostname + replication secret                                       | HA           | Post-init configuration                                                                                                  |
| Unix client config   | per-host: `kanidm-unixd.toml`                                                                    | Client       | For each Linux host integrating with Kanidm                                                                                                          |

## Install via Docker (single node)

Follow the Kanidm book's container section. Shape:

```yaml
services:
  kanidmd:
    image: docker.io/kanidm/server:latest              # pin specific version in prod
    container_name: kanidmd
    restart: unless-stopped
    ports:
      - "443:8443"                                      # HTTPS
      - "636:3636"                                      # LDAPS
    volumes:
      - ./data:/data
      - ./certs/chain.pem:/data/chain.pem:ro
      - ./certs/cert.pem:/data/cert.pem:ro
      - ./certs/key.pem:/data/key.pem:ro
    environment:
      TZ: UTC
```

Initial admin + idm_admin passwords are created at first init; recover from container logs or use `kanidmd recover-account`.

## First boot

1. Start kanidmd → recover the initial admin password from logs (`kanidmd recover-account admin`)
2. Log in via CLI: `kanidm login --name admin`
3. Change password; enroll passkey for admin
4. Create real users; enroll passkeys as primary auth
5. Configure OAuth2/OIDC application(s) — register each relying party (your apps)
6. (Optional) Configure LDAP gateway for legacy apps
7. (Optional) Install `kanidm-unixd` on Linux servers for PAM/SSH integration
8. Test: SSO to an OIDC app, SSH key lookup, RADIUS auth
9. Set up replication for HA (two-node minimum)
10. Back up `/data/` + TLS certs

## Data & config layout

- `/data/kanidm.db` (sled) — ALL state: users, groups, applications, passkeys, tokens, replication metadata
- `/data/certs/` — TLS material
- **One directory to back up** — Kanidm's self-contained design is a DR simplifier

## Backup

```sh
# Online snapshot (kanidmd supports safe hot backup)
kanidmd domain backup /backup/kanidm-$(date +%F).json
# Plus filesystem backup of /data/
sudo tar czf kanidm-full-$(date +%F).tgz data/
```

Critical: passkeys + signing keys live here. Losing = users lose MFA devices enrolled; replication keys regenerate.

## Upgrade

1. Releases: <https://github.com/kanidm/kanidm/releases>. Active, disciplined.
2. Follow **Kanidm book's upgrade path** — **major versions may require intermediate steps** (don't skip versions).
3. **Back up before every upgrade.**
4. Replicated setup: upgrade one node at a time; verify health between steps.

## Gotchas

- **Valid HTTPS certificate is MANDATORY in production.** Self-signed breaks passkey enrollment (WebAuthn requires a real cert + origin). Use Let's Encrypt or internal CA (with CA trust distributed to clients).
- **Don't skip major versions on upgrade.** Kanidm's upgrade path is documented in the book; intermediate hops may be required for schema migrations. Ignoring this = data corruption risk.
- **Passkey-first philosophy is the point.** If you force password-only auth, you're fighting the design. Kanidm strongly promotes passkeys + WebAuthn as primary.
- **Attested passkeys** differentiate consumer vs high-security: you can require passkeys from specific hardware-attested devices (YubiKey 5 + FIDO2 attestation). For homelab: not needed. For regulated enterprises: great feature.
- **"We already have everything you need" scope** — Kanidm bundles LDAP gateway + RADIUS + OIDC + SSH + PAM. If you specifically need Keycloak's realm complexity or FreeIPA's CA, Kanidm may not cover 100%. But for the vast majority — it's enough.
- **LDAP is read-only**. No write-back from LDAP clients. If a legacy app tries to write via LDAP, it'll fail. This is a deliberate design choice to avoid LDAP's sharp edges.
- **HA is replication-based (not raft)** — two-node active-active replication is the model; not a 3/5-node quorum cluster. For the vast majority of deployments, 2 nodes = sufficient resilience.
- **TPM integration**: Linux clients can cache auth credentials TPM-protected for offline login. Genuine differentiator for laptops/fleet. Setup non-trivial — read the book.
- **CLI-first admin**: web UI is mainly user self-service + limited admin. Day-to-day admin happens via `kanidm` CLI + scripts. This is a feature (auditable, scriptable) not a bug.
- **Comparison to LLDAP**: LLDAP = simpler, only LDAP, web admin UI. Kanidm = richer, OAuth2/OIDC native, CLI admin. If you just need "users + groups for Nextcloud," LLDAP is easier. If you want a complete IdP, Kanidm.
- **Comparison to Authentik/Authelia**: these are primarily forward-auth gateways (put in front of apps). Kanidm is primarily an IdP (apps integrate natively via OIDC/LDAP). Different role. Can combine: Authentik as forward-auth, Kanidm as IdP backend.
- **Comparison to Keycloak**: Keycloak = Java, feature-heavy, realm-complex. Kanidm = Rust, simpler mental model, fewer moving parts, self-healing. For org-scale with custom auth flows Keycloak still wins; for most self-host scenarios Kanidm wins on simplicity.
- **Ethics + Code of Conduct explicit**: upstream has "rights and ethics" doc guiding feature decisions. Unusual, admirable, worth reading.
- **Project health**: active core team; William Brown (Firstyear) is a recognized FreeIPA/389-ds veteran. Not bus-factor-1.
- **License**: **MPL-2.0** (verify in LICENSE).
- **Alternatives worth knowing:**
  - **LLDAP** — simpler LDAP-only with web UI
  - **Authentik / Authelia** — forward-auth + OIDC
  - **Keycloak** — Red Hat enterprise IdP (Java)
  - **FreeIPA / 389-ds** — classic enterprise LDAP+Kerberos
  - **Zitadel** — modern OIDC-focused (Go)
  - **Casdoor** — newer IdP (Go)
  - **Ory Kratos/Hydra/Keto** — modular identity stack
  - **Choose Kanidm if:** want a complete modern IdP + passkey-first + Rust + self-healing + simpler than Keycloak.
  - **Choose LLDAP if:** just need LDAP + web admin + no OAuth.
  - **Choose Keycloak if:** need huge feature set + Java comfort + enterprise complexity.

## Links

- Repo: <https://github.com/kanidm/kanidm>
- Kanidm book: <https://kanidm.github.io/kanidm/stable/>
- Support guidelines: <https://github.com/kanidm/kanidm/blob/master/book/src/support.md>
- Code of Conduct: <https://github.com/kanidm/kanidm/blob/master/CODE_OF_CONDUCT.md>
- Ethics doc: <https://github.com/kanidm/kanidm/blob/master/book/src/developers/developer_ethics.md>
- Community: <https://app.gitter.im/#/room/#kanidm_community:gitter.im>
- Discussions: <https://github.com/kanidm/kanidm/discussions>
- Releases: <https://github.com/kanidm/kanidm/releases>
- Docker image: <https://hub.docker.com/r/kanidm/server>
- LDAP bindings: <https://github.com/kanidm/ldap3>
- LLDAP (alt): <https://github.com/lldap/lldap>
- Authentik (alt forward-auth): <https://goauthentik.io>
- Keycloak (alt): <https://www.keycloak.org>
- Zitadel (alt): <https://zitadel.com>
