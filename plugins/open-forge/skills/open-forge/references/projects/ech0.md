---
name: ech0
description: Ech0 recipe for open-forge. Covers self-hosting the lightweight personal microblogging/timeline platform. Upstream: https://github.com/lin-snow/Ech0
---

# Ech0

Self-hosted personal microblog and timeline platform. Publish short posts, links, and media to a personal timeline that others can follow and interact with. Lightweight Go binary with SQLite — no external database required. Supports RSS, optional comments, Docker, Helm, and a systemd install script. Upstream: <https://github.com/lin-snow/Ech0>. Docs: <https://www.ech0.app/>.

**License:** AGPL-3.0

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker (single container) | https://github.com/lin-snow/Ech0#try-in-60-seconds | ✅ | Recommended; zero external deps |
| Docker Compose | https://github.com/lin-snow/Ech0/blob/main/DEPLOYMENT.md | ✅ | Docker-based with compose |
| systemd script | https://github.com/lin-snow/Ech0/blob/main/DEPLOYMENT.md | ✅ | Bare-metal Linux; managed by systemd |
| Kubernetes (Helm) | https://github.com/lin-snow/Ech0/blob/main/DEPLOYMENT.md | ✅ | Kubernetes clusters |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| app | "Port to expose Ech0 on?" | Number (default: 6277) | All |
| app | "Data directory on host?" | Absolute path (default: /opt/ech0/data) | Docker |
| secrets | "JWT secret?" | Random string (replace default "Hello Echos") | Required |

## Docker (60-second quickstart)

```bash
docker run -d \
  --name ech0 \
  -p 6277:6277 \
  -v /opt/ech0/data:/app/data \
  -e JWT_SECRET="your-secret-here" \
  sn0wl1n/ech0:latest
```

Open `http://ip:6277`. Register — the **first account becomes Owner (admin)**.

## Docker Compose

Copy `docker/docker-compose.yml` from the repo, or use:

```yaml
services:
  ech0:
    image: sn0wl1n/ech0:latest
    container_name: ech0
    ports:
      - 6277:6277
    volumes:
      - /opt/ech0/data:/app/data
    environment:
      - JWT_SECRET=your-secret-here
    restart: unless-stopped
```

```bash
docker compose up -d
```

## systemd install (bare-metal)

```bash
# Download and run the install script
curl -fsSL "https://raw.githubusercontent.com/lin-snow/Ech0/main/scripts/ech0.sh" -o ech0.sh
sudo bash ech0.sh

# Custom install path:
sudo bash ech0.sh install /your/path/ech0
```

The script installs Ech0 as a systemd service.

## Kubernetes (Helm)

```bash
helm repo add ech0 https://lin-snow.github.io/Ech0
helm repo update
helm install ech0 ech0/ech0
```

## Software-layer concerns

### Key env vars

| Variable | Default | Purpose |
|---|---|---|
| `JWT_SECRET` | `Hello Echos` | **Required** — change this; used to sign auth tokens |
| (port) | 6277 | Configured in compose or via `-p` |

### Data directory

| Path (container) | Purpose |
|---|---|
| `/app/data` | SQLite database and all persistent data |

No external database required — SQLite is embedded.

### First account = Owner

The first user to register on a fresh instance automatically becomes Owner with admin privileges. By default, only privileged accounts can publish posts.

### RSS feed

Ech0 exposes an RSS feed at `/rss` for public timelines.

## Upgrade procedure

```bash
# Docker
docker pull sn0wl1n/ech0:latest
docker compose down && docker compose up -d

# Docker run
docker stop ech0 && docker rm ech0
docker pull sn0wl1n/ech0:latest
docker run -d --name ech0 -p 6277:6277 \
  -v /opt/ech0/data:/app/data \
  -e JWT_SECRET="your-secret-here" \
  sn0wl1n/ech0:latest
```

## Gotchas

- **Change JWT_SECRET immediately.** The default (`Hello Echos`) is in the public README. Any deployment with the default is insecure.
- **First account = admin.** Register your account before sharing the URL; otherwise anyone who finds the instance first becomes owner.
- **SQLite — single-instance only.** Not suitable for clustered/multi-replica deployments without additional configuration.
- **Publishing restricted by default.** Only privileged accounts can publish. Grant publishing rights via the admin panel after registering.
- **AGPL-3.0 license.** Modifications to Ech0 must be made available as open source if you distribute or offer it as a service.

## Upstream docs

- GitHub README: https://github.com/lin-snow/Ech0
- Deployment guide: https://github.com/lin-snow/Ech0/blob/main/DEPLOYMENT.md
- Official site and docs: https://www.ech0.app/
- Releases: https://github.com/lin-snow/Ech0/releases
- Ech0 Hub (federated instances): https://hub.ech0.app/
