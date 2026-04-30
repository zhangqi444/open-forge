---
name: lldap
description: "Light LDAP — self-hosted lightweight LDAP server for authentication only. Web UI, user/group management, LDAP v3 bind-only interface. Built for self-hosters who need LDAP auth for apps (Nextcloud, Gitea, Vaultwarden, etc.) without the pain of OpenLDAP/389ds. Rust. GPL-3.0."
---

# lldap

**lldap** (**Light LDAP**) is **the self-hoster's dream LDAP server** — a lightweight, Rust-based LDAP v3 bind-only server designed specifically for providing authentication to self-hosted apps. Unlike OpenLDAP and 389 Directory Server, which are industrial-strength but notoriously painful to configure, lldap is **simple**: one binary, one small SQLite DB, a web UI for managing users + groups, LDAP interface that any LDAP-compatible app can bind to.

Positioning: **not** a full LDAP server — only the features needed for auth (search + bind). No replication, no schemas, no dynamic groups. That's the feature, not a bug. Most self-hosters need auth-LDAP, not enterprise directory services.

Typical use: you run Nextcloud + Gitea + Vaultwarden + Jellyfin + GitLab + Grafana + Prometheus + N other apps; each wants its own user DB; you install lldap, point every app at it for LDAP auth, manage one user list.

Features:

- **LDAP v3 bind** — any standard LDAP-compatible app can authenticate against it
- **Web UI** for user + group management (add, edit, reset password, assign to group)
- **Password policies** — configurable length + complexity
- **TLS support** — LDAPS on 6360 or STARTTLS
- **SQLite / MySQL / Postgres backend** — SQLite default, fine for thousands of users
- **User avatars + custom attributes**
- **Forgot-password** via email
- **Admin API** — REST for automation
- **Audit log**
- **Group nesting** (basic)
- **Docker-first deployment**
- **Small footprint**: ~20 MB RAM, single binary, ARM + x86-64

- Upstream repo: <https://github.com/lldap/lldap>
- Install docs: <https://github.com/lldap/lldap/blob/main/docs/install.md>
- App integration examples: <https://github.com/lldap/lldap/tree/main/example_configs>
- Docker Hub: <https://hub.docker.com/r/lldap/lldap>
- Discord: <https://discord.gg/h5PEdRMNyP>

## Architecture in one minute

- **Single Rust binary**
- **DB**: SQLite (default), MySQL, or Postgres
- **Ports**:
  - LDAP (bind + search): `3890` plain / `6360` LDAPS
  - HTTP (web UI + API): `17170`
- **Storage**: DB holds users + groups + passwords (Argon2-hashed)
- **No schema extensions** — uses inetOrgPerson / posixAccount + a small set of custom attrs

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                         |
| ------------------ | -------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| Single VM          | **Docker (`lldap/lldap`)**                                         | **Most common**                                                                    |
| Single VM          | Native binary + systemd                                                     | Pre-built releases on GitHub                                                                 |
| Raspberry Pi       | arm64/arm32 Docker or binary                                                         | Tiny footprint — ideal for Pi                                                                             |
| Kubernetes         | Community Helm                                                                              | Works                                                                                                                |
| Managed            | — (no SaaS; self-host only)                                                                                 |                                                                                                                                         |

## Inputs to collect

| Input                   | Example                                | Phase      | Notes                                                                       |
| ----------------------- | -------------------------------------- | ---------- | --------------------------------------------------------------------------- |
| Base DN                 | `dc=example,dc=com`                           | Schema     | Your LDAP "root"                                                                    |
| Admin user              | `admin` + long password                           | Bootstrap  | Created via env on first boot                                                                        |
| JWT secret              | `openssl rand -hex 32`                                     | Security   | Session tokens                                                                                                  |
| DB                      | SQLite default / external MySQL/PG                                     | Storage    | SQLite fine for <10k users                                                                                                |
| LDAP port               | `3890` (plain) / `6360` (LDAPS)                                              | Network    | Expose internal; proxy-tls for app integrations                                                                                        |
| Web UI port             | `17170`                                                                              | Network    | Map to reverse proxy                                                                                                                 |
| SMTP (opt)              | host/port/user/pass                                                                           | Email      | For password reset                                                                                                                   |

## Install via Docker

```yaml
services:
  lldap:
    image: lldap/lldap:v0.6                          # pin
    container_name: lldap
    restart: unless-stopped
    ports:
      - "3890:3890"                                    # LDAP
      - "17170:17170"                                   # Web UI
    environment:
      UID: "1000"
      GID: "1000"
      TZ: America/Los_Angeles
      LLDAP_JWT_SECRET: "CHANGE_ME_LONG_RANDOM"
      LLDAP_LDAP_USER_PASS: "CHANGE_ME_STRONG"          # admin password
      LLDAP_LDAP_BASE_DN: "dc=example,dc=com"
    volumes:
      - ./data:/data
```

Browse `http://<host>:17170/`.

## First boot

1. Log in as `admin` / `LLDAP_LDAP_USER_PASS`
2. **Users → Add User** — `alice`, email, first/last name, random password (users reset via email)
3. **Groups → Add Group** — `lldap_strict_readonly`, `nextcloud_users`, `admins`, etc.
4. Assign users to groups
5. For each self-hosted app, configure LDAP auth pointing at `ldap://lldap:3890/` with bind DN `uid=admin,ou=people,dc=example,dc=com` (or a restricted readonly user)

### App integration snippets

Upstream repo has examples in `example_configs/` for:

- Nextcloud
- Gitea / Forgejo
- Vaultwarden
- Jellyfin
- Grafana
- Authelia / Authentik (use lldap as LDAP source)
- Portainer
- KeyCloak (as LDAP federation)
- Gitlab
- Home Assistant
- Bookstack
- … and more

## Data & config layout

- `/data/lldap_config.toml` — config (rare)
- `/data/users.db` — SQLite (users, groups, hashed passwords)
- `/data/private_key` — JWT signing key

## Backup

```sh
# Stop for consistent SQLite snapshot (seconds)
docker compose stop lldap
tar czf lldap-$(date +%F).tgz data/
docker compose start lldap
```

Losing `users.db` = lose everyone's passwords (they'd need to be reset). Losing `private_key` = invalidate all sessions (acceptable). Back up both.

## Upgrade

1. Releases: <https://github.com/lldap/lldap/releases>. Active; still `0.x`.
2. Back up `data/` before major bumps.
3. Docker: bump tag; migrations auto.

## Gotchas

- **lldap is intentionally minimal.** No replication, no advanced schemas, no directory-wide search features beyond auth. If you need a real LDAP directory (address book, dynamic groups, custom OIDs), use OpenLDAP or 389 DS.
- **It's a BIND-only LDAP.** Apps can authenticate users but not walk the tree freely. Fine for 99% of self-host auth use cases.
- **Use readonly bind user for apps**: create a dedicated `ro-admin` user in the `lldap_strict_readonly` group; use those creds in app LDAP config. Don't put your admin password in every app's config.
- **TLS**: production should use LDAPS (port 6360) or STARTTLS. Put a TLS reverse proxy (HAProxy/stunnel) in front, or configure lldap with its own cert.
- **Admin password reset**: if you forget the admin password, set `LLDAP_LDAP_USER_PASS` in the compose env + restart → admin password overwritten.
- **JWT secret rotation**: rotating invalidates all sessions; users re-login. Plan downtime.
- **Password policies**: configure minimum length + complexity in config.toml; lldap doesn't enforce without config.
- **SSO (OIDC/SAML) is NOT directly lldap**: lldap gives LDAP. Use Authelia/Authentik on top of lldap for OIDC/SAML. Pattern: Authentik-with-LDAP-federation → lldap.
- **Group mapping**: many apps expect group DN like `cn=admins,ou=groups,dc=example,dc=com`. lldap follows this convention; check each app's LDAP config.
- **Email-as-username**: configurable; some apps prefer `uid` some prefer `mail`. lldap supports both as bind attributes.
- **SCIM / provisioning APIs**: not built-in. Use the REST API for scripted user creation.
- **Export / migration**: lldap REST API + `ldapsearch` allow dumping users. For moving to/from OpenLDAP, both directions are possible.
- **Performance**: SQLite handles thousands of users + thousands of binds/sec. Don't worry about perf for self-host scale.
- **IPv6**: lldap binds both by default.
- **License**: **GPL-3.0**. Core/app contributions welcome.
- **Alternatives worth knowing:**
  - **OpenLDAP** — the classic; powerful; painful config (slapd.conf hell)
  - **389 Directory Server** — Red Hat's enterprise LDAP
  - **FreeIPA** — LDAP + Kerberos + DNS + CA; heavy; good for Linux-centric enterprises
  - **Authentik** — IdP with OIDC/SAML + built-in user store + LDAP outpost (separate recipe; complementary to lldap)
  - **Authelia** — auth middleware; can use lldap as backend (separate recipe; complementary)
  - **KeyCloak** — Java; heavy; full-featured IdP (separate recipe likely)
  - **GLAuth** — another lightweight LDAP; Go; competing with lldap
  - **Rock/Stalwart Directory** — email-first but does LDAP
  - **Active Directory** / **Azure AD** — Microsoft commercial
  - **Choose lldap if:** you want a no-hassle LDAP auth source for self-hosted apps.
  - **Choose Authentik/KeyCloak if:** you need OIDC/SAML, richer policy; can pair with lldap for user store.
  - **Choose OpenLDAP if:** enterprise features / replication / compliance demand it.
  - **Choose FreeIPA if:** you're building a Linux-enterprise directory.

## Links

- Repo: <https://github.com/lldap/lldap>
- Install docs: <https://github.com/lldap/lldap/blob/main/docs/install.md>
- App integration configs: <https://github.com/lldap/lldap/tree/main/example_configs>
- Docker Hub: <https://hub.docker.com/r/lldap/lldap>
- Releases: <https://github.com/lldap/lldap/releases>
- Discord: <https://discord.gg/h5PEdRMNyP>
- Twitter: <https://twitter.com/nitnelave1>
- Authentik (alt/complement): <https://goauthentik.io>
- Authelia (alt/complement): <https://www.authelia.com>
- OpenLDAP (alt): <https://www.openldap.org>
- FreeIPA (alt): <https://www.freeipa.org>
- GLAuth (alt): <https://github.com/glauth/glauth>
