---
name: lesma
description: Lesma recipe for open-forge. Simple paste app friendly with browser and command line, file-based storage, no database. Rust + Docker. Source: https://gitlab.com/ogarcia/lesma
---

# Lesma

A simple paste app, friendly with both browser and command line. Stores pastes as files (no database), supports download limits, expiration times, file deduplication, and curl-based CLI usage. GPL-3.0 licensed, written in Rust. Upstream: <https://gitlab.com/ogarcia/lesma>. Demo: <https://lesma.eu>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux VPS | Docker / container | Official image from GitLab Container Registry |
| Linux x86_64 | Native binary | Pre-built binary available for linux-amd64 |
| Any Linux (ARM etc.) | Build from source | Rust build required for non-amd64 |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain for Lesma?" | FQDN | e.g. paste.example.com |
| "Storage directory for paste files?" | Directory path | Persistent directory; default /var/lib/lesma |
| "Port to expose?" | Number | Configure in lesma.toml |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Max paste size?" | Bytes | Configurable in lesma.toml |
| "Default expiration time?" | Duration | e.g. 24h, 7d; configurable |
| "Reverse proxy?" | NGINX / Caddy / none | Recommended for HTTPS |

## Software-Layer Concerns

- **File-based storage**: No database — pastes stored as flat files in the configured storage directory. Mount as persistent volume.
- **No cron jobs**: Cleanup of expired pastes handled internally — no external cron needed.
- **Deduplication**: Identical content stored once; separate links generated per upload.
- **CLI friendly**: Paste via curl: `curl -F 'data=@file.txt' https://lesma.eu/`
- **Config file**: `lesma.toml` (copied from `lesma.toml.example`) — sets port, storage path, limits, expiry.
- **Dynamic user in systemd**: The provided systemd unit uses a dynamic user with persistent directory at `/var/lib/lesma`.
- **ARM/non-amd64**: Only linux-amd64 binary provided upstream — must compile from source for Raspberry Pi and similar.

## Deployment

### Container

```bash
docker run -d \
  -p 8080:8080 \
  -v lesma_data:/var/lib/lesma \
  registry.gitlab.com/ogarcia/lesma:latest
```

Or with Docker Compose:

```yaml
services:
  lesma:
    image: registry.gitlab.com/ogarcia/lesma:latest
    ports:
      - "8080:8080"
    volumes:
      - lesma_data:/var/lib/lesma
    restart: unless-stopped

volumes:
  lesma_data:
```

### Native binary (linux-amd64)

```bash
# Download latest release from https://gitlab.com/ogarcia/lesma/-/releases
tar xf lesma-X.X.X-linux-amd64.tar.xz
cd lesma-X.X.X-linux-amd64
sudo mkdir -p /usr/lib/lesma
sudo cp -r static templates /usr/lib/lesma
sudo install -m755 lesma /usr/bin/lesma
sudo install -m644 lesma.toml.example /etc/lesma.toml
sudo vim /etc/lesma.toml

# systemd unit from AUR
sudo curl 'https://aur.archlinux.org/cgit/aur.git/plain/lesma.service?h=lesma' \
  -o /etc/systemd/system/lesma.service
sudo systemctl enable --now lesma
```

### CLI usage

```bash
# Paste text
echo "hello world" | curl -F 'data=@-' https://your-lesma-instance.com/

# Paste a file
curl -F 'data=@myfile.txt' https://your-lesma-instance.com/

# With expiry and download limit
curl -F 'data=@file.txt' -F 'expire=1d' -F 'limit=5' https://your-lesma-instance.com/
```

## Upgrade Procedure

1. Container: `docker compose pull && docker compose up -d`
2. Native: download new release, stop service, replace binary and static files, restart.
3. Data directory persists — no migration needed.

## Gotchas

- **linux-amd64 only for pre-built binary**: Must compile from source for ARM (Raspberry Pi, etc.) — requires Rust toolchain.
- **Storage dir permissions**: The storage directory must be writable by the lesma process (or container user).
- **Static + templates dirs required**: Native install needs `static/` and `templates/` alongside the binary — copy from the release tarball.

## Links

- Source: https://gitlab.com/ogarcia/lesma
- Releases: https://gitlab.com/ogarcia/lesma/-/releases
- Demo: https://lesma.eu
