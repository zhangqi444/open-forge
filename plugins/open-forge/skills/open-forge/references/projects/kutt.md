---
name: Kutt
description: Self-hosted URL shortener with custom domains, per-link passwords/expirations/descriptions, OIDC login, private analytics, admin UI. Node.js + SQLite/Postgres/MySQL. MIT.
---

# Kutt

Kutt is a modern, self-hostable URL shortener. Paste a long URL, get a short one at your own domain (`short.example.com/abc`), and optionally track clicks with private analytics — no third-party tracking like bit.ly.

Key features:

- **Custom domains** — users (with permission) can add their own domain
- **Custom slugs** — `short.example.com/my-talk` instead of a random code
- **Per-link password** — protect sensitive short links
- **Per-link description** + **expiration** + **link banner**
- **Private analytics** — per-link click stats (server-side only)
- **Browser extensions** — Firefox, Chrome, Edge
- **OIDC login** — Keycloak / Zitadel / Logto / etc.
- **Admin UI** — manage users, ban abusive links, see all links
- **Disable registration** + **disable anonymous links** — lockdown modes
- **REST API** — for automation / custom integrations
- **No build step** — Node.js package, runs on a VPS directly
- **SQLite default** OR Postgres / MySQL / MariaDB
- **Redis** optional (cache)

- Upstream repo: <https://github.com/thedevs-network/kutt>
- Website: <https://kutt.it> (noted: `.it` domain was suspended; also accessible at `kutt.to`)
- Docs: <https://docs.kutt.it>
- Docker Hub: <https://hub.docker.com/r/kutt/kutt>

## Architecture in one minute

- **Single Node.js app** (Express + Preact)
- **Database** (SQLite default, Postgres/MySQL/MariaDB optional)
- **Redis** (optional) for caching
- **Port 3000** inside container
- Stateless except for DB — horizontal scaling possible

## Compatible install methods

| Infra       | Runtime                                         | Notes                                                             |
| ----------- | ----------------------------------------------- | ----------------------------------------------------------------- |
| Single VM   | Docker / Compose                                 | **Most common**                                                    |
| Single VM   | Native Node.js 20+                                | From source; no build step                                          |
| Kubernetes  | Community Helm charts                              | Stateless app + DB                                                   |
| Cloud PaaS  | Heroku / Railway / Fly                             | One-click deploys community-maintained                                |

## Inputs to collect

| Input                  | Example                             | Phase     | Notes                                                          |
| ---------------------- | ----------------------------------- | --------- | -------------------------------------------------------------- |
| `DEFAULT_DOMAIN`       | `short.example.com`                  | DNS       | **PERMANENT** — the base URL for generated short links           |
| `SITE_NAME`            | `Example Links`                      | Branding  | Shown in UI + emails                                              |
| `PORT`                 | `3000`                               | Network   | Default                                                          |
| `JWT_SECRET`           | `openssl rand -hex 64`                | Security  | Session signing; **losing = all users logged out**                 |
| `ADMIN_EMAILS`         | `admin@example.com`                  | Bootstrap | Bootstrapping: first of these to register becomes admin            |
| Database URL           | `postgres://...` OR SQLite path        | DB        | Default: SQLite at `/var/lib/kutt/db.sqlite`                        |
| Redis URL (optional)   | `redis://redis:6379/0`                 | Cache     | Optional; speeds up resolve for busy instances                       |
| SMTP                   | host + port + creds                     | Email     | For registration / password reset / link notifications               |
| hCaptcha / reCAPTCHA   | site key + secret                       | Anti-spam | To prevent bot registrations + link creation                           |
| OIDC                   | issuer + client + secret                 | Auth SSO  | For SSO instead of / alongside local accounts                            |

## Install via Docker Compose (Postgres + Redis)

```yaml
services:
  kutt:
    image: kutt/kutt:3.x.x     # pin; check Docker Hub
    container_name: kutt
    restart: unless-stopped
    depends_on:
      postgres: { condition: service_healthy }
      redis: { condition: service_started }
    ports:
      - "3000:3000"
    environment:
      DEFAULT_DOMAIN: short.example.com
      SITE_NAME: Example Links
      JWT_SECRET: <openssl rand -hex 64>
      ADMIN_EMAILS: admin@example.com
      DB_URI: postgresql://kutt:<strong>@postgres:5432/kutt
      REDIS_HOST: redis
      # SMTP
      # MAIL_HOST: smtp.example.com
      # MAIL_PORT: 587
      # MAIL_USER: ...
      # MAIL_PASSWORD: ...
      # MAIL_FROM: Kutt <noreply@example.com>
      # OIDC (optional)
      # OIDC_ISSUER: https://auth.example.com
      # OIDC_CLIENT_ID: kutt
      # OIDC_CLIENT_SECRET: ...
      # OIDC_REDIRECT_URI: https://short.example.com/oauth/callback
      # OIDC_DISCOVERY_ENDPOINT: https://auth.example.com/.well-known/openid-configuration

  postgres:
    image: postgres:17-alpine
    container_name: kutt-db
    restart: unless-stopped
    environment:
      POSTGRES_USER: kutt
      POSTGRES_PASSWORD: <strong>
      POSTGRES_DB: kutt
    volumes:
      - kutt-db:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U kutt"]
      interval: 10s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: kutt-redis
    restart: unless-stopped
    volumes:
      - kutt-redis:/data

volumes:
  kutt-db:
  kutt-redis:
```

## Install natively (Node.js)

```sh
# Requires Node 20+
git clone https://github.com/thedevs-network/kutt
cd kutt
cp .env.example .env
# edit .env: DEFAULT_DOMAIN, JWT_SECRET, ADMIN_EMAILS, etc.
npm install
npm run start
# Listens on $PORT (default 3000)
```

First access → wizard prompts you to create the admin account.

## First boot

1. Browse `https://short.example.com`
2. Register with one of the `ADMIN_EMAILS` → first-user-is-admin for that email
3. Admin UI available at `/admin`
4. Set `DISALLOW_REGISTRATION=true` + `DISALLOW_ANONYMOUS_LINKS=true` in env to lock down for private use
5. (Optional) Add custom domain — users with permission can add domains; DNS-level you'll need to proxy those domains to the Kutt instance

## Data & config layout

Inside the container:

- `/var/lib/kutt/db.sqlite` — SQLite DB (if not using Postgres/MySQL)
- `custom/` — custom templates / CSS (if using themes)
- Session secrets, API keys, OIDC creds — all in env, not on disk

## Backup

```sh
# Postgres
docker compose exec -T postgres pg_dump -U kutt kutt | gzip > kutt-db-$(date +%F).sql.gz

# SQLite path
cp /var/lib/kutt/db.sqlite kutt-$(date +%F).sqlite
```

Also back up your `.env` — JWT_SECRET loss = all users get logged out; SMTP/OIDC secrets need replacing if lost.

## Upgrade

1. Releases: <https://github.com/thedevs-network/kutt/releases>. Semi-active.
2. Docker: `docker compose pull && docker compose up -d`.
3. Native: `git pull && npm install && npm run start`.
4. DB migrations run on startup via Knex; back up first.
5. **Major versions (2.x → 3.x) had breaking env var changes**. Read release notes.

## Gotchas

- **`DEFAULT_DOMAIN` is baked into generated short links** — changing it doesn't retroactively rewrite old links. Pick it permanently.
- **`JWT_SECRET` loss** = all users logged out; must re-login. Back up as part of secrets vault.
- **Public URL shorteners become spam targets instantly.** **Always** set:
  - `DISALLOW_ANONYMOUS_LINKS=true` (users must register)
  - `DISALLOW_REGISTRATION=true` (once your users are registered)
  - CAPTCHA keys (hCaptcha / reCAPTCHA) if you must keep registration open
- **Domain blacklists**: your short domain can get blacklisted by spam detectors if abused. Google Safe Browsing, Spamhaus, etc. will flag all links on that domain. Prevention > cleanup.
- **Abuse reporting endpoint** (`/report`) — lets anyone report a link for abuse. Check the admin UI regularly.
- **Link expiration** is a soft feature — expired links return a 404 immediately; not cleaned up from DB by default.
- **Analytics is per-link stats** — click count, referrer, country (via IP geoip), device. Stored server-side; not a third-party tracker.
- **OIDC integration**: standard OpenID Connect — works with Keycloak, Zitadel, Logto, Authentik, Casdoor, etc. `OIDC_REDIRECT_URI` must match exactly what you register with the IdP.
- **`kutt.it` was suspended** (Italian TLD registrar didn't get identification documents). The public demo is at **`kutt.to`**. If you've used the hosted version, links continue to work on kutt.to.
- **Custom domain per-user** (SaaS mode) requires DNS + reverse proxy gymnastics — users CNAME their domain to your Kutt host; you configure SNI/TLS. Not trivial at scale.
- **API rate limits** — configurable via env; default is generous. For abuse resistance, tighten.
- **Browser extensions** are useful — install on your dev machine; one click shortens any URL.
- **No bulk import** from bit.ly / TinyURL exports — would need a script against the REST API.
- **Redis is optional** but noticeably speeds up link resolution at scale.
- **MIT license** — permissive.
- **Alternatives worth knowing:**
  - **YOURLS** — PHP, older, mature; simpler (separate recipe — also flagged abuse risks)
  - **Shlink** — PHP, strong analytics, REST-first, web-UI + CLI
  - **Polr** — PHP, very minimal, long-standing
  - **Dub** — Next.js, modern, product-focused on marketing teams; OSS + commercial
  - **Simple-URL / LinkStack** — different niches
  - **Bit.ly / TinyURL / Rebrandly** — commercial SaaS
  - **Choose Kutt if:** Node.js stack preferred, OIDC needed, admin UI is important.
  - **Choose Shlink if:** you want strongest analytics + campaign tracking.
  - **Choose YOURLS if:** you want battle-tested PHP simplicity.

## Links

- Repo: <https://github.com/thedevs-network/kutt>
- Website: <https://kutt.to> (also <https://kutt.it> historically)
- Docs: <https://docs.kutt.it>
- Configuration (env vars): <https://github.com/thedevs-network/kutt/blob/main/.docker/.env.docker>
- Docker Hub: <https://hub.docker.com/r/kutt/kutt>
- Releases: <https://github.com/thedevs-network/kutt/releases>
- Browser extensions: <https://github.com/thedevs-network/kutt#browser-extensions>
- Firefox ext: <https://addons.mozilla.org/firefox/addon/kutt/>
- Chrome ext: <https://chrome.google.com/webstore/detail/kutt/>
- Status: <https://status.kutt.it>
- Donate: <https://btcpay.kutt.it/apps/L9Gc7PrnLykeRHkhsH2jHivBeEh/crowdfund>
