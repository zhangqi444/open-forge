---
name: iceshrimp-net
description: Iceshrimp.NET recipe for open-forge. Federated microblogging server communicating over ActivityPub. .NET rewrite of Iceshrimp. EUPL-1.2. Based on upstream at https://iceshrimp.dev/iceshrimp/iceshrimp.net and website https://iceshrimp.net.
---

# Iceshrimp.NET

Federated microblogging server implementing ActivityPub (Mastodon-compatible federation). A ground-up .NET rewrite of the Iceshrimp (Node.js) codebase. Designed to be fast, feature-rich, and compatible with Mastodon clients and the broader Fediverse. EUPL-1.2. Upstream: https://iceshrimp.dev/iceshrimp/iceshrimp.net. Website: https://iceshrimp.net.

> **Note:** Iceshrimp.NET is under active development and not yet recommended for migrating existing Iceshrimp-JS instances. New instance setup is supported and bug reports are welcome.

## Compatible install methods

| Method | When to use |
|---|---|
| Docker Compose | Standard; recommended for self-hosters |
| Source (.NET SDK) | Development or custom builds |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| database | "PostgreSQL connection string?" | Connection string | iceshrimp requires PostgreSQL |
| config | "Instance domain?" | FQDN (e.g. social.example.com) | ActivityPub identity — cannot change after launch |
| config | "Admin email?" | Email | For initial admin account |
| network | "Port to expose?" | Number (default 3000) | Proxy behind Caddy/nginx for HTTPS |
| storage | "Media storage path?" | Host path | Uploaded media, avatars, attachments |

## Software-layer concerns

| Concern | Detail |
|---|---|
| Language | C# / .NET |
| Database | PostgreSQL (required) |
| Federation | ActivityPub; compatible with Mastodon, Misskey, Pleroma, etc. |
| Client compatibility | Mastodon API-compatible clients |
| Port | 3000 (default; proxy behind nginx/Caddy for TLS) |
| Object storage | Local filesystem or S3-compatible bucket for media |
| Migration | Not yet recommended for migrating from Iceshrimp-JS |

## Install: Docker Compose

Source: https://iceshrimp.dev/iceshrimp/iceshrimp.net

Check the upstream repository for the official docker-compose.yml and `.env.example`. The general approach:

```bash
git clone https://iceshrimp.dev/iceshrimp/iceshrimp.net
cd iceshrimp.net
# Copy and edit environment configuration
cp .env.example .env
# Edit .env: set DOMAIN, DATABASE_URL, SMTP settings, etc.
docker compose pull
docker compose up -d
```

Refer to the upstream README and documentation at https://iceshrimp.net for current compose file format and environment variable reference — the project is under active development.

## Instance domain: choose carefully

The instance domain (ActivityPub actor base URL) is permanent. Once you federate with other servers, you cannot change your domain without losing your followers and federated identity. Choose `social.yourdomain.com` or a dedicated domain before going live.

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Follow the upgrade notes in upstream releases: https://iceshrimp.dev/iceshrimp/iceshrimp.net/releases

## Gotchas

- Domain is permanent: ActivityPub identity is tied to your domain. Changing it after federating breaks all existing connections.
- Not stable yet for migrations: The upstream explicitly warns against migrating existing Iceshrimp-JS instances until a stable release is published.
- HTTPS required: ActivityPub federation requires HTTPS. Use Caddy or nginx + certbot to terminate TLS in front of the container.
- PostgreSQL only: Unlike some Fediverse software that supports SQLite for small instances, Iceshrimp.NET requires PostgreSQL.
- Mastodon API compatibility: Most Mastodon-compatible apps (Tusky, Ivory, Elk) should work, but edge cases may exist during the active development phase.
- .NET runtime: The Docker image bundles the .NET runtime. Running from source requires the .NET 8+ SDK.

## Links

- Source: https://iceshrimp.dev/iceshrimp/iceshrimp.net
- Website: https://iceshrimp.net
- Releases: https://iceshrimp.dev/iceshrimp/iceshrimp.net/releases
