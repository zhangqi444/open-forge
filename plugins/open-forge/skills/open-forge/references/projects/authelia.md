---
name: authelia-project
description: Authelia recipe for open-forge. Apache 2.0 authentication and authorization server — provides SSO + 2FA (TOTP / WebAuthn / Mobile Push via Duo) for your apps via a web portal. Integrates with reverse proxies (Traefik / nginx / Caddy / HAProxy / Envoy / SWAG / Skipper) as a ForwardAuth middleware. Acts as an OpenID Connect 1.0 Provider (beta-stable) so downstream apps can do OIDC + SSO. Lightweight single Go binary or container — compared to Keycloak it's much simpler but with fewer bells and whistles. Storage: file / LDAP for users; SQLite / MariaDB / MySQL / PostgreSQL for sessions. Redis optional for session store. Covers the canonical Traefik compose with Authelia as forwardAuth middleware, configuration.yml structure, and proxy-specific quirks.
---

# Authelia

Apache 2.0 authentication + authorization + SSO server. Upstream: <https://github.com/authelia/authelia>. Docs: <https://www.authelia.com>.

Purpose: add login + 2FA + SSO in front of apps that don't have their own auth (or whose auth you want to unify). Unlike Keycloak (heavier, Java, more features) or Authentik (also more features, Python), Authelia is a lean single Go binary focused on doing auth-in-front-of-a-reverse-proxy extremely well.

**How it works (the 30-second version):**

1. User hits `app.example.com` (an app behind your reverse proxy).
2. Reverse proxy (Traefik / nginx / etc.) calls Authelia's `forwardAuth` endpoint via middleware BEFORE forwarding.
3. If the user isn't authenticated, Authelia redirects them to `auth.example.com` → login → 2FA.
4. After success, Authelia sets an authentication cookie valid for `auth.example.com` + parent domain.
5. Subsequent requests to any app on `example.com` get allowed without re-login (SSO via cookie).
6. Authelia sends `Remote-User`, `Remote-Groups`, `Remote-Email`, `Remote-Name` headers to the backend.

## Features

- **Login + 2FA**: TOTP (standard authenticator apps), WebAuthn (FIDO2 / Yubikey / Passkeys), Duo Push.
- **SSO via cookie** + parent-domain session sharing.
- **ForwardAuth integration** with Traefik, Caddy, nginx, HAProxy, Envoy, Skipper, SWAG.
- **OpenID Connect 1.0 Provider** (beta-stable as of 2026) — downstream apps can OIDC-authenticate against Authelia.
- **Access Control**: per-user, per-group, per-domain, per-IP subnet, per-URL-path rules with allow/deny/2FA-required.
- **Password policy** + account recovery (email with reset link).
- **Brute-force protection** — regulator locks out accounts after N failed attempts.
- **LDAP + Active Directory integration** for user source.
- **File-based user DB** for small deployments (a single `users_database.yml`).
- **Session storage**: memory (default, single-instance), Redis (for HA), database.
- **Storage backend**: SQLite (small), MariaDB, MySQL, PostgreSQL (production).
- **Notifications**: SMTP (for account recovery / alerts) or filesystem (dev).

## Proxy support (ForwardAuth)

First-party docs provided for:

- Traefik v2 / v3 (most mature integration)
- Caddy
- nginx (including LinuxServer.io's SWAG)
- HAProxy
- Envoy
- Skipper

For apps that speak OIDC directly (Nextcloud, Grafana, GitLab, Gitea, etc.), Authelia as OIDC Provider is a nicer integration than ForwardAuth — gives apps real user info, logout propagation, fine-grained scopes.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker image (`authelia/authelia`) | ✅ Recommended | Most self-hosters. |
| Docker Compose with Traefik | <https://github.com/authelia/authelia/tree/master/examples/compose/lite> | ✅ Example | Full quickstart — Authelia + Traefik + demo apps. |
| Kubernetes (Helm) | <https://charts.authelia.com> | ✅ | Clusters. |
| Static binary | <https://github.com/authelia/authelia/releases> | ✅ | Bare-metal / systemd. |
| Debian `.deb` | <https://apt.authelia.com> | ✅ | Debian/Ubuntu. |
| AUR | `authelia` / `authelia-bin` / `authelia-git` | Community | Arch. |
| FreeBSD Ports | `www/authelia` | Community | FreeBSD. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion`: `docker-compose-with-traefik` / `docker-compose-standalone` / `kubernetes` / `binary-systemd` | Drives section. |
| dns | "Parent domain?" | e.g. `example.com` | All protected apps need to share this parent domain for SSO. |
| dns | "Authelia subdomain?" | e.g. `auth.example.com` | The portal. |
| user-store | "User backend?" | `AskUserQuestion`: `file` / `ldap` / `active-directory` | File is fine for ≤10 users. |
| session-store | "Session storage?" | `AskUserQuestion`: `memory (single-instance)` / `redis (HA)` | Redis required for multi-replica deployments. |
| storage | "Storage backend (regulation, TOTP secrets, OIDC)?" | `AskUserQuestion`: `sqlite` / `postgresql` / `mysql` / `mariadb` | SQLite fine for small installs. |
| secrets | "Generate JWT / session / storage / OIDC HMAC secrets?" | Auto-generate 4+ × 64-char random | Authelia's canonical secrets: `jwt_secret`, `session.secret`, `storage.encryption_key`, optional OIDC `hmac_secret`. |
| 2fa | "Default 2FA method?" | `AskUserQuestion`: `totp` / `webauthn` / `any` / `none` | TOTP is easiest to start with. |
| smtp | "SMTP server for emails?" | Multi-field | Required for account recovery, 2FA enrollment confirmations. |
| proxy | "Reverse proxy in use?" | `AskUserQuestion`: `traefik` / `nginx` / `caddy` / `haproxy` / `envoy` / `swag` | Determines middleware config. |

## Install — Docker Compose (Traefik + Authelia lite example)

The upstream "lite" example (<https://github.com/authelia/authelia/tree/master/examples/compose/lite>) is a complete minimal setup. Adapted here:

```yaml
# compose.yml (based on upstream lite example)
networks:
  net:
    driver: bridge

services:
  authelia:
    image: authelia/authelia:latest               # pin in prod e.g. 4.39
    container_name: authelia
    volumes:
      - ./authelia:/config
    networks: [net]
    labels:
      traefik.enable: 'true'
      traefik.http.routers.authelia.rule: 'Host(`auth.example.com`)'
      traefik.http.routers.authelia.entrypoints: 'https'
      traefik.http.routers.authelia.tls: 'true'
      traefik.http.routers.authelia.tls.certresolver: 'letsencrypt'
      traefik.http.middlewares.authelia.forwardAuth.address: 'http://authelia:9091/api/authz/forward-auth'
      traefik.http.middlewares.authelia.forwardAuth.trustForwardHeader: 'true'
      traefik.http.middlewares.authelia.forwardAuth.maxResponseBodySize: '8192'
      traefik.http.middlewares.authelia.forwardAuth.authResponseHeaders: 'Remote-User,Remote-Groups,Remote-Name,Remote-Email'
    restart: unless-stopped
    environment:
      TZ: 'UTC'

  redis:
    image: redis:alpine
    container_name: redis
    volumes:
      - ./redis:/data
    networks: [net]
    restart: unless-stopped

  traefik:
    image: traefik:v3.6
    container_name: traefik
    volumes:
      - ./traefik:/etc/traefik
      - /var/run/docker.sock:/var/run/docker.sock
    networks: [net]
    labels:
      traefik.enable: 'true'
      traefik.http.routers.api.rule: 'Host(`traefik.example.com`)'
      traefik.http.routers.api.entrypoints: 'https'
      traefik.http.routers.api.service: 'api@internal'
      traefik.http.routers.api.tls: 'true'
      traefik.http.routers.api.tls.certresolver: 'letsencrypt'
      traefik.http.routers.api.middlewares: 'authelia@docker'    # ← protected by Authelia
    ports:
      - '80:80/tcp'
      - '443:443/tcp'
      - '443:443/udp'
    command:
      - '--api'
      - '--providers.docker=true'
      - '--providers.docker.exposedByDefault=false'
      - '--entrypoints.http=true'
      - '--entrypoints.http.address=:80'
      - '--entrypoints.http.http.redirections.entrypoint.to=https'
      - '--entrypoints.http.http.redirections.entrypoint.scheme=https'
      - '--entrypoints.https=true'
      - '--entrypoints.https.address=:443'
      - '--certificatesResolvers.letsencrypt.acme.email=you@example.com'
      - '--certificatesResolvers.letsencrypt.acme.storage=/etc/traefik/acme.json'
      - '--certificatesResolvers.letsencrypt.acme.httpChallenge.entryPoint=http'

  # Example protected app
  secure:
    image: traefik/whoami
    container_name: secure
    networks: [net]
    labels:
      traefik.enable: 'true'
      traefik.http.routers.secure.rule: 'Host(`secure.example.com`)'
      traefik.http.routers.secure.entrypoints: 'https'
      traefik.http.routers.secure.tls: 'true'
      traefik.http.routers.secure.tls.certresolver: 'letsencrypt'
      traefik.http.routers.secure.middlewares: 'authelia@docker'   # ← protected by Authelia
    restart: unless-stopped
```

To protect ANY app, add the label `traefik.http.routers.<name>.middlewares: 'authelia@docker'` — the middleware forwards the request to Authelia for auth validation before passing to the app.

## Configuration — `./authelia/configuration.yml`

```yaml
# authelia/configuration.yml
server:
  address: 'tcp://0.0.0.0:9091/'

theme: 'light'

log:
  level: 'debug'                    # 'info' in prod

totp:
  issuer: 'example.com'

identity_validation:
  reset_password:
    jwt_secret: '<random-64-chars>'

authentication_backend:
  file:
    path: '/config/users_database.yml'
    password:
      algorithm: 'argon2id'

access_control:
  default_policy: 'deny'
  rules:
    # Let anyone hit the landing page
    - domain: 'public.example.com'
      policy: 'bypass'
    # One-factor for low-sensitivity apps
    - domain: 'secure.example.com'
      policy: 'one_factor'
    # Two-factor required for the traefik dashboard
    - domain: 'traefik.example.com'
      policy: 'two_factor'
    # Everything else = deny
    - domain: '*.example.com'
      policy: 'two_factor'

session:
  name: 'authelia_session'
  secret: '<random-64-chars>'
  expiration: '1h'
  inactivity: '5m'
  remember_me: '1M'
  cookies:
    - domain: 'example.com'
      authelia_url: 'https://auth.example.com'

regulation:
  max_retries: 3
  find_time: '2m'
  ban_time: '5m'

storage:
  encryption_key: '<random-64-chars>'
  local:
    path: '/config/db.sqlite3'
  # Or for production, use postgres:
  # postgres:
  #   address: 'tcp://postgres:5432'
  #   database: 'authelia'
  #   username: 'authelia'
  #   password: '<pwd>'

notifier:
  smtp:
    address: 'smtp://smtp.example.com:587'
    sender: 'Authelia <noreply@example.com>'
    username: 'authelia'
    password: '<smtp-pwd>'
  # OR for dev:
  # filesystem:
  #   filename: '/config/notification.txt'
```

### Users file (`./authelia/users_database.yml`)

```yaml
users:
  alice:
    disabled: false
    displayname: 'Alice Example'
    password: '$argon2id$v=19$m=65536,t=3,p=4$...'   # generate via `authelia crypto hash generate argon2`
    email: 'alice@example.com'
    groups:
      - admins
      - users
```

Generate password hashes:

```bash
docker run --rm authelia/authelia:latest authelia crypto hash generate argon2 --password 'p@ssword'
```

## Secrets

Required random 64-char strings:

| Secret | Purpose |
|---|---|
| `identity_validation.reset_password.jwt_secret` | Signs password-reset JWTs |
| `session.secret` | Signs session cookies |
| `storage.encryption_key` | Encrypts TOTP secrets + WebAuthn creds + OIDC data in the storage DB |
| `identity_providers.oidc.hmac_secret` (if OIDC enabled) | OIDC token signing |

Generate: `openssl rand -hex 64`. Keep stable — rotating `storage.encryption_key` invalidates all 2FA + OIDC data.

## OIDC Provider (Authelia as OpenID Connect)

For apps that speak OIDC (Grafana, Nextcloud, Gitea, GitLab, Synapse, OpenWebUI, etc.), configure Authelia as an OpenID Provider:

```yaml
# configuration.yml
identity_providers:
  oidc:
    hmac_secret: '<random-64-chars>'
    jwks:
      - key_id: 'main'
        key: |
          -----BEGIN RSA PRIVATE KEY-----
          ...
          -----END RSA PRIVATE KEY-----
    clients:
      - client_id: 'grafana'
        client_name: 'Grafana'
        client_secret: '$pbkdf2-sha512$...'
        public: false
        authorization_policy: 'two_factor'
        redirect_uris:
          - 'https://grafana.example.com/login/generic_oauth'
        scopes: ['openid', 'profile', 'groups', 'email']
        userinfo_signing_alg: 'none'
```

Then Grafana's OIDC config points at `https://auth.example.com/.well-known/openid-configuration`.

Full OIDC docs: <https://www.authelia.com/integration/openid-connect/introduction/>.

## Data layout

| Path | Content |
|---|---|
| `./authelia/configuration.yml` | Main config |
| `./authelia/users_database.yml` | File-based user DB (if using `authentication_backend.file`) |
| `./authelia/db.sqlite3` | SQLite storage — TOTP secrets, WebAuthn credentials, regulation counters, OIDC data |
| `./authelia/notification.txt` | Dev-mode notifier output (if using `filesystem` notifier) |

Or externalize storage to Postgres / MySQL / MariaDB in production.

**Backup** = tar `./authelia/` (or dump Postgres if using). The SQLite DB + config files are what matter.

## Upgrade procedure

```bash
# Check release notes — semver-ish; breaking changes documented
# https://github.com/authelia/authelia/releases

docker compose pull
docker compose up -d
docker compose logs -f authelia
```

Authelia migrates the storage DB on startup. Config schema changes in minor versions are flagged on startup with helpful error messages.

## Gotchas

- **Parent domain matters.** All protected apps must share a parent domain with Authelia for the session cookie to work. `app1.example.com` + `app2.example.com` + `auth.example.com` — all ok. `app1.example.org` + `auth.example.com` — session cookie won't cross TLDs. For cross-domain setups, use OIDC Provider mode instead.
- **`session.cookies.domain` must match the parent domain** you want the cookie to cover. Setting it too narrow (e.g. `auth.example.com`) breaks SSO; setting it too broad (e.g. `com`) breaks because browsers reject.
- **Default `access_control.default_policy: deny` is recommended** — safer than `bypass` (anyone allowed) or `one_factor` (password-only). Explicit allow-lists avoid accidentally exposing apps.
- **`forwardAuth.authResponseHeaders` must include every header** you want to forward to backends. Missing `Remote-User` / `Remote-Groups` → backends can't identify users.
- **OIDC is beta-stable.** Works well; but flagged "beta" in docs for historical reasons. Most self-hosters use it in production. Read the integration guide before migrating apps to it.
- **`storage.encryption_key`** encrypts TOTP secrets + WebAuthn creds + OIDC tokens in the DB. Rotating it = all those secrets become unreadable. Back up before any rotation.
- **2FA enrollment requires email (SMTP) OR filesystem notifier.** On a fresh install with no SMTP, users can't receive the enrollment link. Use `filesystem:` for testing → read `/config/notification.txt` → copy link manually.
- **Regulator can lock you out.** 3 failed attempts (default) locks for 5 minutes. If you're debugging, turn off temporarily OR clear via `docker exec authelia authelia storage user regulate-unban --username=alice --config=/config/configuration.yml`.
- **WebAuthn requires HTTPS + exact origin match.** Testing on HTTP or a different hostname = WebAuthn registration fails silently.
- **`password` in `users_database.yml` is the argon2id hash, NOT the plaintext.** Generate via `authelia crypto hash generate argon2`. Paste the plaintext by accident = logins will never match.
- **Redis-backed sessions are required for multi-replica HA.** In-memory sessions don't sync across replicas — user hits replica 1, authenticates, gets bounced to replica 2, session gone, prompted to log in again.
- **LDAP integration is read-only.** Authelia doesn't create users in your LDAP; it authenticates against existing ones. Don't expect Authelia to become your LDAP management UI.
- **Password reset flow requires a working SMTP.** Test the email configuration BEFORE rolling out to users.
- **Traefik labels in Docker Compose are verbose.** Every protected app needs the same `middlewares: 'authelia@docker'` label. Use Docker Compose profiles + YAML anchors to DRY it up.
- **nginx integration needs lua-nginx module** (OpenResty or nginx-plus). Plain nginx with `ngx_http_auth_request_module` works but lacks some features.
- **Caddy integration via `forward_auth`** is clean — see <https://www.authelia.com/integration/proxies/caddy/>.
- **`default_redirection_url`** points users to a landing app after login (not the Authelia portal itself). Useful to avoid users wondering "what do I do now?"
- **Password policies** in config affect BOTH new-user creation AND password-reset. Too strict = users pick bad passwords they'll forget.
- **`log.level: debug`** is verbose — useful for first-setup debugging. Switch to `info` or `warn` in prod.
- **No admin UI.** Authelia is config-file-driven. No "Add User" button — edit `users_database.yml` and restart. For UI-based user mgmt, use LDAP backend + your LDAP's admin tool (LLDAP, FreeIPA, etc.).
- **Session inactivity (`inactivity: 5m`) is separate from expiration (`expiration: 1h`).** Inactivity is how long a session can sit idle; expiration is absolute max. Tune both for your UX.
- **Upgrading across major versions** (4.37 → 4.38) may introduce config renames — Authelia prints clear errors on startup. Fix + restart.
- **vs Keycloak/Authentik**: if you need full IdP features (federation, user provisioning, SCIM, SAML, complex flows, admin UI), look at Authentik or Keycloak. Authelia is for "I just want auth in front of my apps."

## Links

- Upstream repo: <https://github.com/authelia/authelia>
- Docs: <https://www.authelia.com>
- Docker Hub: <https://hub.docker.com/r/authelia/authelia>
- Getting started: <https://www.authelia.com/integration/prologue/get-started/>
- Lite compose example: <https://github.com/authelia/authelia/tree/master/examples/compose/lite>
- Production compose example: <https://github.com/authelia/authelia/tree/master/examples/compose/local>
- Helm chart: <https://charts.authelia.com>
- Proxy integrations: <https://www.authelia.com/integration/proxies/>
- OIDC integration: <https://www.authelia.com/integration/openid-connect/introduction/>
- Reference config: <https://www.authelia.com/configuration/prologue/reference/>
- Releases: <https://github.com/authelia/authelia/releases>
- APT repo: <https://apt.authelia.com>
- Discord: <https://discord.authelia.com>
- Matrix: <https://matrix.to/#/#support:authelia.com>
