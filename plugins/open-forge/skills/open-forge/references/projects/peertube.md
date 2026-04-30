---
name: PeerTube
description: Self-hosted, federated video streaming platform built on ActivityPub + WebTorrent. YouTube alternative without ads, algorithm, or corporate ownership. Node.js backend + Angular frontend. AGPL-3.0.
---

# PeerTube

PeerTube is the leading federated video platform: instances federate via ActivityPub (you follow channels on other instances like Mastodon follows users), videos can seed P2P between viewers via WebTorrent, and live streaming uses RTMP. No central YouTube-like gatekeeper — each admin curates their instance, and the federated network handles discovery.

Maintained by Framasoft, a French non-profit. Production-grade; runs at scale (TILvids, diode.zone, many 10k+ user instances).

- Upstream repo: <https://github.com/Chocobozzz/PeerTube>
- Docs: <https://docs.joinpeertube.org/>
- Docker install guide: <https://docs.joinpeertube.org/install/docker>
- Docker compose: <https://github.com/Chocobozzz/PeerTube/blob/develop/support/docker/production/docker-compose.yml>

## Architecture in one minute

Six services in the upstream compose:

1. **`peertube`** — Node.js app (web UI, REST API, federation, transcoding)
2. **`postgres:17-alpine`** — database
3. **`redis:8-alpine`** — job queue + session cache
4. **`webserver`** (custom nginx `chocobozzz/peertube-webserver`) — TLS termination, static asset serving, /live RTMP passthrough
5. **`certbot/certbot`** — auto Let's Encrypt renewal (optional; skip if using your own reverse proxy)
6. **`postfix`** (`mwader/postfix-relay`) — outbound SMTP + DKIM signing
7. Plus `webserver-reloader` — an alpine sidecar that HUPs nginx every 6h to pick up renewed certs

Ports: 80, 443 (HTTP/S), 1935 (RTMP live), 9000 (internal app port; not exposed).

## Compatible install methods

| Infra      | Runtime                                                             | Notes                                                              |
| ---------- | ------------------------------------------------------------------- | ------------------------------------------------------------------ |
| Single VM  | Docker Compose (upstream `support/docker/production/docker-compose.yml`) | **Recommended self-host path.** 4 GB RAM minimum, 8+ realistic |
| Single VM  | Manual (Node 22 + Postgres + Redis + nginx + FFmpeg + systemd)     | "Any-OS" install guide; more tuning knobs                          |
| Yunohost   | Package                                                             | Easy for small instances                                           |
| Kubernetes | Community Helm chart / manifests                                    | Niche; stateful services make it less natural                      |

## Inputs to collect

| Input                       | Example                                     | Phase     | Notes                                                            |
| --------------------------- | ------------------------------------------- | --------- | ---------------------------------------------------------------- |
| `PEERTUBE_WEBSERVER_HOSTNAME` | `video.example.com`                       | DNS       | **PERMANENT.** PeerTube does NOT support hostname change after first boot |
| `POSTGRES_USER` + `POSTGRES_PASSWORD` | strong values                     | DB        | Both used by `peertube` (mirrored as `PEERTUBE_DB_*`)              |
| `PEERTUBE_SECRET`           | `openssl rand -hex 32`                      | Runtime   | Signs federation requests + JWT                                  |
| Admin email                 | `you@example.com`                           | Bootstrap | For Let's Encrypt + admin notifications                          |
| Storage                     | 100+ GB recommended                         | Disk      | Videos, transcoded renditions, live recordings — grows fast       |
| RAM                         | 4 GB min, 8 GB for transcoding              | Runtime   | FFmpeg is memory-hungry                                          |
| `PEERTUBE_TRUST_PROXY`      | `["127.0.0.1", "loopback", "172.18.0.0/16"]` | Runtime  | For correct client-IP logging behind webserver container         |
| DKIM DNS record             | generated on first boot                     | Email     | Copy from `./docker-volume/opendkim/keys/*/*.txt` to your DNS     |

## Install via upstream Docker Compose

From <https://docs.joinpeertube.org/install/docker>:

```sh
# 1. Create workdir
mkdir -p /your/peertube && cd /your/peertube

# 2. Fetch compose + env template (from develop branch — use master for stable)
curl https://raw.githubusercontent.com/Chocobozzz/PeerTube/master/support/docker/production/docker-compose.yml > docker-compose.yml
curl https://raw.githubusercontent.com/Chocobozzz/PeerTube/master/support/docker/production/.env > .env

# 3. Edit .env — replace:
#    <MY POSTGRES USERNAME> / <MY POSTGRES PASSWORD>
#    <MY DOMAIN>  (without https://)
#    <MY EMAIL ADDRESS>
#    <MY PEERTUBE SECRET>  → `openssl rand -hex 32`
vim .env

# 4. Install nginx template (rendered from env at startup)
mkdir -p docker-volume/nginx docker-volume/nginx-logs
curl https://raw.githubusercontent.com/Chocobozzz/PeerTube/master/support/nginx/peertube > docker-volume/nginx/peertube

# 5. Generate first TLS cert manually with certbot standalone
mkdir -p docker-volume/certbot
docker run -it --rm --name certbot -p 80:80 \
  -v "$(pwd)/docker-volume/certbot/conf:/etc/letsencrypt" \
  certbot/certbot certonly --standalone

# 6. Bring up the stack
docker compose up -d

# 7. Find auto-generated root password in logs:
docker compose logs peertube | grep -A1 root
# Or reset it:
docker compose exec -u peertube peertube npm run reset-password -- -u root
```

### Publish your DKIM record

```sh
cat ./docker-volume/opendkim/keys/*/*.txt
# Copy the TXT record to DNS: peertube._domainkey.<your-domain>
```

Without DKIM, outbound email (user invites, password resets, notifications) lands in spam.

## Data & config layout

Mounted volumes (all under `./docker-volume/`):

- `data/` — videos, thumbnails, avatars, previews, torrents, redundancy cache
- `config/` — generated `production.yaml` after first boot
- `db/` — PostgreSQL data
- `redis/` — Redis persistence
- `nginx/peertube` — rendered nginx config
- `certbot/conf/` — Let's Encrypt certs
- `opendkim/keys/` — DKIM private keys

**`data/` grows linearly with video upload volume + transcoding renditions.** A 1-hour 1080p upload at multiple renditions (240p/360p/480p/720p/1080p) can be 5–10 GB of storage.

## Backup

```sh
# Stop writes
docker compose stop peertube

# Postgres dump
docker compose exec -T postgres pg_dump -U <MY_POSTGRES_USERNAME> peertube | gzip > pt-db-$(date +%F).sql.gz

# Config + secrets
tar czf pt-config-$(date +%F).tgz docker-volume/config docker-volume/opendkim .env

# Data (videos — usually the big one)
tar czf pt-data-$(date +%F).tgz docker-volume/data

docker compose start peertube
```

For large instances, consider S3-compatible object storage (`OBJECT_STORAGE_ENABLED=true` in env) → backup only becomes the DB + config.

## Upgrade

1. Changelog: <https://github.com/Chocobozzz/PeerTube/blob/develop/CHANGELOG.md> — **read the IMPORTANT NOTES section** for breaking changes.
2. `cd /your/peertube && docker compose pull`.
3. `docker compose down -v` (removes internal volumes holding the shared `assets` volume — this is intentional; shared client files must be regenerated).
4. Refresh nginx config: `curl https://raw.githubusercontent.com/Chocobozzz/PeerTube/master/support/nginx/peertube > docker-volume/nginx/peertube`.
5. `docker compose up -d`.
6. **Postgres major-version upgrades** (e.g. 13 → 17) require dump + reload, NOT just changing image tag. Upstream has a dedicated upgrade procedure.

## Gotchas

- **`PEERTUBE_WEBSERVER_HOSTNAME` IS PERMANENT.** Upstream README warns: *"PeerTube does not support webserver host change."* The hostname is baked into every federated video ID, every ActivityPub actor URL, every signed object. Changing = breaking federation for every other instance that knows you. Start with the final domain.
- **Upstream default images use `postgres:17-alpine` + `redis:8-alpine`.** If you were on an older compose, don't bump major Postgres in-place — pg_dump + reload required.
- **Live streaming (RTMP) uses port 1935.** Ensure firewall allows it inbound if you enable `PEERTUBE_LIVE_ENABLED=true`. `PEERTUBE_LIVE_RTMP_*_URL` env lets you use `rtmps://` if you front it with a TLS RTMP proxy.
- **Static IPv4 on `172.18.0.42`** in compose is deliberate — nginx's upstream block references this IP, and nginx doesn't re-resolve on restart. Don't change the compose subnet.
- **Federation requires HTTPS.** Other instances will reject HTTP-only actors. Run the built-in webserver + certbot, or your own TLS-terminating proxy.
- **Default admin password is auto-generated.** Shown ONCE in container logs on first boot; grep `docker compose logs peertube | grep -A1 root`. Reset via `npm run reset-password -- -u root` if you missed it.
- **Video transcoding is CPU-expensive.** Upstream suggests disabling `PEERTUBE_TRANSCODING_ENABLED` if you have tiny hardware and users upload pre-encoded H.264/AAC. Remote GPU transcoding is supported via runners (since 5.x).
- **`PEERTUBE_TRUST_PROXY`** MUST include the Docker bridge network (e.g. `172.18.0.0/16`) — without it, IP rate-limiting thinks every request comes from the nginx container and will rate-limit aggressively or log wrong IPs.
- **Federation is sticky.** Instances that followed you remember your actor forever; unsubscribing from a defederated instance requires cooperation. Plan your federation policy (allowlist vs blocklist) before going public.
- **Object storage (S3/MinIO/Cloudflare R2)** is supported and strongly recommended for instances >100 GB storage. Otherwise videos fill local disk fast. Env: `OBJECT_STORAGE_*`.
- **Redundancy feature** lets your instance cache videos from other instances (helps P2P). Opt-in via config; costs bandwidth + storage.
- **WebTorrent/WebSeed** for P2P viewing: modern browsers need MSE + WebRTC. Blocked on strict corporate networks.
- **Postfix relay container (`mwader/postfix-relay`)** auto-generates DKIM keys on first boot. Leaving the generated TXT record unpublished = outbound mail lands in spam.
- **Plugins are community-maintained.** Plugin store at <https://packages.joinpeertube.org>. Some plugins change the schema; always back up DB before installing/removing.
- **`webserver-reloader` HUPs nginx every 6h** to reload LE certs. Fine for most; if you get 502s every 6 hours, this is the suspect.
- **AGPL-3.0 network copyleft.** Modified PeerTube run as a service = must offer source to users.
- **Alternatives worth knowing:**
  - **Owncast** — simpler, live-streaming focused, not federated
  - **Plex / Jellyfin** — media server; no federation, no upload form
  - **Funkwhale** — audio/music federation counterpart (uses PeerTube-like patterns)

## Links

- Repo: <https://github.com/Chocobozzz/PeerTube>
- Docs: <https://docs.joinpeertube.org/>
- Install (Docker): <https://docs.joinpeertube.org/install/docker>
- Install (any OS): <https://docs.joinpeertube.org/install/any-os>
- Compose: <https://github.com/Chocobozzz/PeerTube/blob/develop/support/docker/production/docker-compose.yml>
- .env template: <https://github.com/Chocobozzz/PeerTube/blob/develop/support/docker/production/.env>
- Changelog: <https://github.com/Chocobozzz/PeerTube/blob/develop/CHANGELOG.md>
- Admin docs: <https://docs.joinpeertube.org/admin/following-instances>
- Federation + moderation: <https://docs.joinpeertube.org/admin/moderation>
- Plugin packages: <https://packages.joinpeertube.org>
- Join a list of instances: <https://joinpeertube.org/instances>
- Framasoft (maintainer): <https://framasoft.org/en/>
