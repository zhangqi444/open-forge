---
name: quickshare
description: Recipe for QuickShare — a self-hosted file sharing service with multi-user support, quotas, speed limiting, resumable transfers, QR sharing, and folder management. Go + Docker.
---

# QuickShare

Self-hosted file sharing service for sharing files and folders between devices. Supports multiple users with role-based access (admin/user), per-user upload/download speed limits and space quotas, resumable uploads/downloads, folder management, QR code sharing, and fuzzy file search. Single Go binary with no external database dependency. Upstream: <https://github.com/ihexxa/quickshare>. Website: <https://ihexxa.github.io/quickshare.site/>.

License: LGPL-3.0. Platform: Go, Docker. Port: `8686`. Stars: ~629.

## Compatible install methods

| Method | When to use |
|---|---|
| Docker (single container) | Recommended |
| Binary | For minimal-dependency installs |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| auth | "Admin username?" | Set via `DEFAULTADMIN` env var (default: `qs`) |
| auth | "Admin password?" | Set via `DEFAULTADMINPWD` env var — change from default `1234` immediately |
| network | "Host port for the web UI?" | Default `8686` |
| storage | "Host path for file storage?" | Mapped to `/quickshare/root` inside the container |

## Docker (recommended)

```bash
mkdir quickshare && cd quickshare
mkdir -p root
```

`docker-compose.yml`:
```yaml
services:
  quickshare:
    image: hexxa/quickshare:latest
    restart: unless-stopped
    ports:
      - "8686:8686"
    environment:
      - DEFAULTADMIN=admin
      - DEFAULTADMINPWD=changeme
    volumes:
      - ./root:/quickshare/root
```

```bash
docker compose up -d
```

Web UI at `http://your-host:8686`. Log in with the admin credentials you set.

## Minimal Docker run

```bash
docker run \
  --name quickshare \
  -d -p 8686:8686 \
  -v $(pwd)/quickshare/root:/quickshare/root \
  -e DEFAULTADMIN=admin \
  -e DEFAULTADMINPWD=changeme \
  hexxa/quickshare
```

## Configuration via `settings.json`

After first run, `root/0/settings.json` is created. Key settings:

```json
{
  "site": {
    "siteName": "My QuickShare",
    "siteDesc": "Private file sharing"
  },
  "users": {
    "defaultSpaceLimit": "1073741824"
  }
}
```

Restart the container after editing.

## Software-layer concerns

| Concern | Detail |
|---|---|
| Storage | `./root/` on host — all files, metadata, and config |
| Default port | `8686` |
| Database | Embedded (no external DB needed) |
| Config file | `root/0/settings.json` |
| Upload method | Chunked/resumable upload API |
| File access from OS | Mount `./root/files/` for direct OS access |

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Settings and files in `./root/` are preserved across upgrades.

## Gotchas

- **Change default password**: The default admin password in the upstream README is `1234`. Always set `DEFAULTADMINPWD` to something strong before first run.
- **`DEFAULTADMIN`/`DEFAULTADMINPWD` are only applied on first run**: If the `root/` directory already exists with a database, these env vars are ignored. Reset by deleting `root/` (this deletes all data).
- **Not backward compatible (under active development)**: The upstream README warns that full backward compatibility between versions is not guaranteed. Test upgrades in a staging environment if you have important data.
- **No HTTPS built-in**: QuickShare serves plain HTTP on port 8686. Place it behind a TLS-terminating reverse proxy (nginx, Caddy) for production use.
- **Folder sharing via QR**: The QR code sharing feature generates a link to a shared folder. The link URL is based on the host where QuickShare is running — ensure the correct public URL is accessible.
- **Per-user quota and speed limits**: Configurable per user from the admin panel after login.

## Upstream links

- Source: <https://github.com/ihexxa/quickshare>
- Docker Hub: <https://hub.docker.com/r/hexxa/quickshare>
- Screenshots: <https://github.com/ihexxa/quickshare/blob/main/docs/screenshots.md>
