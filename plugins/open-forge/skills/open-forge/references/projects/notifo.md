---
name: notifo
description: Recipe for Notifo — a multi-channel notification service supporting Email, Web Push, Mobile Push, SMS, and WebSockets. C#/.NET + MongoDB + Docker.
---

# Notifo

Multi-channel notification service for sending alerts and messages to users via Email, Web Push (browser push), Mobile Push (Firebase), SMS (MessageBird), WebSockets, and in-app notifications. Includes a management UI, template engine, subscription management, and a JavaScript overlay plugin. Upstream: <https://github.com/notifo-io/notifo>.

License: MIT. Platform: C#/.NET, MongoDB, Docker. Latest release: 1.3.0 (Nov 2022). Low recent activity.

## Compatible install methods

| Method | When to use |
|---|---|
| Docker Compose | Recommended — runs Notifo + MongoDB + Caddy proxy |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| network | "Public domain for Notifo (e.g. `notifo.example.com`)?" | Set as `NOTIFO_DOMAIN` env var |
| auth | "OAuth provider credentials (Google/GitHub/Microsoft)?" | At least one OAuth provider is needed for login |
| push | "Firebase server key for mobile push?" | Optional — only needed for Android/iOS push |
| sms | "MessageBird API key for SMS?" | Optional |
| mail | "Amazon SES credentials for email channel?" | Optional |

## Docker Compose

The upstream repo provides a ready-made compose file at `deployment/docker compose/docker compose.yml`.

```bash
git clone https://github.com/notifo-io/notifo.git
cd notifo/deployment/docker\ compose/
```

Create a `.env` file:
```dotenv
NOTIFO_DOMAIN=notifo.example.com

# At least one OAuth provider required for login
NOTIFO_GOOGLECLIENT=your-google-client-id
NOTIFO_GOOGLESECRET=your-google-client-secret
# NOTIFO_GITHUBCLIENT=
# NOTIFO_GITHUBSECRET=
# NOTIFO_MICROSOFTCLIENT=
# NOTIFO_MICROSOFTSECRET=
```

`docker-compose.yml` (from the repo):
```yaml
services:
  notifo_mongo:
    image: mongo:5
    volumes:
      - /etc/notifo/mongo/db:/data/db
    networks:
      - internal
    restart: unless-stopped

  notifo_notifo:
    image: "squidex/notifo:1"
    environment:
      - URLS__BASEURL=https://${NOTIFO_DOMAIN}
      - STORAGE__MONGODB__CONNECTIONSTRING=mongodb://notifo_mongo
      - IDENTITY__GOOGLECLIENT=${NOTIFO_GOOGLECLIENT}
      - IDENTITY__GOOGLESECRET=${NOTIFO_GOOGLESECRET}
      - ASPNETCORE_URLS=http://+:5000
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5000/healthz"]
      start_period: 60s
    depends_on:
      - notifo_mongo
    volumes:
      - /etc/notifo/assets:/app/Assets
    networks:
      - internal
    restart: unless-stopped

  notifo_proxy:
    image: squidex/caddy-proxy:2.7.6
    ports:
      - "80:80"
      - "443:443"
    environment:
      - SITE_ADDRESS=${NOTIFO_DOMAIN}
      - SITE_SERVER=notifo_notifo:5000
    volumes:
      - /etc/notifo/caddy/data:/data
      - /etc/notifo/caddy/config:/config
    depends_on:
      - notifo_notifo
    networks:
      - internal
    restart: unless-stopped

networks:
  internal:
    driver: bridge
```

```bash
sudo mkdir -p /etc/notifo/{mongo/db,assets,caddy/data,caddy/config}
docker compose up -d
```

Notifo will be available at `https://notifo.example.com` with auto-TLS via Caddy.

## Configuration via environment variables

All `appsettings.json` config keys can be set as env vars using double underscore (`__`) as the separator:

| Setting | Env var | Example |
|---|---|---|
| Base URL | `URLS__BASEURL` | `https://notifo.example.com` |
| MongoDB | `STORAGE__MONGODB__CONNECTIONSTRING` | `mongodb://notifo_mongo` |
| Firebase key | `MESSAGING__FIREBASE__CREDENTIAL` | (JSON key file content) |
| Amazon SES | `EMAIL__SES__ACCESSKEY` / `EMAIL__SES__SECRETKEY` | AWS credentials |
| MessageBird | `SMS__MESSAGEBIRD__ACCESSKEY` | API key |

## Software-layer concerns

| Concern | Detail |
|---|---|
| Config | Environment variables (maps to `appsettings.json`) |
| Database | MongoDB 5 |
| Assets | `/app/Assets` — uploaded assets; persist this volume |
| Default port | `5000` (internal); `443` via Caddy proxy |
| OAuth | Required — at least one of Google/GitHub/Microsoft OAuth must be configured |
| Health check | `GET /healthz` |

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

MongoDB migrations are applied automatically on startup.

## Gotchas

- **OAuth is mandatory**: Notifo does not have a username/password login by default. You must configure at least one OAuth provider (Google, GitHub, or Microsoft) or you cannot log in.
- **Low maintenance since 2022**: Latest release is v1.3.0 from November 2022. The project has minimal activity. Evaluate whether it fits your long-term maintenance needs.
- **Docker image name**: The Docker image is `squidex/notifo` (hosted by Squidex, the company behind Notifo) — not `notifo/notifo`.
- **MongoDB 5**: The compose file pins MongoDB 5. Newer MongoDB versions may work but are untested by the project.
- **Assets volume**: The `/app/Assets` volume holds uploaded media. If lost, asset references in notifications will break.
- **`URLS__BASEURL` must match public URL**: Web Push subscriptions and notification links are generated using this URL. If it's wrong, push notifications and links will be broken.

## Upstream links

- Source: <https://github.com/notifo-io/notifo>
- Docker Hub: <https://hub.docker.com/r/squidex/notifo>
- Configuration reference: <https://github.com/notifo-io/notifo/wiki/configuration>
- Installation wiki: <https://github.com/notifo-io/notifo/wiki/Installation>
