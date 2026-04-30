---
name: Tinyauth
description: "Tiny forward-auth server for reverse proxies (Traefik, Nginx, Caddy). Gates self-hosted services behind login. Supports OAuth, LDAP, access-control rules. Standalone-capable. Go. GPL-3.0."
---

# Tinyauth

**"The tiniest authentication and authorization server you have ever seen."**

Tinyauth is a **forward-auth middleware** for reverse proxies — drop it in front of your self-hosted services (Jellyfin without its own login, Uptime Kuma, a raw Prometheus UI, anything that lacks auth or where you want a second factor) and it gates access with a login page + optional OAuth / LDAP / ACL checks. Works with Traefik, Nginx, and Caddy's forward-auth directives.

In spirit it's a smaller cousin of **Authelia** and **Authentik** — same pattern (proxy asks Tinyauth "is this request OK?" → Tinyauth says yes/no + sets cookie), way less config surface.

> **Upstream warning (verbatim):** _"Tinyauth is in active development and configuration may change often. Please make sure to carefully read the release notes before updating."_

> **Org rename:** the project moved from its original org to `tinyauthapp/tinyauth` — use the new org name in all URLs. Old paths may still redirect but won't receive updates.

Features:

- **Forward-auth endpoint** — `/api/auth/nginx` / `/api/auth/traefik` / `/api/auth/caddy`
- **Local users** (username/password)
- **OAuth providers** — Google, GitHub, generic OIDC
- **LDAP** — bind against existing directory
- **Access controls** — per-resource allowlist (by user, group, IP, URL pattern)
- **TOTP 2FA**
- **Remember me** cookies
- **Login page** — branding customizable
- **Small + fast** — Go binary, minimal deps
- **Works standalone** too — can gate a single app directly without a proxy

- Upstream repo: <https://github.com/tinyauthapp/tinyauth>
- Website: <https://tinyauth.app>
- Docs: <https://tinyauth.app/docs>
- Demo: <https://demo.tinyauth.app> (`user` / `password`)
- Discord: <https://discord.gg/eHzVaCzRRd>

## Architecture in one minute

- **Go** binary; small container image
- **Forward-auth flow**: reverse proxy intercepts request → calls Tinyauth `/api/auth/*` → Tinyauth checks cookie/session → returns 200 (allow) or 302 (redirect to login)
- **State**: session in cookies (signed) or Redis (optional for HA)
- **User store**: flat file / env / env-secret / LDAP / OAuth
- **Resource**: ~20-50 MB RAM

## Compatible install methods

| Infra       | Runtime                                        | Notes                                                              |
| ----------- | ---------------------------------------------- | ------------------------------------------------------------------ |
| Single VM   | **Docker** (alongside Traefik/Caddy/Nginx)        | **The way**                                                            |
| Bare metal  | Go binary                                              | systemd service                                                            |
| Kubernetes  | Deployment + Service; paired with ingress-nginx auth-url       | Standard K8s forward-auth pattern                                                  |

## Inputs to collect

| Input            | Example                               | Phase      | Notes                                                           |
| ---------------- | ------------------------------------- | ---------- | --------------------------------------------------------------- |
| Cookie domain    | `.example.com`                           | Session    | Shared cookie across subdomains = SSO across all gated apps         |
| Session secret   | random 32+ chars                                | Crypto     | Don't rotate without invalidating sessions                               |
| Users            | `user:bcrypt-hash-of-password`                        | Auth       | Or via LDAP / OAuth                                                                 |
| Protected apps   | hostnames                                                  | Proxy      | Configured in your reverse proxy, not Tinyauth directly                                       |
| OAuth creds (opt)| client_id + client_secret per provider                               | Auth       | Google/GitHub/custom OIDC                                                                                 |
| LDAP (opt)       | URL + bindDN + baseDN                                                      | Auth       | For existing directory                                                                                              |

## Install via Docker (Traefik example)

```yaml
services:
  traefik:
    image: traefik:v3
    ports: ["80:80", "443:443"]
    command:
      - "--providers.docker"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"

  tinyauth:
    image: ghcr.io/tinyauthapp/tinyauth:latest      # pin specific version in prod
    container_name: tinyauth
    restart: unless-stopped
    environment:
      - SECRET=<random-32-chars>
      - APP_URL=https://auth.example.com
      - COOKIE_DOMAIN=example.com
      - USERS=user:$2a$10$...    # htpasswd-style bcrypt
      # - OAUTH_GOOGLE_CLIENT_ID=...
      # - OAUTH_GOOGLE_CLIENT_SECRET=...
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.tinyauth.rule=Host(`auth.example.com`)"
      - "traefik.http.routers.tinyauth.entrypoints=websecure"
      - "traefik.http.routers.tinyauth.tls.certresolver=letsencrypt"
      - "traefik.http.middlewares.tinyauth.forwardauth.address=http://tinyauth:3000/api/auth/traefik"
      - "traefik.http.middlewares.tinyauth.forwardauth.trustForwardHeader=true"
      - "traefik.http.middlewares.tinyauth.forwardauth.authResponseHeaders=Remote-User,Remote-Email,Remote-Name,Remote-Groups"

  whoami:
    image: traefik/whoami
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.whoami.rule=Host(`whoami.example.com`)"
      - "traefik.http.routers.whoami.entrypoints=websecure"
      - "traefik.http.routers.whoami.tls.certresolver=letsencrypt"
      - "traefik.http.routers.whoami.middlewares=tinyauth@docker"  # GATED
```

Browse `whoami.example.com` → redirects to `auth.example.com` → log in → redirects back authenticated.

## Nginx forward-auth snippet

```nginx
location = /tinyauth {
    internal;
    proxy_pass http://tinyauth:3000/api/auth/nginx;
    proxy_pass_request_body off;
    proxy_set_header Content-Length "";
    proxy_set_header X-Original-URI $request_uri;
}

location / {
    auth_request /tinyauth;
    error_page 401 = @redirect_to_login;
    # pass Remote-User etc. back to upstream
    auth_request_set $user $upstream_http_remote_user;
    proxy_set_header X-Remote-User $user;
    proxy_pass http://backend;
}

location @redirect_to_login {
    return 302 https://auth.example.com/login?redirect_uri=$scheme://$host$request_uri;
}
```

## First boot

1. Start Tinyauth + your reverse proxy (as above)
2. Generate a user password hash:
   ```sh
   htpasswd -nbB user hunter2
   # Output: user:$2y$05$...  → use in USERS env
   ```
3. Browse a gated service (e.g., `whoami.example.com`) → redirect to login → enter creds → redirect back
4. Cookie set on `example.com` = SSO across all subdomains gated by the same Tinyauth

## Data & config layout

- Session: cookies (signed with SECRET)
- Users: env var `USERS` or file
- Config: env variables (see upstream docs for full list)

Stateless except for session storage choice. No DB needed unless using Redis for session.

## Backup

Back up your **config/env** — that's all state. Users in env = part of your infra-as-code. Sessions are regenerable.

## Upgrade

1. Releases: <https://github.com/tinyauthapp/tinyauth/releases>. Active; breaking changes possible (upstream warns).
2. **Read release notes before upgrading.** Config env variable names have changed across releases.
3. Docker: bump tag, pull, up -d.
4. Test a gated URL after upgrade; fix any env name mismatches.

## Gotchas

- **Active development → breaking config changes** — explicit warning from upstream README. Pin versions + test on staging before prod.
- **Organization rename** to `tinyauthapp` — make sure you're pulling from `ghcr.io/tinyauthapp/tinyauth` (not the old path).
- **Cookie domain for SSO**: set `COOKIE_DOMAIN=example.com` (leading dot optional); single-cookie SSO works only if all gated apps are subdomains of the same parent domain.
- **HTTPS required for cookies `Secure` flag** — if you test over HTTP, session cookies don't persist. Always test behind TLS.
- **SameSite cookies** — default `Lax`; some cross-site OAuth flows need `None` + `Secure`. Check docs for your OAuth provider.
- **bcrypt the passwords** — don't put plaintext in USERS. Use `htpasswd -bnB`.
- **Rate limiting** — Tinyauth has some; pair with fail2ban or proxy-level rate limiting for brute-force resistance.
- **2FA (TOTP)** — enroll via the UI; enforce if you want. Backup codes are critical — store them somewhere.
- **LDAP bind** — if LDAP is unreachable, users can't log in. Plan for LDAP outages.
- **ACL model** — per-resource allowlist is text-based; simpler than Authelia's YAML but less powerful. For complex RBAC, consider Authelia/Authentik.
- **No forward-auth = no protection** — Tinyauth only works because your reverse proxy asks it. Misconfigured proxy = bypass. Test by curl-ing the gated URL without a cookie and verify a 302/redirect to login.
- **Logout**: clear cookies via Tinyauth's `/logout` endpoint. Some single-page apps don't propagate logout to Tinyauth; provide an explicit logout link.
- **Standalone mode**: can also run Tinyauth WITHOUT a reverse proxy, serving its own login + forwarding to an upstream. Useful for gating a single app.
- **Performance**: ~20-50 MB RAM, minimal CPU. Serves thousands of auth checks/sec easily.
- **License**: GPL-3.0.
- **Alternatives worth knowing:**
  - **Authelia** — YAML-configured forward-auth with 2FA, LDAP, LDAP users, ACL, backup codes (separate recipe)
  - **Authentik** — Keycloak-like featureful SSO + forward-auth + provider modes (separate recipe)
  - **oauth2-proxy** — OAuth-only forward-auth; Google/GitHub/OIDC in front of apps
  - **Pocket ID** — passkey-only OIDC (separate recipe, batch 57)
  - **Keycloak** — enterprise SSO; complex
  - **Traefik forward-auth-middleware** only — for quickest "just ask Google" auth
  - **Choose Tinyauth if:** you want the smallest/simplest forward-auth for a handful of gated apps with local users + optional OAuth.
  - **Choose Authelia if:** you want a more mature similar-surface tool.
  - **Choose Authentik if:** you need broader protocol coverage (SAML, LDAP provider).
  - **Choose oauth2-proxy if:** you want OAuth-only in front of a single app.

## Links

- Repo: <https://github.com/tinyauthapp/tinyauth>
- Website: <https://tinyauth.app>
- Docs: <https://tinyauth.app/docs>
- Getting started: <https://tinyauth.app/docs/getting-started>
- Demo: <https://demo.tinyauth.app>
- Discord: <https://discord.gg/eHzVaCzRRd>
- Releases: <https://github.com/tinyauthapp/tinyauth/releases>
- Example compose: <https://github.com/tinyauthapp/tinyauth/blob/main/docker-compose.example.yml>
- Traefik forward-auth docs: <https://doc.traefik.io/traefik/middlewares/http/forwardauth/>
- Nginx auth_request docs: <https://nginx.org/en/docs/http/ngx_http_auth_request_module.html>
- Authelia alternative: <https://www.authelia.com>
- Authentik alternative: <https://goauthentik.io>
- oauth2-proxy alternative: <https://github.com/oauth2-proxy/oauth2-proxy>
