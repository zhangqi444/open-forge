---
name: nextcloud-aio
description: Recipe for Nextcloud All-in-One (AIO) — the official, batteries-included Nextcloud deployment with a web-based management interface.
---

# Nextcloud All-in-One (AIO)

The official recommended Nextcloud installation method. Deploys Nextcloud plus a curated set of optional services (Nextcloud Office, Talk/TURN, backup via BorgBackup, ClamAV, full-text search, Redis, PostgreSQL) via a single Docker container that manages all the others through a web UI. Upstream: <https://github.com/nextcloud/all-in-one>. Docs: <https://github.com/nextcloud/all-in-one#nextcloud-all-in-one>. License: AGPL-3.0.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker (standalone) | <https://github.com/nextcloud/all-in-one#how-to-use-this> | Yes | Recommended; AIO master container manages the rest |
| Docker behind reverse proxy | <https://github.com/nextcloud/all-in-one/blob/main/reverse-proxy.md> | Yes | When you already have Nginx/Caddy/Traefik |
| Portainer / Kubernetes | <https://github.com/nextcloud/all-in-one#-helm-chart> | Community | Advanced deployments |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| infra | Public domain for Nextcloud? | FQDN (e.g. cloud.example.com) | Required; AIO provisions Let's Encrypt for it |
| infra | Nextcloud data directory? | Absolute host path | Recommended; avoids storing data in Docker volumes |
| infra | Behind a reverse proxy? | Boolean | Changes which port AIO listens on |
| software | Optional containers to enable? | office / talk / backup / clamav / fulltextsearch / imaginary / whiteboard | Optional |
| software | Backup location? | Absolute host path | Required if enabling BorgBackup |

## Software-layer concerns

### Docker run (direct — AIO manages all containers)

```bash
# Without reverse proxy (AIO handles TLS directly on port 443)
docker run \
  --sig-proxy=false \
  --name nextcloud-aio-mastercontainer \
  --restart always \
  --publish 80:80 \
  --publish 8080:8080 \
  --publish 443:443 \
  --volume nextcloud_aio_mastercontainer:/mnt/docker-aio-config \
  --volume /var/run/docker.sock:/var/run/docker.sock:ro \
  nextcloud/all-in-one:latest
```

Then open https://your-server-ip:8080 to complete setup via the AIO web UI.

### Docker run (behind reverse proxy)

```bash
# AIO listens only on 8080 for the setup UI
docker run \
  --sig-proxy=false \
  --name nextcloud-aio-mastercontainer \
  --restart always \
  --publish 8080:8080 \
  --env APACHE_PORT=11000 \
  --env APACHE_IP_BINDING=127.0.0.1 \
  --volume nextcloud_aio_mastercontainer:/mnt/docker-aio-config \
  --volume /var/run/docker.sock:/var/run/docker.sock:ro \
  nextcloud/all-in-one:latest
```

Reverse proxy forwards external HTTPS → port 11000 on localhost. See the reverse proxy guide: <https://github.com/nextcloud/all-in-one/blob/main/reverse-proxy.md>

### Caddy example (reverse proxy)

```caddyfile
cloud.example.com {
    reverse_proxy localhost:11000
}
```

### Included services (managed by AIO)

| Service | Optional? | Purpose |
|---|---|---|
| Nextcloud | No | Core application |
| PostgreSQL | No | Primary database |
| Redis | No | Cache + file locking |
| High-perf Files backend | No | Client push notifications |
| Nextcloud Office (Collabora) | Yes | Online document editing |
| Talk + TURN server | Yes | Video/audio calls |
| Talk Recording server | Yes | Call recording |
| BorgBackup | Yes | Encrypted daily backups |
| ClamAV | Yes | Antivirus scanning |
| Full-text search (OpenSearch) | Yes | File content search |
| Imaginary | Yes | Image previews (HEIC, PDF, SVG, etc.) |
| Whiteboard | Yes | Collaborative whiteboard |

### Nextcloud data directory (important)

Set a custom data dir to avoid data loss on container removal:

```bash
--env NEXTCLOUD_DATADIR=/mnt/ncdata   # or any host path
```

## Upgrade procedure

AIO handles upgrades through the web UI at https://your-server:8080. It:
1. Creates a backup (if BorgBackup is enabled)
2. Pulls updated images
3. Restarts all containers in the correct order

Manual via CLI:
```bash
docker pull nextcloud/all-in-one:latest
docker stop nextcloud-aio-mastercontainer
docker rm nextcloud-aio-mastercontainer
# Re-run the original docker run command
```

## Gotchas

- Port 8080 is the AIO admin UI — protect it (firewall or VPN-only access). It has full control over your Nextcloud instance.
- Docker socket access: AIO needs `/var/run/docker.sock` to manage child containers. This is a security trade-off.
- Domain must be publicly reachable for Let's Encrypt: AIO auto-provisions TLS certificates. The domain must have a public A record pointing to your server and port 80 must be accessible.
- Behind reverse proxy: the reverse proxy setup requires specific configuration (see reverse-proxy.md). Getting it wrong results in broken redirects or HSTS issues.
- Custom data dir: not setting `NEXTCLOUD_DATADIR` stores user files inside the Docker volume — harder to access on the host and easy to lose on `docker rm`.
- Talk (TURN): self-hosted Nextcloud Talk requires proper UDP port opening (3478) for WebRTC. See the Talk docs.
- ClamAV is resource-hungry: only enable if you have spare RAM (1+ GB extra).

## Links

- GitHub: <https://github.com/nextcloud/all-in-one>
- Reverse proxy guide: <https://github.com/nextcloud/all-in-one/blob/main/reverse-proxy.md>
- Community containers: <https://github.com/nextcloud/all-in-one/tree/main/community-containers>
- Docker Hub: <https://hub.docker.com/r/nextcloud/all-in-one>
- Migration from classic Nextcloud: <https://github.com/nextcloud/all-in-one/blob/main/migration.md>
