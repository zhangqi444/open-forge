---
name: leafwiki-project
description: LeafWiki recipe for open-forge. Covers Docker, Docker Compose, binary/installer, and systemd service on Linux. Based on upstream README at https://github.com/perber/leafwiki/blob/main/readme.md.
---

# LeafWiki

Fast, folder-oriented wiki for engineers and self-hosters. Single Go binary, SQLite storage, Markdown files on disk. Upstream: <https://github.com/perber/leafwiki>. Docs: <https://github.com/perber/leafwiki/blob/main/readme.md>.

LeafWiki is a structured wiki with tree navigation, not a flat note browser. Content is stored as Markdown files on disk (easy to back up and version). Features include optional revision history, link refactoring, public read-only mode, and reverse-proxy support via `--base-path`.

## Compatible install methods

| Method | When to use |
|---|---|
| Docker single container | Quickest start; data persisted on host volume |
| Docker Compose | Preferred for compose-managed stacks |
| Installer script (Linux) | Install as a systemd service on Ubuntu/Debian/Raspberry Pi |
| Binary | Smallest footprint; run directly without containers |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "Which install method?" | Docker / Docker Compose / Installer / Binary | Drives which section to follow |
| config | "JWT secret (random string)?" | Free-text (sensitive) | Used to sign session tokens — generate with `openssl rand -hex 32` |
| config | "Initial admin password?" | Free-text (sensitive) | Set on first run; can be changed in admin UI |
| config | "Serve behind HTTPS reverse proxy?" | Yes / No | If yes, omit ALLOW_INSECURE; if no (plain HTTP), add it |
| network | "Port to expose?" | Number (default 8080) | External port; container always listens on 8080 internally |
| data | "Data directory path on host?" | Path (default ~/leafwiki-data) | Stores SQLite DB + Markdown files |

## Software-layer concerns

| Concern | Detail |
|---|---|
| Config method | CLI flags or env vars (prefixed LEAFWIKI_) — both work equivalently |
| Data directory | /app/data inside container — mount a host path for persistence |
| Cookie security | LEAFWIKI_ALLOW_INSECURE=true required for plain-HTTP setups; omit behind HTTPS |
| Non-root | Pass user: 1000:1000 (or -u 1000:1000) — mounted data dir must be writable by that UID |
| Feature flags | --enable-revision (revision history) and --enable-link-refactor (safe link rewriting) are opt-in |
| Base path | --base-path=/wiki for sub-path reverse proxy deployments |
| Default bind | 127.0.0.1 for binary; 0.0.0.0 for Docker. Add --host=0.0.0.0 to binary if LAN access needed |

## Install: Docker single container

Source: https://github.com/perber/leafwiki/blob/main/readme.md#installation

```bash
docker run -d \
  --name leafwiki \
  --restart unless-stopped \
  -p 8080:8080 \
  -u 1000:1000 \
  -v ~/leafwiki-data:/app/data \
  -e LEAFWIKI_JWT_SECRET=<your-jwt-secret> \
  -e LEAFWIKI_ADMIN_PASSWORD=<your-admin-password> \
  -e LEAFWIKI_ALLOW_INSECURE=true \
  ghcr.io/perber/leafwiki:latest
```

Remove `-e LEAFWIKI_ALLOW_INSECURE=true` when serving behind an HTTPS reverse proxy.

## Install: Docker Compose

Source: https://github.com/perber/leafwiki/blob/main/readme.md#docker-compose

```yaml
services:
  leafwiki:
    image: ghcr.io/perber/leafwiki:latest
    container_name: leafwiki
    user: 1000:1000
    ports:
      - "8080:8080"
    environment:
      - LEAFWIKI_JWT_SECRET=yourSecret
      - LEAFWIKI_ADMIN_PASSWORD=yourPassword
      - LEAFWIKI_ALLOW_INSECURE=true  # Remove when behind HTTPS
    volumes:
      - ~/leafwiki-data:/app/data
    restart: unless-stopped
```

```bash
docker compose up -d
```

## Install: Installer script (Linux)

Source: https://github.com/perber/leafwiki/blob/main/readme.md#quick-start-with-the-installer

Installs LeafWiki as a systemd service. Tested on Ubuntu, Debian, Raspbian.

```bash
sudo /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/perber/leafwiki/main/install.sh)"
```

Non-interactive mode:

```bash
cp .env.example .env
# Edit .env with LEAFWIKI_JWT_SECRET, LEAFWIKI_ADMIN_PASSWORD, etc.
sudo ./install.sh --non-interactive --env-file ./.env
```

Environment variables are stored in /etc/leafwiki/.env — restrict file permissions to authorized users.

Deployment examples:
- Install with nginx on Ubuntu: https://github.com/perber/leafwiki/blob/main/docs/install/nginx.md
- Install on Raspberry Pi: https://github.com/perber/leafwiki/blob/main/docs/install/raspberry.md

## Install: Binary

Source: https://github.com/perber/leafwiki/blob/main/readme.md#quick-start-with-a-binary

Download the latest release binary from GitHub Releases (https://github.com/perber/leafwiki/releases), then:

```bash
chmod +x leafwiki
./leafwiki \
  --jwt-secret=yoursecret \
  --admin-password=yourpassword \
  --allow-insecure=true \
  --host=0.0.0.0
```

Multi-platform builds available: Linux, macOS, Windows, ARM64.

## Upgrade procedure

Docker / Compose:
```bash
docker pull ghcr.io/perber/leafwiki:latest
docker compose up -d
```

Binary: Download the new release binary, stop the running process, replace the binary, restart.

Installer: Re-run the installer script — it will upgrade in place.

LeafWiki stores all content as Markdown files in the data directory. Back up the host-mounted path before upgrading.

## Gotchas

- Cookie failure on plain HTTP: Omitting ALLOW_INSECURE on a non-HTTPS setup causes login cookies to fail. Always add it for HTTP-only deployments.
- Non-root UID mismatch: If the mounted ~/leafwiki-data directory is owned by root, the 1000:1000 user inside the container cannot write to it. Run `sudo chown -R 1000:1000 ~/leafwiki-data` first.
- Default binds to localhost: Binary install binds to 127.0.0.1 by default. Add --host=0.0.0.0 if you need LAN or reverse-proxy access from another host.
- Revision history / link refactor are opt-in: These features are behind flags (--enable-revision, --enable-link-refactor). Not enabled by default.
- SQLite single-writer: Designed for small teams. Not intended for high-concurrency write workloads.

## Links

- Upstream README: https://github.com/perber/leafwiki/blob/main/readme.md
- GitHub Releases: https://github.com/perber/leafwiki/releases
- Demo: https://demo.leafwiki.com
- CHANGELOG: https://github.com/perber/leafwiki/blob/main/CHANGELOG.md
