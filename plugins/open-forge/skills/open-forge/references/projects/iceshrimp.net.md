---
name: iceshrimp-net-project
description: Iceshrimp.NET recipe for open-forge. Federated ActivityPub microblogging server built on .NET 10. Covers Docker install. Based on upstream repo at https://iceshrimp.dev/iceshrimp/iceshrimp.net and docs at https://iceshrimp.net/docs.
---

# Iceshrimp.NET

Federated microblogging server implementing the ActivityPub standard. Built on .NET 10 + Blazor WASM frontend. Mastodon-compatible API. EUPL-1.2. Upstream: https://iceshrimp.dev/iceshrimp/iceshrimp.net. Docs: https://iceshrimp.net/docs.

Iceshrimp.NET is a full rewrite of the original Iceshrimp-JS in .NET, with a new Blazor frontend, improved performance, and a well-supported migration path from Iceshrimp-JS. It federates with Mastodon, Misskey, Pleroma, and other ActivityPub-compatible servers.

Note: As of the latest release (v2026.1-beta), this is beta software. Setting up new instances and bug reporting is encouraged; upgrades from existing Iceshrimp-JS instances are possible but should be done carefully.

## Compatible install methods

| Method | When to use |
|---|---|
| Docker | Primary supported deployment method |
| Source build (.NET 10) | Development / contributing to the project |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "Domain name for this instance?" | FQDN (e.g. social.example.com) | Must be publicly reachable; cannot be changed after setup |
| config | "Database password?" | Free-text (sensitive) | PostgreSQL password for the iceshrimp DB user |
| config | "Redis password (optional)?" | Free-text / skip | Used for job queues and caching |
| smtp | "SMTP host, port, user, password?" | Separate values | For sending email verification, notifications |
| smtp | "From address?" | email | e.g. noreply@example.com |
| storage | "Object storage or local?" | local / S3-compatible | For media attachments |

## Software-layer concerns

| Concern | Detail |
|---|---|
| Runtime | .NET 10 (Alpine or resolute-chiseled base image) |
| Database | PostgreSQL (required) |
| Cache / queues | Redis (required) |
| Config file | appsettings.json (or env-var overrides) |
| Media storage | Local filesystem or S3-compatible object storage |
| Ports | HTTP 3000 by default; put behind HTTPS reverse proxy |
| Federation | Requires publicly accessible HTTPS domain; HTTPS is mandatory for ActivityPub |
| Image registry | iceshrimp.dev/iceshrimp/iceshrimp.net |
| Current release | v2026.1-beta |
| AOT builds | Optional -- build with AOT=true for smaller/faster image; VIPS=false to disable image processing |

## Install: Docker Compose

Source: https://iceshrimp.net/docs/installation/ and https://iceshrimp.dev/iceshrimp/iceshrimp.net

The official image is hosted at iceshrimp.dev/iceshrimp/iceshrimp.net:latest.

```yaml
services:
  iceshrimp:
    image: iceshrimp.dev/iceshrimp/iceshrimp.net:latest
    container_name: iceshrimp
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - ICESHRIMP_URL=https://social.example.com
      - ICESHRIMP_DB_HOST=db
      - ICESHRIMP_DB_PORT=5432
      - ICESHRIMP_DB_NAME=iceshrimp
      - ICESHRIMP_DB_USER=iceshrimp
      - ICESHRIMP_DB_PASS=changeme
      - ICESHRIMP_REDIS_HOST=redis
      - ICESHRIMP_REDIS_PORT=6379
    depends_on:
      - db
      - redis

  db:
    image: postgres:16-alpine
    restart: unless-stopped
    environment:
      - POSTGRES_DB=iceshrimp
      - POSTGRES_USER=iceshrimp
      - POSTGRES_PASSWORD=changeme
    volumes:
      - postgres-data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    restart: unless-stopped
    volumes:
      - redis-data:/data

volumes:
  postgres-data:
  redis-data:
```

Note: Consult https://iceshrimp.net/docs for the canonical compose file and full configuration reference — the above is a minimal starting point. Env var names may change between releases.

## Reverse proxy

Iceshrimp.NET must be served over HTTPS for ActivityPub federation. Configure nginx or Caddy to proxy to port 3000.

nginx example:
```nginx
server {
    listen 443 ssl;
    server_name social.example.com;
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
    }
}
```

## Upgrade procedure

```bash
docker pull iceshrimp.dev/iceshrimp/iceshrimp.net:latest
docker compose up -d
```

Check the CHANGELOG (https://iceshrimp.dev/iceshrimp/iceshrimp.net/src/branch/dev/CHANGELOG.md) for breaking changes before upgrading.

## Gotchas

- Domain is permanent: The instance domain is baked into the database and federation. It cannot be changed after the first toot/post.
- HTTPS is mandatory: ActivityPub requires HTTPS. Never expose Iceshrimp directly on HTTP without a TLS-terminating reverse proxy.
- Beta status: v2026.1-beta — production use is possible but expect rough edges. Back up your database before every upgrade.
- Migration from Iceshrimp-JS: A migration path exists but check the docs for the current state before attempting (https://iceshrimp.net/docs).
- Mastodon API compatibility: Relatively complete — tested against Elk, Phanpy, Tusky, Moshidon, and others. Some features may differ from stock Mastodon.

## Supported clients

Web: Elk, Phanpy, Enafore, Masto-FE-standalone, Akkoma-FE, Pleroma-FE
iOS: Mona, Toot!, Ice Cubes, Tusker, Feditext, Ivory, Mastodon
Android: Tusky, Subway Tooter, Moshidon, Megalodon, Mastodon
Linux: Tuba

## Links

- Upstream repo: https://iceshrimp.dev/iceshrimp/iceshrimp.net
- Docs: https://iceshrimp.net/docs
- Knowledgebase: https://iceshrimp.net/kb
- Feature comparison: https://iceshrimp.net/help/prodready
- Chat / community: https://chat.iceshrimp.dev
- CHANGELOG: https://iceshrimp.dev/iceshrimp/iceshrimp.net/src/branch/dev/CHANGELOG.md
