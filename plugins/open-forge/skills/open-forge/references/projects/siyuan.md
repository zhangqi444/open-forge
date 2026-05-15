---
name: siyuan-project
description: SiYuan recipe for open-forge. AGPLv3 privacy-first personal knowledge management — block-level references, two-way links, Markdown WYSIWYG. Primarily a desktop/mobile Electron+React app but ships a Docker image (`b3log/siyuan`) for server self-host. Covers the Docker + docker-compose flows from upstream README, the MANDATORY access auth code, PUID/PGID for host-volume permissions, and the open-core caveat (sync/backup/AI are paid features; local single-user self-host is free).
---

# SiYuan

AGPLv3 personal knowledge management system. Upstream: <https://github.com/siyuan-note/siyuan>. Docs: <https://docs.siyuan-note.club/en/>. Image: <https://hub.docker.com/r/b3log/siyuan>.

**Desktop-first, optionally self-hostable.** Upstream's recommended install is the native desktop app (Electron). The Docker image exists for "serve SiYuan to myself over a browser from a home server / VPS" — it's single-user, not multi-tenant.

## Open-core model

Most features are free (including commercial use). Paid membership unlocks:

- Official **cloud sync** (S3-compatible self-host is a free alternative)
- **AI features** (bring your own API key is free)
- **Official backup** (self-managed via the `dejavu` data repo snapshots is free)

Full pricing page: <https://b3log.org/siyuan/en/pricing.html>. Everything in this recipe covers the free-tier self-host path.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Desktop installer (Electron) | <https://b3log.org/siyuan/en/download.html> · <https://github.com/siyuan-note/siyuan/releases> | ✅ Recommended | Primary path. Mac / Win / Linux AppImage. |
| Mobile (App Store / Play / F-Droid) | Per store | ✅ | iOS / Android / HarmonyOS. |
| Package managers | <https://repology.org/project/siyuan/versions> | ✅ (community via distro) | AUR / Homebrew cask / nixpkgs etc. |
| Docker `b3log/siyuan` | <https://hub.docker.com/r/b3log/siyuan> | ✅ | Self-host path — the open-forge target. |
| Docker Compose | README §Docker Hosting | ✅ | Preferred over plain `docker run` for persistence + upgrades. |
| Unraid template | README §Unraid Hosting | ✅ | Unraid community apps. |
| TrueNAS template | README §TrueNAS Hosting | ✅ | TrueNAS SCALE. |
| Build from source | `siyuan-note/siyuan` | ✅ | Dev / contributors. Needs Go + Node. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion` | Drives section. |
| auth | "Access auth code?" | Free-text (sensitive, long) | **MANDATORY for non-localhost deploys.** `--accessAuthCode=<code>` or `SIYUAN_ACCESS_AUTH_CODE` env. |
| workspace | "Workspace path on host?" | Free-text, default `/siyuan/workspace` | Mounted into the container at the same path. |
| permissions | "PUID / PGID for the SiYuan process?" | Free-text, default `1000:1000` | Must match the host-user that owns the workspace dir. |
| tz | "Timezone?" (IANA format) | Free-text | `TZ` env. |
| dns | "Public domain + reverse proxy?" | Free-text | SiYuan does not terminate TLS. Caddy/nginx/Traefik in front. |

## Install — Docker (single container)

Per upstream README:

```bash
# 1. Prepare workspace dir with correct ownership
sudo mkdir -p /siyuan/workspace
sudo chown -R 1001:1002 /siyuan/workspace   # match PUID/PGID below

# 2. Run
docker run -d \
  --name siyuan \
  -v /siyuan/workspace:/siyuan/workspace \
  -p 6806:6806 \
  -e PUID=1001 -e PGID=1002 \
  -e TZ=Europe/London \
  --restart unless-stopped \
  b3log/siyuan:v3.6.5 \
  --workspace=/siyuan/workspace/ \
  --accessAuthCode='change-me-to-a-long-secret'
```

Visit `http://<host>:6806/` → prompts for the access auth code.

## Install — Docker Compose (preferred)

```yaml
# docker-compose.yml — based on upstream README
services:
  siyuan:
    image: b3log/siyuan:v3.6.5
    container_name: siyuan
    command:
      - '--workspace=/siyuan/workspace/'
      - '--accessAuthCode=${AUTH_CODE}'
    ports:
      - '6806:6806'
    volumes:
      - /siyuan/workspace:/siyuan/workspace
    environment:
      - TZ=${TZ:-Europe/London}
      - PUID=${PUID:-1000}
      - PGID=${PGID:-1000}
    restart: unless-stopped
```

```bash
cat > .env <<EOF
AUTH_CODE=$(openssl rand -hex 32)
TZ=Europe/London
PUID=1000
PGID=1000
EOF

# Make sure workspace dir matches PUID:PGID
sudo mkdir -p /siyuan/workspace
sudo chown -R 1000:1000 /siyuan/workspace

docker compose up -d
docker compose logs -f siyuan
```

## First-run setup

1. Open `http://<host>:6806/` in a browser.
2. Paste the access auth code.
3. First boot populates the workspace with default notebooks (`guide/`, `data/`, etc.). Disable auth prompt during setup by setting `SIYUAN_ACCESS_AUTH_CODE_BYPASS=true` (dev only).

## Reverse proxy (Caddy)

```caddy
siyuan.example.com {
    reverse_proxy 127.0.0.1:6806
}
```

Ensure WebSocket support is enabled (Caddy has it by default; nginx needs `proxy_set_header Upgrade $http_upgrade; proxy_set_header Connection "upgrade";`). SiYuan's realtime block-sync uses WebSockets.

## Data layout

Everything lives under the workspace dir. Structure:

| Subdir | Content |
|---|---|
| `data/` | All notebooks, block index, attachments. THE thing to back up. |
| `conf/` | Config, layouts, plugins, themes. |
| `history/` | File history (per-op snapshots). |
| `temp/` | Transient; safe to wipe. |
| `repo/` | `dejavu` encrypted snapshot repo (see below). |

### Dejavu data repo (built-in backup)

SiYuan has a built-in Git-like snapshot system called `dejavu` that:

- Encrypts snapshots with a user-provided passphrase (the "data repo key")
- Stores them locally under `repo/`
- Can sync to S3-compatible / WebDAV destinations (free self-host alternative to the paid Cloud sync)

Configure in Settings → **Cloud / Data Repo**. **Losing the data repo key is fatal** — if you forget it, every existing snapshot is unrecoverable. Upstream's FAQ says it cannot be recovered by them either.

## Upgrade procedure

```bash
# Docker Compose
docker compose pull
docker compose up -d
docker compose logs -f siyuan
```

SiYuan runs in-place schema migrations on first boot of a new version. Backup the workspace FIRST:

```bash
cd /path/to/compose
docker compose down
sudo tar -czf siyuan-backup-$(date +%F).tar.gz /siyuan/workspace
docker compose up -d
```

Or use the built-in Dejavu snapshot (Settings → Data Repo → Create Snapshot) before pulling a new image.

## Gotchas

- **`--accessAuthCode` is mandatory on any non-localhost deploy.** Without it, your notes are world-readable. Setting `SIYUAN_ACCESS_AUTH_CODE_BYPASS=true` disables auth — NEVER on public-facing hosts.
- **Single-user.** The Docker image is not multi-tenant. For team use, run one container per user (or use the commercial cloud offering).
- **PUID/PGID must match host-volume ownership.** If the workspace dir is owned by `1000:1000` but you pass `PUID=1001 PGID=1002`, SiYuan will fail to read/write and crash-loop. Match them.
- **Data repo key loss = permanent data loss.** Write it down in a password manager BEFORE creating your first snapshot. Upstream cannot recover it.
- **WebSocket passthrough at the reverse proxy** is required for realtime features (sync, co-editing). Default Caddy works; nginx needs explicit Upgrade/Connection headers.
- **"Kernel" vs "UI" confusion.** SiYuan splits into a Go backend ("kernel") and an Electron UI. The Docker image runs ONLY the kernel + serves the UI as static assets; you can point the desktop app at a remote kernel (Settings → About → Kernel URL) for desktop-as-thin-client workflows.
- **AGPLv3.** Modifying and redistributing requires source disclosure. Running a modified copy for a team across a network counts as "distribution" under AGPL — check with counsel for commercial use of forks.
- **Paid-only features in the free build.** AI, Cloud sync (official), and some publishing features show a paywall in the UI. They are NOT removed from the binary; you just can't subscribe without paying. BYOK for AI + S3 for sync is free.
- **Mobile has its own auth flow.** The mobile apps connect to the self-hosted kernel via the same `:6806` — require HTTPS + valid cert, not self-signed, or mobile WebView will reject the connection.
- **Chinese-first community.** Upstream forums / most tutorials are in Chinese; English forum is at <https://liuyun.io>. Error messages sometimes ship English-only but docs are translated with some lag.

## Links

- Upstream repo: <https://github.com/siyuan-note/siyuan>
- Official site: <https://b3log.org/siyuan/en/>
- Docs (EN): <https://docs.siyuan-note.club/en/>
- Release notes: <https://github.com/siyuan-note/siyuan/blob/master/CHANGELOG.md>
- Docker image: <https://hub.docker.com/r/b3log/siyuan>
- API: <https://github.com/siyuan-note/siyuan/blob/master/API.md>
- English forum: <https://liuyun.io>
- Dejavu (data repo): <https://github.com/siyuan-note/dejavu>
- Pricing (paid features): <https://b3log.org/siyuan/en/pricing.html>
