---
name: keycloak-project
description: Keycloak recipe for open-forge. Apache-2.0 CNCF-incubating identity and access management platform — OIDC, SAML 2.0, OAuth 2.0 provider with user federation (LDAP/AD), social login, MFA, fine-grained authorization, realms/clients/roles model. Covers the dev-mode quickstart (`start-dev`), production config with external DB (PostgreSQL/MySQL/MariaDB), reverse-proxy setup (CRITICAL — Keycloak is picky about proxy headers), JVM vs native image, and the Keycloak Operator for Kubernetes. This is the serious-tier auth platform: complex, but canonical for "I need real SSO."
---

# Keycloak

Apache-2.0 CNCF-incubating identity and access management platform. Upstream: <https://github.com/keycloak/keycloak>. Docs: <https://www.keycloak.org/documentation.html>. Downloads: <https://www.keycloak.org/downloads.html>.

- **Standards support:** OpenID Connect (OIDC), OAuth 2.0 / 2.1, SAML 2.0, WS-Fed
- **User federation:** LDAP, Active Directory (sync users from existing directories)
- **Social / identity brokering:** Login via Google, GitHub, Microsoft, Facebook, Apple, or any external OIDC/SAML IdP
- **MFA:** TOTP, WebAuthn (passkeys), Recovery codes, OTP over email
- **Fine-grained authorization:** Role-based + attribute-based + policy engine (UMA 2.0)
- **Admin UI + account UI + REST admin API**
- **Multi-tenant (realms):** Each realm is an isolated auth universe

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker (`quay.io/keycloak/keycloak`) | <https://quay.io/keycloak/keycloak> | ✅ Recommended for self-host | Most self-hosted Keycloak deploys. |
| ZIP distribution | <https://www.keycloak.org/downloads.html> | ✅ | Bare metal / systemd. Runs on any system with Java 21+. |
| Keycloak Operator (Kubernetes) | <https://www.keycloak.org/operator/installation> | ✅ | K8s. CNCF-standard Operator for managing Keycloak + imports of realms as CRDs. |
| Helm chart | Bitnami / community | ⚠️ Community | Not first-party. Operator is preferred for K8s. |
| Build from source | Maven | ✅ | Core contributors. |
| Red Hat Build of Keycloak (RHBK) | Red Hat support subscription | Paid | Red Hat's supported, release-stabilized commercial build. |

**Legacy note:** Pre-v17 Keycloak was built on WildFly (JBoss EAP). Post-v17 it's built on Quarkus — very different config, simpler deploy, better startup time. **All modern docs assume Quarkus.** If you find old guides mentioning `standalone.xml` or `domain.xml`, they're for the EOL WildFly distribution. Don't use them.

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion`: `docker` / `zip-bare-metal` / `k8s-operator` | Drives section. |
| preflight | "Production or dev?" | `AskUserQuestion` | `start-dev` is fine for testing; `start` with full config is required for prod. Dev mode uses ephemeral H2 DB; anything beyond local demo needs Postgres/MySQL. |
| db | "Database?" | `AskUserQuestion`: `postgres (recommended)` / `mysql` / `mariadb` / `mssql` / `oracle` | Keycloak uses Hibernate; supports most major SQL DBs. |
| db | "DB host/port/user/pass/name?" | Free-text | Maps to `KC_DB_URL`, `KC_DB_USERNAME`, `KC_DB_PASSWORD`. |
| admin | "Initial bootstrap admin username/password?" | Free-text (sensitive) | Env: `KC_BOOTSTRAP_ADMIN_USERNAME` / `KC_BOOTSTRAP_ADMIN_PASSWORD`. Old `KEYCLOAK_ADMIN` vars still work but deprecated. |
| dns | "Public hostname?" | Free-text | `KC_HOSTNAME=auth.example.com`. **This MUST match the URL users reach** — Keycloak generates absolute URLs with this hostname in tokens, emails, OIDC discovery. Mismatch = client redirect failures. |
| tls | "TLS source?" | `AskUserQuestion`: `reverse-proxy (recommended)` / `keycloak-native-tls` | If reverse proxy, set `KC_PROXY_HEADERS=xforwarded` and `KC_HTTP_ENABLED=true`. |
| secrets | "HTTPS cert + key files?" | File paths | Only if `keycloak-native-tls`. |
| cluster | "Single node or HA cluster?" | `AskUserQuestion` | Single-node is fine for most. HA needs shared DB + cache topology (Infinispan). |

## Install — Docker (production-ish)

```yaml
# compose.yaml — production-style Keycloak with external Postgres
services:
  db:
    image: postgres:16-alpine
    restart: unless-stopped
    environment:
      POSTGRES_DB: keycloak
      POSTGRES_USER: keycloak
      POSTGRES_PASSWORD: ${KC_DB_PASSWORD}
    volumes:
      - keycloak-db:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U keycloak"]
      interval: 10s

  keycloak:
    image: quay.io/keycloak/keycloak:26.0    # pin a specific version
    restart: unless-stopped
    command: start --optimized       # see "start vs start-dev" below
    environment:
      # Bootstrap admin (first boot only)
      KC_BOOTSTRAP_ADMIN_USERNAME: admin
      KC_BOOTSTRAP_ADMIN_PASSWORD: ${KC_ADMIN_PASSWORD}

      # Database
      KC_DB: postgres
      KC_DB_URL: jdbc:postgresql://db:5432/keycloak
      KC_DB_USERNAME: keycloak
      KC_DB_PASSWORD: ${KC_DB_PASSWORD}

      # Hostname (must match reverse-proxy URL exactly)
      KC_HOSTNAME: https://auth.example.com
      KC_HOSTNAME_STRICT: 'true'
      KC_HOSTNAME_STRICT_HTTPS: 'true'

      # HTTP + reverse proxy
      KC_HTTP_ENABLED: 'true'
      KC_PROXY_HEADERS: xforwarded

      # Health endpoints
      KC_HEALTH_ENABLED: 'true'
      KC_METRICS_ENABLED: 'true'
    ports:
      - "127.0.0.1:8080:8080"      # bind to localhost; reverse proxy terminates TLS
    depends_on:
      db:
        condition: service_healthy
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:9000/health/ready || exit 1"]
      interval: 30s

volumes:
  keycloak-db:
```

```bash
cat > .env <<EOF
KC_DB_PASSWORD=$(openssl rand -hex 24)
KC_ADMIN_PASSWORD=$(openssl rand -base64 24)
EOF

docker compose up -d
docker compose logs -f keycloak
```

Visit `https://auth.example.com/` (via your reverse proxy) → admin console link. Log in with the bootstrap admin creds, **create a real admin user, delete the bootstrap admin.**

### `start` vs `start-dev`

| Mode | What it does | When |
|---|---|---|
| `start-dev` | H2 in-memory DB, no TLS enforcement, no hostname checks, fast iteration | Local dev only. Data lost on container restart. |
| `start` | Full production checks. Requires hostname, DB, TLS config. | Production. |
| `start --optimized` | Skips build-time optimization — assumes image was pre-built with `kc.sh build`. The official image IS pre-built, so `--optimized` is usually correct. | Production with official image. |

Do NOT run `start-dev` in production. It disables security checks.

## Install — ZIP (bare metal)

```bash
# Requires OpenJDK 21+
java -version

# Download
VERSION=26.0.0
curl -LO "https://github.com/keycloak/keycloak/releases/download/${VERSION}/keycloak-${VERSION}.zip"
sudo unzip "keycloak-${VERSION}.zip" -d /opt/
sudo ln -sfn "/opt/keycloak-${VERSION}" /opt/keycloak

# Configure (minimal production)
sudo tee /opt/keycloak/conf/keycloak.conf > /dev/null <<'EOF'
db=postgres
db-url=jdbc:postgresql://localhost/keycloak
db-username=keycloak
db-password=STRONGPASSWORD
hostname=https://auth.example.com
proxy-headers=xforwarded
http-enabled=true
EOF

# Pre-build (bakes config into a runtime image for fast start)
sudo /opt/keycloak/bin/kc.sh build

# Run
sudo KC_BOOTSTRAP_ADMIN_USERNAME=admin \
     KC_BOOTSTRAP_ADMIN_PASSWORD='strong-pass' \
     /opt/keycloak/bin/kc.sh start --optimized
```

### systemd unit

```ini
# /etc/systemd/system/keycloak.service
[Unit]
Description=Keycloak
After=network.target postgresql.service

[Service]
Type=exec
User=keycloak
Group=keycloak
EnvironmentFile=/etc/keycloak/keycloak.env     # contains KC_BOOTSTRAP_ADMIN_* on first boot
ExecStart=/opt/keycloak/bin/kc.sh start --optimized
Restart=on-failure
RestartSec=5s
LimitNOFILE=102642

[Install]
WantedBy=multi-user.target
```

## Install — Kubernetes Operator

```bash
# 1. Install the CRDs + operator
kubectl apply -f https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/26.0.0/kubernetes/keycloaks.k8s.keycloak.org-v1.yml
kubectl apply -f https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/26.0.0/kubernetes/keycloakrealmimports.k8s.keycloak.org-v1.yml
kubectl apply -f https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/26.0.0/kubernetes/kubernetes.yml

# 2. Create a Keycloak CR
cat <<EOF | kubectl apply -f -
apiVersion: k8s.keycloak.org/v2alpha1
kind: Keycloak
metadata:
  name: auth
  namespace: keycloak
spec:
  instances: 1
  db:
    vendor: postgres
    host: postgres.database.svc
    usernameSecret:
      name: keycloak-db-creds
      key: username
    passwordSecret:
      name: keycloak-db-creds
      key: password
  hostname:
    hostname: auth.example.com
  http:
    tlsSecret: keycloak-tls
EOF
```

Realms can be imported as CRDs (`KeycloakRealmImport`), making GitOps-managed Keycloak possible. See <https://www.keycloak.org/operator/advanced-configuration>.

## Reverse proxy — Caddy

```caddy
auth.example.com {
    reverse_proxy 127.0.0.1:8080 {
        header_up Host {host}
        header_up X-Forwarded-For {remote}
        header_up X-Forwarded-Proto {scheme}
    }
}
```

Keycloak reads `X-Forwarded-*` only if `KC_PROXY_HEADERS=xforwarded`. Caddy sets these headers by default; nginx/Traefik must be configured to send them.

### Reverse proxy — nginx

```nginx
server {
    listen 443 ssl http2;
    server_name auth.example.com;

    ssl_certificate /etc/letsencrypt/live/auth.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/auth.example.com/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_buffer_size 128k;
        proxy_buffers 4 256k;
    }
}
```

## First-login setup (every production Keycloak)

1. Log in to `/admin` as the bootstrap admin.
2. **Create a new realm** (don't use `master` for user-facing apps; `master` is Keycloak's own admin realm).
3. In that realm: configure identity providers (Google/GitHub/SAML/etc.), password policy, MFA requirements, client apps.
4. Create a long-lived admin user in the `master` realm with a strong password + MFA enabled.
5. **Delete the bootstrap admin** (`admin` account created by env vars): in `master` → Users → admin → Delete.
6. Back up realm config via Export (or set up KeycloakRealmImport CRs for GitOps).

## Clients: OIDC or SAML?

- **OIDC** for modern apps (most). Client app gets `client_id`, `client_secret`, and `issuer` URL (`https://auth.example.com/realms/<realm>`). Configure redirect URIs + web origins. Scopes = `openid profile email` + any custom.
- **SAML** for enterprise apps that don't speak OIDC (SharePoint, old JIRA, some SaaS). Configure Entity ID + ACS URL + SLO URL.

## Upgrade procedure

### Docker / K8s

```bash
# 1. Back up Postgres (Keycloak's DB has all realm/user/client config)
docker exec $(docker compose ps -q db) \
    pg_dump -U keycloak keycloak | gzip > keycloak-$(date +%F).sql.gz

# 2. Read release notes — EVERY version: https://www.keycloak.org/docs/latest/release_notes/
#    Pay attention to the "Migrating from N-1" section for schema changes.

# 3. Bump image tag
docker compose pull
docker compose up -d
docker compose logs -f keycloak
```

Keycloak runs schema migrations on startup. **Always back up first.** Major version jumps (e.g. 22 → 26) went through multiple breaking changes for admin console, realm config, account UI.

**Cross-major upgrades are one-step only if upstream says so.** Read release notes. Some versions require stepping through intermediate versions.

## Data layout

All data in the external DB (Postgres/MySQL/MariaDB/etc.). Keycloak itself is stateless (apart from Infinispan caches, which are in-memory).

**Backup = `pg_dump` the Keycloak DB** + whatever TLS certs/keystore files are mounted.

Export realms for portable config:

```bash
docker exec keycloak /opt/keycloak/bin/kc.sh export \
    --dir /tmp/export --realm my-realm --users realm_file
docker cp keycloak:/tmp/export ./keycloak-realms-export
```

## Gotchas

- **`KC_HOSTNAME` must match the URL users reach, exactly.** If users hit `https://auth.example.com/` but `KC_HOSTNAME=auth.internal.example.com`, OIDC discovery URLs, token issuers, and email links all point at the wrong host → clients fail to validate tokens.
- **Don't put Keycloak behind a path prefix unless you really mean it.** `KC_HTTP_RELATIVE_PATH=/auth` is legal but 10 kinds of edge cases (OIDC well-known paths, SAML endpoints, static assets). Only use if you MUST share a hostname.
- **`start-dev` is not for production.** Uses H2 in-memory DB → data lost on restart. Disables hostname + HTTPS checks. Only for local laptop testing.
- **The `master` realm is Keycloak's own admin. Don't use it for your users.** Always create a new realm for your actual application users. `master` is where the Keycloak super-admins live.
- **First-boot bootstrap admin with weak password = instant takeover.** Default `admin` username + any weak password = every script-kiddie in the world sees your Keycloak on Shodan. Use a strong `KC_BOOTSTRAP_ADMIN_PASSWORD`, then delete the bootstrap admin after creating your real one.
- **Reverse proxy headers are non-trivial.** `KC_PROXY_HEADERS=xforwarded` or `forwarded` must be set, AND the proxy must actually send them. Common error: nginx doesn't set `X-Forwarded-Proto` → Keycloak thinks requests are HTTP → generates HTTP URLs in cookies → browser blocks them on HTTPS origin.
- **Cookie domain / SameSite issues.** When Keycloak is behind a proxy, session cookies are issued for `KC_HOSTNAME`. SameSite=Lax is default; for cross-site OAuth flows (very common), may need tweaking.
- **Keycloak token signatures use RS256 by default.** Store the realm's private keys safely — if leaked, anyone can forge tokens. Key rotation is built-in: Realm settings → Keys → add new active key, deactivate old. Old tokens expire naturally.
- **JVM startup is slow.** Cold start of Docker image is 30-90 seconds for `start`, 10-20 seconds for `start --optimized` (pre-built). Kubernetes liveness probes need adequate `initialDelaySeconds`.
- **Native image exists** (`quay.io/keycloak/keycloak:X-native`) — faster startup, lower memory, but some features (certain providers, custom SPIs) don't work. Only use native if you've verified your setup doesn't need the JVM.
- **LDAP federation can de-sync.** When adding LDAP as a user federation provider, test import on a small OU first. Bad LDAP attribute mapping can corrupt user records; undoing requires DB surgery.
- **No built-in SMTP.** Password-reset emails, verify-email, invitation emails all require configuring SMTP in **Realm Settings → Email**. Without it, users can't reset passwords.
- **Offline tokens + refresh tokens** are forever (by default) — if a client's refresh token leaks, it's a perpetual backdoor until revoked in admin console. Shorten `SSO Session Idle` in Realm Settings → Sessions for hardened setups.
- **CORS and "Web Origins" are separate from redirect URIs.** A client's `Valid Redirect URIs` controls OAuth redirect; `Web Origins` controls CORS. Both needed for SPA clients.
- **Infinispan clustering config is subtle.** HA Keycloak needs Infinispan to share session state across nodes — by default it uses UDP multicast (which does NOT work in cloud). For cloud/K8s: use TCP + JDBC_PING or DNS_PING cache stack. See <https://www.keycloak.org/server/caching>.

## Links

- Upstream repo: <https://github.com/keycloak/keycloak>
- Docs: <https://www.keycloak.org/documentation.html>
- Server guides: <https://www.keycloak.org/guides#server>
- Operator: <https://www.keycloak.org/operator/installation>
- Release notes: <https://www.keycloak.org/docs/latest/release_notes/>
- Docker image: <https://quay.io/keycloak/keycloak>
- Downloads: <https://www.keycloak.org/downloads.html>
- Community: <https://cloud-native.slack.com/archives/C056HC17KK9> (`#keycloak` on CNCF Slack)
- Mailing list: <https://groups.google.com/d/forum/keycloak-user>
