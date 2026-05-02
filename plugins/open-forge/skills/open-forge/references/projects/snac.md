---
name: snac-project
description: snac recipe for open-forge. Simple, minimalistic, multi-user ActivityPub/fediverse instance. No database needed, no JavaScript, no cookies. Mastodon API compatible. Written in C. Must be fronted by a TLS-enabled reverse proxy. Upstream: https://codeberg.org/grunfink/snac2
---

# snac

A simple, minimalistic ActivityPub instance. Multi-user fediverse server with no database, no JavaScript, and no cookies. Mastodon API support means any Mastodon-compatible mobile app works with it. Written in portable C with minimal dependencies (`openssl` + `curl`).

Name stands for *Social Networks Are Crap*.

Upstream: <https://codeberg.org/grunfink/snac2> | Manuals: <https://comam.es/snac-doc/>

Image: built from source (official Dockerfile included). Must be fronted by a TLS reverse proxy (nginx/Caddy).

## Compatible combos

| Infra | Notes |
|---|---|
| Any Linux host | Built from source via Docker; fronted by nginx or Caddy for TLS |
| OpenBSD / FreeBSD | Native install (no Docker needed) |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Your domain?" | e.g. `social.example.com` — used as ActivityPub server name; **cannot be changed after init** |
| preflight | "snac listen port?" | Default: `8001` — snac's internal HTTP port; reverse proxy forwards to this |
| config | "Admin username?" | Created on first init |
| config | "Timezone?" | `TZ` env var; e.g. `America/New_York` |

## Software-layer concerns

### Image

snac has no prebuilt image on Docker Hub. Build from source:

```bash
git clone https://codeberg.org/grunfink/snac2.git
cd snac2
docker build -t snac2 .
```

The official `Dockerfile` (multi-stage Alpine build) produces a minimal image.

### Compose (development/testing — nginx TLS frontend included)

```bash
# Uses examples/docker-compose.yml + examples/docker-entrypoint.sh
docker compose build && docker compose up
```

This spins up snac on port 8001 + nginx with a self-signed cert on 443. On first run:
- snac initializes a new instance at `localhost` with a test user `testuser`
- The generated password is printed to the console

### Production compose (snac only — front with your own reverse proxy)

```yaml
services:
  snac:
    build: .
    container_name: snac
    restart: unless-stopped
    environment:
      TZ: America/New_York
    ports:
      - "8001:8001"   # only expose to reverse proxy, not public
    volumes:
      - ./data:/data
```

> Source: upstream Dockerfile + entrypoint — <https://codeberg.org/grunfink/snac2>

### Init (first run)

The entrypoint auto-initializes if `/data/data/server.json` does not exist:

```sh
# Entrypoint runs:
echo -ne "0.0.0.0\r\n8001\r\nlocalhost\r\n\r\n\r\n" | snac init /data/data
snac adduser /data/data testuser
```

To init with your real domain instead of `localhost`, customize the entrypoint or run init manually:

```bash
docker run --rm -it -v ./data:/data snac2 snac init /data/data
# Interactive prompts: listen address, port, server name (your domain), etc.
```

### Adding users

```bash
docker exec -it snac snac adduser /data/data yourusername
```

### Mastodon API

Available from version 2.27. To compile without it:
```
make CFLAGS=-DNO_MASTODON_API
```

### Nginx reverse proxy (TLS)

```nginx
server {
    listen 443 ssl;
    server_name social.example.com;

    ssl_certificate     /etc/letsencrypt/live/social.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/social.example.com/privkey.pem;

    location / {
        proxy_pass http://localhost:8001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Caddy reverse proxy (auto TLS)

```
social.example.com {
    reverse_proxy localhost:8001
}
```

### CSS themes

Custom CSS can be dropped into the `lang/` subdirectory. Community themes: <https://codeberg.org/voron/snac-style>

### Languages

From version 2.73, the web UI language is configurable. Copy a file from `po/` to `lang/` in your data dir.

## Upgrade procedure

```bash
cd snac2
git pull
docker compose build
docker compose up -d
```

Data in `./data` persists across upgrades.

## Gotchas

- **Server name cannot be changed after init** — the domain is baked into all ActivityPub actor URLs and stored data. Initialize with your final production domain, not `localhost`.
- **TLS is mandatory** — ActivityPub federation requires HTTPS. snac itself only speaks plain HTTP; you must front it with nginx, Caddy, or another TLS-terminating proxy.
- **No prebuilt image** — must build from source. Keep the `snac2` git clone around for future upgrades.
- **Port 8001 should not be exposed publicly** — only your reverse proxy should talk to it. Use `127.0.0.1:8001:8001` or a private Docker network.
- **Data directory ownership** — the container runs as root by default; the `./data` bind-mount will be owned by root. Adjust if needed for your setup.
- **Linux Landlock sandbox** (v2.68+) — opt-in at compile time: `make CFLAGS=-DWITH_LINUX_SANDBOX`. Requires kernel ≥ 5.13.
- **`shm_open` errors on Ubuntu 20.04** — compile with `make LDFLAGS=-lrt` or `make CFLAGS=-DWITHOUT_SHM`.

## Links

- Upstream (Codeberg): <https://codeberg.org/grunfink/snac2>
- Online manuals (user, admin, formats): <https://comam.es/snac-doc/>
- Community CSS themes: <https://codeberg.org/voron/snac-style>
- nginx proxy cache guide: <https://it-notes.dragas.net/2025/01/29/improving-snac-performance-with-nginx-proxy-cache/>
- Caddy config example: <https://ffuentes.sdf.org/communication/2025/08/23/my-snac-config-activitypub-instance-with-caddy.html>
