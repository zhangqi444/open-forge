---
name: FileBrowser Quantum
description: "Major fork of the classic filebrowser — web-based file manager with modern UI, multi-source config, OIDC/LDAP/JWT/2FA login, SQLite-indexed real-time search, advanced sharing, directory-level ACLs, API tokens. Go single binary + static frontend. Apache-2.0."
---

# FileBrowser Quantum

FileBrowser Quantum is **a modernized fork of the popular `filebrowser/filebrowser` project** — a single-binary Go app that gives you a web UI over one or more folders on your server. Sharing, previews, previews-for-office/video/audio/3D-models, per-directory ACLs, indexed search as you type, real-time updates. Tiny (~180 MB Docker image with ffmpeg), fast, no external DB required.

> **Fork-supersedes-parent note:**
>
> - The **original `filebrowser/filebrowser`** project exists and is still maintained, but upstream development pace and feature velocity have slowed.
> - **FileBrowser Quantum** is a significant rewrite by `gtsteffaniak` with features the original lacks (OIDC/LDAP/JWT/2FA login, better sharing, SQLite-indexed search, multi-source configuration, directory-level ACL).
> - **Different Docker image** (`gtstef/filebrowser`) — **NOT** drop-in compatible with the original `filebrowser/filebrowser` config; settings + DB schema differ.
> - **Shell-command feature REMOVED** (intentionally — original had `commands` for running shell scripts; Quantum removed this for security and has no plans to re-add).

Features (what Quantum adds over classic):

- **Multiple sources** — serve several folders as separate "shares" from one instance
- **OIDC + LDAP + JWT + proxy + password + 2FA** logins (classic = just password)
- **SQLite-indexed search** — real-time, typeahead, with filter predicates (size, date)
- **Folder sizes** in listings (classic omits)
- **Scroll memory** across navigation
- **Rich sharing** — expiration, anonymous/authed access, theming, fine-grained permissions (view/edit/upload)
- **Directory-level ACLs** — per user/group
- **Long-lived API tokens + Swagger** page at `/swagger`
- **YAML config file** (classic uses flags + internal DB)
- **Modern UI** — responsive, animations, better thumbnails (office/video/3D)

- Upstream repo: <https://github.com/gtsteffaniak/filebrowser>
- Docs: <https://filebrowserquantum.com>
- Docker Hub: <https://hub.docker.com/r/gtstef/filebrowser>
- Classic filebrowser (for comparison): <https://github.com/filebrowser/filebrowser>

## Architecture in one minute

- **Single Go binary** (+ optional ffmpeg sidecar for video thumbs)
- **SQLite** for users, share links, and the **search index** (all in one file)
- **Config**: YAML (`config.yaml`) — declarative
- **Stateless-ish**: just needs the config file + the SQLite DB file + the data directories
- **Resource**: tiny — 512 MB RAM floor, fine on Pi

## Compatible install methods

| Infra        | Runtime                                      | Notes                                                              |
| ------------ | -------------------------------------------- | ------------------------------------------------------------------ |
| Single VM    | **Docker (`gtstef/filebrowser`)**                | **Simplest**                                                              |
| Single VM    | **Standalone binary** from releases                    | No Docker needed                                                               |
| Raspberry Pi | Binary (arm64/armv7) or Docker                                | Great fit                                                                           |
| Synology/QNAP | Docker via NAS UI                                                  | Works                                                                                       |
| Kubernetes   | Deploy Docker image; mount PVC                                             | Works; one replica                                                                                   |
| Managed      | — (no official SaaS)                                                                  |                                                                                                              |

## Inputs to collect

| Input        | Example                        | Phase     | Notes                                                             |
| ------------ | ------------------------------ | --------- | ----------------------------------------------------------------- |
| Domain       | `files.example.com`                | URL       | Reverse proxy with TLS                                               |
| Data paths   | `/srv/media`, `/srv/docs`                 | Storage   | Each = one "source" in config                                                    |
| Admin user   | set in config / first-run             | Bootstrap | Change default creds                                                                   |
| Auth         | password / OIDC / LDAP / JWT / proxy        | Auth      | Mix and match                                                                                   |
| Port         | `8080` internal                                   | Network   | Proxy exposes via 443                                                                                       |
| Config file  | mounted `config.yaml`                                   | Config    | YAML, reloadable                                                                                                         |

## Install via Docker Compose

```yaml
services:
  filebrowser:
    image: gtstef/filebrowser:latest-ffmpeg        # pin specific tag in prod
    container_name: filebrowser
    restart: unless-stopped
    environment:
      TZ: UTC
    volumes:
      - ./config.yaml:/home/filebrowser/config.yaml:ro
      - ./data:/home/filebrowser/data               # DB + indexes + logs
      - /srv/media:/srv/media                       # data sources
      - /srv/docs:/srv/docs
    ports:
      - "8080:8080"
```

### Minimal `config.yaml`

```yaml
server:
  port: 8080
  baseURL: ""
  sources:
    - path: /srv/media
      name: "Media"
    - path: /srv/docs
      name: "Documents"
auth:
  methods:
    password:
      enabled: true
    # oidc:
    #   enabled: true
    #   clientId: ...
    #   clientSecret: ...
    #   issuerUrl: https://sso.example.com/realms/main
```

Full config reference: <https://filebrowserquantum.com/en/docs/configuration/>.

## First boot

1. Browse `https://files.example.com/`
2. Log in as default admin (see docs for initial creds) → **change password immediately**
3. Users → create per-user accounts; set per-directory access
4. Visit a source → upload/create/preview files
5. Select file → Share → configure expiration + auth + permissions → get link
6. API: Settings → generate API token → `/swagger` for docs

## Data & config layout

- `config.yaml` — your config
- `data/filebrowser.db` — SQLite (users, shares, search index)
- `data/logs/` — logs (if enabled)
- Your source directories — untouched filesystem; Quantum just serves them

## Backup

```sh
# DB + config
tar czf fbq-$(date +%F).tgz config.yaml data/
```

User data = your filesystems; back those up with your usual tool (Restic/Borg/rsync).

## Upgrade

1. Releases: <https://github.com/gtsteffaniak/filebrowser/releases>. Active.
2. Back up `data/filebrowser.db` + `config.yaml` before bumping.
3. Docker: bump tag.
4. Binary: stop, replace binary, restart.
5. Read release notes for `config.yaml` breaking changes.

## Gotchas

- **Not compatible with classic filebrowser.** Config file format, DB schema, URL endpoints differ. Migrating from classic = export users/shares via API (if possible) and recreate in Quantum; or accept fresh-start.
- **Default admin credentials** — **change immediately.** Don't expose to the internet before doing so.
- **Shell commands are gone.** If your workflow depended on the classic `commands` feature to run scripts server-side, Quantum won't work — that was removed for security and isn't coming back.
- **Index rebuilds on directory changes** — Quantum watches filesystems, but massive add/delete bursts can spike CPU. For millions of files, index size + build time can be significant; tune `indexing` options.
- **Thumbnails require ffmpeg** — use the `-ffmpeg` image variant for video + office previews. Without, only image thumbs work.
- **Office thumbnails** — need LibreOffice/unoconv configured; see docs.
- **No shell access = no editing files directly in the container**. Mount a volume + edit from host.
- **Multiple sources** — each source is a separate index; switching between them works but isn't a single merged view.
- **Shares** with no expiration never expire; audit periodically.
- **Public shares** — any shared URL with "anonymous" access = anyone with link has access. Treat URLs as capabilities.
- **No built-in reverse proxy / HTTPS** — front with Caddy/Traefik/Nginx/Pangolin/Cloudflare Tunnel.
- **Webdav** — Quantum lists "yes" in comparison table; verify current state; configure in config.yaml.
- **No S3 backend** (as of current fork state) — serves local filesystems only. Use Filestash if you need S3/FTP/SFTP backends.
- **No mobile app** — responsive web only. PWA install works.
- **Active development, pre-2.x** — fast-moving fork; some features marked `:construction:`. Pin versions; read release notes.
- **License**: Apache-2.0.
- **Alternatives worth knowing:**
  - **Classic filebrowser** (`filebrowser/filebrowser`) — the parent project; simpler; still maintained
  - **Filestash** — multi-backend (S3, FTP, SFTP, WebDAV, GDrive, Dropbox, Backblaze); AGPL-3.0
  - **Nextcloud** — much more than files (calendar, contacts, Talk) but heavier (separate recipe)
  - **Seafile** — file-sync focused (separate recipe)
  - **Duplicacy / Restic** + **Resilio Sync / Syncthing** — sync, not a web UI
  - **rclone + webui** — CLI+web for remote backends
  - **CloudCommander** — minimal Node-based file manager
  - **Choose Quantum if:** you want the best modern free self-hosted file web UI with auth + search + sharing.
  - **Choose classic filebrowser if:** stability + simplicity + the original upstream; don't need OIDC/LDAP/2FA/shell-free constraints.
  - **Choose Filestash if:** you need S3/FTP/SFTP/cloud-drive backends.
  - **Choose Nextcloud if:** you want the full collaboration suite + a mobile app + CalDAV/CardDAV.

## Links

- Repo: <https://github.com/gtsteffaniak/filebrowser>
- Docs: <https://filebrowserquantum.com>
- Getting started: <https://filebrowserquantum.com/en/docs/getting-started/>
- Configuration: <https://filebrowserquantum.com/en/docs/configuration/>
- Sources config: <https://filebrowserquantum.com/en/docs/configuration/sources/>
- Shares options: <https://filebrowserquantum.com/en/docs/shares/options/>
- Docker Hub: <https://hub.docker.com/r/gtstef/filebrowser>
- Releases: <https://github.com/gtsteffaniak/filebrowser/releases>
- Discussions (announcements): <https://github.com/gtsteffaniak/filebrowser/discussions>
- Docs repo: <https://github.com/quantumx-apps/filebrowserDocs>
- Classic filebrowser (comparison): <https://github.com/filebrowser/filebrowser>
- Filestash (alternative): <https://github.com/mickael-kerjean/filestash>
