---
name: christmas-community-project
description: Christmas Community recipe for open-forge. Self-hosted family wish-list app. Avoid double-gifting. Multi-user lists, link-based item addition, claim-marking hidden from list owner. Node.js + SQLite. Single container. Upstream: https://github.com/Wingysam/Christmas-Community
---

# Christmas Community

A self-hosted web app for coordinating family wish lists (Christmas, weddings, birthdays, etc.). Each person gets their own list. Other members mark items as "I'm getting this" — but that mark is hidden from the list owner, preserving the surprise and avoiding double-gifting. Items added by pasting a URL; app auto-fetches the title.

Node.js, SQLite, single Docker container.

Upstream: <https://github.com/Wingysam/Christmas-Community> | Docker Hub: `wingysam/christmas-community`

## Compatible combos

| Infra | Notes |
|---|---|
| Any Linux host | Single container; SQLite; no external DB needed |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Host port?" | Default: `8080` (container runs on 80) |
| config | "Table or box layout?" | `TABLE=true` (table, default) or `TABLE=false` (box/card) |
| config | "Single list mode?" | `SINGLE_LIST=true` for weddings/birthdays (only admin list shown) |
| config | "Subdirectory path?" | `ROOT_URL=/path` only if hosting under a subpath |

## Software-layer concerns

### Image

```
wingysam/christmas-community:latest
```

Docker Hub, multi-arch.

### Compose

```yaml
services:
  christmas-community:
    image: wingysam/christmas-community
    container_name: christmas-community
    volumes:
      - ./data:/data
    ports:
      - "8080:80"
    environment:
      - TZ=UTC
      - TABLE=true
      - SINGLE_LIST=false
      # - ROOT_URL=/christmas-community
      # - NODE_OPTIONS=--max-http-header-size=32768
    restart: always
```

Source: upstream README -- https://github.com/Wingysam/Christmas-Community

### Key environment variables

| Variable | Default | Purpose |
|---|---|---|
| `TABLE` | `true` | Layout: `true` = table, `false` = box/card |
| `SINGLE_LIST` | `false` | Single list mode (weddings, birthdays) |
| `ROOT_URL` | (none) | Subpath prefix if hosting under a subdirectory |
| `NODE_OPTIONS` | (none) | Node.js options; set `--max-http-header-size=32768` if retail sites fail |
| `TZ` | System | Timezone |

### Volumes

| Path | Purpose |
|---|---|
| `./data:/data` | SQLite database and app data |

### First run

1. Go to `http://your-host:8080` and register an admin account
2. Share the URL with family so they can register and create their own wish lists
3. Browse other people's lists and mark items as "I'm getting this" -- the mark is hidden from the list owner

### Single list mode

Set `SINGLE_LIST=true` when only one wish list is needed (wedding registry, birthday, etc.). Only the admin account's list is displayed.

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Data persists in `./data`.

## Gotchas

- **`./data` must be pre-created** -- run `mkdir -p data` before `docker compose up` or Docker creates it as root-owned, causing write failures.
- **Large-header sites** -- some retailers (Walmart) send HTTP headers exceeding Node's 8 KB default. If adding items from those sites fails, set `NODE_OPTIONS=--max-http-header-size=32768`.
- **`ROOT_URL` + reverse proxy** -- if using a subpath, configure your proxy to forward the full path. A missing prefix rewrite is the most common setup mistake.
- **No built-in TLS** -- use Caddy or nginx for HTTPS when sharing with family outside your LAN.

## Links

- Upstream README: <https://github.com/Wingysam/Christmas-Community>
- Docker Hub: <https://hub.docker.com/r/wingysam/christmas-community>
- Discord: <https://discord.gg/Dxjh68gFzV>
