---
name: hatsu
description: Hatsu recipe for open-forge. Self-hosted ActivityPub bridge for static sites. Lets Fediverse users follow and interact with your static blog/site. Rust + SQLite. Docker. AGPL-3.0. Source: https://github.com/importantimport/hatsu
---

# Hatsu

Self-hosted, fully automated ActivityPub bridge for static sites. Lets Fediverse users (Mastodon, Pleroma, GoToSocial, etc.) search for, follow, and interact with your static site as if it were a Fediverse account. Automatically pushes new posts to followers via RSS/Atom feed polling. No CMS changes required -- works with any static site generator. Written in Rust. SQLite backend. AGPL-3.0 licensed.

Upstream: https://github.com/importantimport/hatsu | Docs: https://hatsu.cli.rs

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any | Docker Compose | Official method |
| Any | Binary | See docs for binary install |
| Any | Docker Compose + Litestream | SQLite streaming replication/backup |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| config | HATSU_DOMAIN | Domain of the Hatsu instance, e.g. hatsu.example.com |
| config | HATSU_PRIMARY_ACCOUNT | Your static site domain, e.g. blog.example.com |
| config | HATSU_DATABASE_URL | SQLite path, e.g. sqlite://hatsu.sqlite3 |
| config | HATSU_LISTEN_HOST | Set to 0.0.0.0 when running in Docker |
| config (optional) | HATSU_ACCESS_TOKEN | UUID for API auth; generate with cat /proc/sys/kernel/random/uuid |
| config (optional) | HATSU_LISTEN_PORT | Default: 3939 |
| config (optional) | HATSU_NODE_NAME | Display name for the instance |
| config (optional) | HATSU_NODE_DESCRIPTION | Instance description |
| config (optional) | HATSU_LOG | Log level, default: info |

## Software-layer concerns

- HATSU_DOMAIN must match the domain in DNS and your reverse proxy -- this is the ActivityPub actor domain
- HATSU_PRIMARY_ACCOUNT is your static site's domain (not the Hatsu instance domain)
- SQLite file must be persisted via a bind mount; without it, data is lost on container restart (default in-memory)
- Must be reachable over HTTPS: ActivityPub requires HTTPS for federation; put Caddy or Nginx in front
- RSS/Atom feed: Hatsu polls your site's feed to detect new posts and push them to followers
- HATSU_ACCESS_TOKEN: optional but recommended to protect the admin API

## Install -- Docker Compose

```yaml
version: "3"

services:
  hatsu:
    container_name: hatsu
    image: ghcr.io/importantimport/hatsu:nightly
    restart: unless-stopped
    ports:
      - 3939:3939
    environment:
      - HATSU_DATABASE_URL=sqlite://hatsu.sqlite3
      - HATSU_DOMAIN=hatsu.example.com
      - HATSU_LISTEN_HOST=0.0.0.0
      - HATSU_PRIMARY_ACCOUNT=blog.example.com
      # Optional:
      # - HATSU_ACCESS_TOKEN=your-uuid-here
      # - HATSU_NODE_NAME=My Hatsu Instance
    volumes:
      - ./hatsu.sqlite3:/app/hatsu.sqlite3
```

```bash
touch hatsu.sqlite3   # create empty file so Docker bind-mounts correctly
docker compose up -d
# API at http://yourserver:3939
```

## Reverse proxy (Caddy example)

```
hatsu.example.com {
    reverse_proxy localhost:3939
}
```

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
# Hatsu applies DB migrations automatically on startup
```

## Gotchas

- HTTPS required: Fediverse servers will reject unsigned ActivityPub requests over plain HTTP. Deploy behind a TLS-terminating reverse proxy (Caddy recommended for auto-TLS).
- Touch the SQLite file first: if the bind-mount target file doesn't exist, Docker creates it as a directory, breaking SQLite.
- nightly vs versioned tags: the example compose uses :nightly. For production, pin to a specific version tag to avoid unexpected breaking changes.
- Fediverse search: after setup, Fediverse users can find your site by searching @catch-all@hatsu.example.com or your site URL from their Mastodon/Pleroma client.
- Feed polling: Hatsu discovers new posts by polling your RSS/Atom feed. Ensure your static site publishes a feed.

## Links

- Source: https://github.com/importantimport/hatsu
- Documentation: https://hatsu.cli.rs
- Docker Hub: https://github.com/importantimport/hatsu/pkgs/container/hatsu
