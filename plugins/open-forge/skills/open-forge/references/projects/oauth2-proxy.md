---
name: OAuth2 Proxy
description: Reverse-proxy / middleware that adds OAuth2 / OIDC authentication in front of any web application. Google / Microsoft Entra / GitHub / GitLab / Keycloak / Dex / generic OIDC. Go, single binary. MIT.
---

# OAuth2 Proxy

OAuth2 Proxy is the battle-tested auth layer you put in front of any self-hosted service that doesn't have its own login (Prometheus, Grafana's anonymous mode, internal Kibana, a Node-RED flow, Jupyter, …). It authenticates users against an OAuth2 / OIDC provider, issues a session cookie, and then either:

- **Standalone reverse proxy mode**: proxies requests to your upstream after authenticating
- **Middleware / forward-auth mode**: returns 202/401 to an existing nginx / Traefik / Caddy, which then passes the user through — most common in Kubernetes + Ingress-controller setups

Forked from Bitly's long-unmaintained `bitly/oauth2_proxy` in 2018; now maintained by a dedicated org.

- Upstream repo: <https://github.com/oauth2-proxy/oauth2-proxy>
- Docs: <https://oauth2-proxy.github.io/oauth2-proxy>
- Install docs: <https://oauth2-proxy.github.io/oauth2-proxy/installation>
- Providers: <https://oauth2-proxy.github.io/oauth2-proxy/configuration/providers/>
- Container: `quay.io/oauth2-proxy/oauth2-proxy` (and `ghcr.io`)

## Architecture in one minute

One Go binary. Two deployment patterns:

1. **Reverse-proxy mode** — browser → oauth2-proxy (auth + proxy) → upstream. Upstream sees `X-Forwarded-*` + `X-Auth-Request-*` headers with user identity.
2. **Forward-auth / middleware mode** — browser → nginx-auth-request (or Traefik ForwardAuth) → oauth2-proxy (returns 202 or 401) → nginx proxies to upstream on 202. Pattern used by nginx-ingress-controller + Kubernetes.

Session storage: in-memory (stateless, cookie holds everything encrypted), Redis (shared across replicas), or file.

Since v7.6.0 the base image is distroless (smaller attack surface); `-alpine` variant still available for debugging.

## Compatible install methods

| Infra                    | Runtime                                              | Notes                                                                  |
| ------------------------ | ---------------------------------------------------- | ---------------------------------------------------------------------- |
| Single VM                | Docker (`quay.io/oauth2-proxy/oauth2-proxy`)         | **Recommended** — single container in front of one app                 |
| Single VM                | Binary + systemd                                     | Trivial: one file, one unit                                            |
| Kubernetes               | Helm chart + nginx/Traefik `ForwardAuth`             | **Most common production pattern**                                     |
| Multi-replica            | Docker + Redis session store                         | Scale out without sticky sessions                                      |
| Per-app sidecar          | Docker Compose, one oauth2-proxy per service        | Fine; wasteful of resources vs shared instance                         |

## Inputs to collect

| Input                     | Example                                          | Phase     | Notes                                                           |
| ------------------------- | ------------------------------------------------ | --------- | --------------------------------------------------------------- |
| OAuth provider            | Google / Entra / GitHub / GitLab / Keycloak / OIDC | Provider | Registered client (Web Application type)                         |
| `client_id` + `client_secret` | from provider                                | Provider  | Store `client_secret` as a secret                                |
| `oidc_issuer_url`         | `https://accounts.google.com`                    | Provider  | For OIDC mode (preferred when possible)                          |
| `redirect_url`            | `https://auth.example.com/oauth2/callback`       | Provider  | Must match exactly what you registered at the provider           |
| `cookie_secret`           | `openssl rand -base64 32 \| tr -- '+/' '-_'`    | Runtime   | **Required.** 16, 24, or 32 bytes. Shorter = bad, longer = wrong size error |
| `cookie_domain(s)`        | `.example.com`                                   | Runtime   | For SSO across subdomains                                        |
| `whitelist_domains`       | `.example.com`                                   | Security  | Allow-list for post-login redirect targets                       |
| `email_domains`           | `example.com` or `*`                             | Authz     | Which email domains may sign in                                  |
| Upstream URL              | `http://grafana:3000`                            | Proxy     | Where to forward authenticated requests                          |
| Session store             | `cookie` (default) / `redis` / `file`            | Runtime   | Redis required for multi-replica                                 |

## Install via Docker Compose (reverse-proxy mode)

From upstream example <https://github.com/oauth2-proxy/oauth2-proxy/tree/master/contrib/local-environment>:

```yaml
services:
  oauth2-proxy:
    image: quay.io/oauth2-proxy/oauth2-proxy:v7.15.2    # pin; NEVER use :latest in prod
    container_name: oauth2-proxy
    command: --config /oauth2-proxy.cfg
    volumes:
      - ./oauth2-proxy.cfg:/oauth2-proxy.cfg:ro
    ports:
      - 4180:4180/tcp
    restart: unless-stopped
    depends_on:
      - upstream
    networks: [front]

  upstream:
    image: whatever/your-app:tag
    networks: [front]

networks:
  front: {}
```

`oauth2-proxy.cfg`:

```ini
http_address = "0.0.0.0:4180"
cookie_secret = "REPLACE_WITH_OPENSSL_RAND_BASE64_32"
cookie_secure = "true"
cookie_domains = [".example.com"]
whitelist_domains = [".example.com"]
email_domains = ["example.com"]
upstreams = ["http://upstream:80"]

provider = "oidc"
provider_display_name = "My SSO"
oidc_issuer_url = "https://auth.example.com/realms/main"   # Keycloak example
client_id = "my-app"
client_secret = "REPLACE"
redirect_url = "https://app.example.com/oauth2/callback"

# Optional hardening:
skip_provider_button = true       # auto-redirect to provider; no intermediate "sign in with X" button
pass_access_token = true          # pass OAuth access token to upstream as header
set_xauthrequest = true
```

## Install via Docker (forward-auth mode, behind nginx/Traefik)

In forward-auth mode, nginx/Traefik calls `GET /oauth2/auth` on oauth2-proxy; 202 = let through, 401 = redirect to `/oauth2/sign_in`.

Traefik dynamic config (file or docker labels):

```yaml
http:
  middlewares:
    auth:
      forwardAuth:
        address: "http://oauth2-proxy:4180/oauth2/auth"
        trustForwardHeader: true
        authResponseHeaders:
          - X-Auth-Request-User
          - X-Auth-Request-Email
          - X-Auth-Request-Groups
          - Authorization
```

nginx:

```nginx
location /oauth2/ {
    proxy_pass       http://oauth2-proxy:4180;
    proxy_set_header Host                    $host;
    proxy_set_header X-Real-IP               $remote_addr;
    proxy_set_header X-Scheme                $scheme;
    proxy_set_header X-Auth-Request-Redirect $request_uri;
}

location /oauth2/auth {
    proxy_pass       http://oauth2-proxy:4180;
    proxy_set_header Host             $host;
    proxy_set_header X-Real-IP        $remote_addr;
    proxy_set_header X-Scheme         $scheme;
    # Auth check is internal only
    proxy_pass_request_body off;
    proxy_set_header Content-Length   "";
}

location / {
    auth_request /oauth2/auth;
    error_page 401 = /oauth2/sign_in;

    auth_request_set $user   $upstream_http_x_auth_request_user;
    auth_request_set $email  $upstream_http_x_auth_request_email;
    proxy_set_header X-User  $user;
    proxy_set_header X-Email $email;

    proxy_pass http://my-app:8080;
}
```

## Provider quickstarts

All docs at <https://oauth2-proxy.github.io/oauth2-proxy/configuration/providers/>. Headline settings:

- **Google** — `provider=google`, `client_id`/`client_secret` from GCP Console, optionally `google_group` to restrict to a Workspace group
- **Microsoft Entra ID (Azure AD)** — `provider=entra-id`, `oidc_issuer_url=https://login.microsoftonline.com/<tenant-id>/v2.0`
- **GitHub** — `provider=github`, with `github_org` / `github_team` to restrict
- **GitLab** — `provider=gitlab`, with `gitlab_group` / `gitlab_projects`
- **Keycloak** — `provider=oidc`, `oidc_issuer_url=https://kc.example.com/realms/main`
- **Dex** — `provider=oidc`, same pattern
- **Generic OIDC** — `provider=oidc`, any OIDC-compliant provider

## Data & config layout

Either:

- **File config** (`--config /oauth2-proxy.cfg`) — INI-like, easiest
- **Alpha config** (YAML) — upstream's next-gen format with more structured options; docs at <https://oauth2-proxy.github.io/oauth2-proxy/configuration/alpha-config>
- **CLI flags** — `--cookie-secret`, `--upstream`, etc.
- **Env vars** — any flag as `OAUTH2_PROXY_<NAME>` (dashes → underscores)

Session storage:

- `cookie` (default) — session in an encrypted cookie; zero server state
- `redis` — `--session-store-type=redis --redis-connection-url=...`
- `file` — `--session-store-type=file --session-store-path=...`

## Backup

Nothing persistent unless you chose `redis` or `file` session store. Even then, loss = users log in again. Config file (`oauth2-proxy.cfg`) is the only thing to back up; keep it in version control (secrets in a sealed vault, not the file).

## Upgrade

1. Releases: <https://github.com/oauth2-proxy/oauth2-proxy/releases>.
2. Docker: `docker compose pull && docker compose up -d`. No migrations.
3. **Read the changelog.** Breaking config changes happen between minor versions (v7.4 vs v7.5 renamed `--provider=azure` to `--provider=entra-id`).
4. **Distroless base since v7.6.0.** Older debugging habits (exec into container, install tools) don't work; use `-alpine` tag for debugging.
5. Alpha config (YAML) has evolved between releases — watch for rename of fields.

## Gotchas

- **`cookie_secret` MUST be 16, 24, or 32 bytes.** Other lengths silently fail or fail at startup. Generate with `openssl rand -base64 32 | tr -- '+/' '-_' | head -c 32`.
- **`cookie_secret` rotation logs everyone out.** Plan for it during off-hours.
- **Default CLI flags vs config file.** Order of precedence: CLI > env > config file. Mixing all three is a debugging nightmare; pick one.
- **`--provider=azure` is DEPRECATED** (removed in v7.11+); use `--provider=entra-id` or generic `--provider=oidc` with Entra's OIDC issuer URL.
- **`cookie_domain` + `cookie_secure` interplay.** `cookie_secure=true` (required for prod) + `cookie_domain=example.com` means browsers send the cookie over HTTPS only to `*.example.com`. Localhost testing needs `cookie_secure=false`.
- **Redirect URI must match exactly.** Provider dashboards reject `https://auth.example.com/oauth2/callback` if you configured `https://auth.example.com:443/oauth2/callback`. Watch for trailing slashes, port numbers, HTTP vs HTTPS.
- **`whitelist_domains` prevents open-redirect attacks.** Always set it. Without, an attacker can craft a link `/oauth2/sign_in?rd=https://evil.com` that logs users in, then redirects to an attacker page.
- **`email_domains=["*"]` is public signup.** Anyone with a valid OIDC token from your provider can in. For true allow-list, use `authenticated_emails_file` with one email per line.
- **Group-based authorization is provider-specific.** `--google-group`, `--github-team`, `--keycloak-group` have different semantics. OIDC groups via `--allowed-group` + `--scope=groups` is more portable but requires provider to include groups in the ID token.
- **Session cookie size grows with groups + access tokens.** Passing the access token + 50+ group memberships can exceed browser cookie size limits (4 KB). Use Redis session store or trim claims.
- **Behind a reverse proxy, `--reverse-proxy=true`** so oauth2-proxy honors `X-Forwarded-*` headers. Without it, it thinks every request comes from the proxy IP.
- **Refresh token handling** varies by provider. Some (Google) return refresh tokens only on first consent (`access_type=offline`); you'll need to force consent with `approval_prompt=force` or similar.
- **CSRF on OAuth flow.** oauth2-proxy uses `state` + a cookie for CSRF protection. Disabling `cookie_csrf_per_request=false` is generally safe; leaving defaults is safer.
- **Graceful upstream failure.** If the upstream is down, oauth2-proxy returns a 502 — but the user stays logged in. No need to re-auth when upstream comes back.
- **Audit: no built-in log of who logged in when.** Middleware like Ory Hydra + Ory Oathkeeper or Authentik provides audit logging. oauth2-proxy is minimal; parse access logs for auth events.
- **Alpha config (YAML)** supports more features (multiple upstreams on one oauth2-proxy, per-path rules) but is less stable across versions. Stick to INI config unless you specifically need alpha features.
- **`--skip-provider-button=true`** gives users a seamless login (no "Sign in with Google" intermediate page). Good UX for single-provider setups.
- **Alternatives worth knowing:**
  - **Authelia** — more integrated (TOTP + WebAuthn + LDAP backend); heavier
  - **Authentik** — all-in-one IDP + forward-auth; huge feature set
  - **Pomerium** — policy-based; richer ZeroTrust story
  - **Keycloak Gatekeeper** (deprecated) → Keycloak no longer ships this; use oauth2-proxy

## Links

- Repo: <https://github.com/oauth2-proxy/oauth2-proxy>
- Docs: <https://oauth2-proxy.github.io/oauth2-proxy>
- Installation: <https://oauth2-proxy.github.io/oauth2-proxy/installation>
- Configuration overview: <https://oauth2-proxy.github.io/oauth2-proxy/configuration/overview>
- Providers: <https://oauth2-proxy.github.io/oauth2-proxy/configuration/providers/>
- Alpha config (YAML): <https://oauth2-proxy.github.io/oauth2-proxy/configuration/alpha-config>
- Local examples: <https://github.com/oauth2-proxy/oauth2-proxy/tree/master/contrib/local-environment>
- Releases: <https://github.com/oauth2-proxy/oauth2-proxy/releases>
- Images (distroless): <https://quay.io/repository/oauth2-proxy/oauth2-proxy>
- Images (alpine): `-alpine` suffix on the same tags
- Nginx forward-auth example: <https://oauth2-proxy.github.io/oauth2-proxy/configuration/integration#configuring-for-use-with-the-nginx-auth_request-directive>
- Kubernetes nginx-ingress example: <https://kubernetes.github.io/ingress-nginx/examples/auth/oauth-external-auth/>
