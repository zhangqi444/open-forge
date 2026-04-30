---
name: Filestash
description: Storage-agnostic file manager — a web UI that speaks FTP, SFTP, S3, SMB, WebDAV, IPFS, and ~20 other protocols. Think "Dropbox UX on top of any storage backend you already have". Optional Collabora office integration. AGPL-3.0.
---

# Filestash

Filestash is the web file-manager you put in front of any existing storage. Instead of being a storage server, it's a **storage-agnostic UI layer**: point it at an existing S3 bucket, FTP server, SFTP host, WebDAV endpoint, or SMB share, and users get a polished web interface with file preview, editing, sharing, and workflow automation.

Plugin-driven architecture — every storage backend, auth method, file viewer, and workflow action is a plugin. Commercial support and "Filestash Enterprise" plugins available; community tier is functional for most self-hosts.

- Upstream repo: <https://github.com/mickael-kerjean/filestash>
- Website: <https://www.filestash.app>
- Getting started: <https://www.filestash.app/docs/>
- Plugin inventory: <https://www.filestash.app/docs/plugin/>
- Image: `machines/filestash` on Docker Hub

## Compatible install methods

| Infra      | Runtime                                    | Notes                                                                |
| ---------- | ------------------------------------------ | -------------------------------------------------------------------- |
| Single VM  | Docker (`machines/filestash:latest`)       | **Recommended.** Multi-arch                                           |
| Single VM  | Docker + Collabora Office container        | For in-browser docx/xlsx/pptx editing                                 |
| Kubernetes | Plain Deployment + `/app/data/state/` PVC  | Stateless HTTP + small state volume                                   |
| Bare-metal | Binary release                             | Documented at <https://www.filestash.app/docs/install-and-upgrade/>   |

## Inputs to collect

| Input               | Example                                  | Phase     | Notes                                                       |
| ------------------- | ---------------------------------------- | --------- | ----------------------------------------------------------- |
| Port                | `8334:8334`                              | Network   | Filestash's HTTP port                                       |
| `APPLICATION_URL`   | `https://files.example.com`              | Runtime   | Public URL; leave empty for LAN / auto-detect                |
| Admin setup         | via web UI on first visit                | Bootstrap | First visitor at `/admin/` becomes the admin                 |
| Admin password      | set at `/admin/setup`                    | Bootstrap | Stored hashed in `/app/data/state/`                          |
| `CANARY` env        | `true`                                   | Runtime   | Enables beta features                                        |
| State volume        | `filestash:/app/data/state/`             | Data      | Admin settings, saved share links, plugin state              |
| Office integration  | `OFFICE_URL=http://wopi_server:9980`     | Optional  | Point at a Collabora CODE instance for in-browser office     |
| Backends            | FTP / SFTP / S3 / SMB / WebDAV / etc.    | Config    | Configured per-user; connection strings held in state DB     |

## Install via Docker Compose

From <https://github.com/mickael-kerjean/filestash/blob/master/docker/docker-compose.yml>:

```yaml
services:
  app:
    container_name: filestash
    image: machines/filestash:latest
    restart: unless-stopped
    environment:
      - APPLICATION_URL=https://files.example.com
      - CANARY=true
      - OFFICE_URL=http://wopi_server:9980
      - OFFICE_FILESTASH_URL=http://app:8334
      - OFFICE_REWRITE_URL=http://127.0.0.1:9980
    ports:
      - "8334:8334"
    volumes:
      - filestash:/app/data/state/

  wopi_server:
    container_name: filestash_wopi
    image: collabora/code:24.04.10.2.1       # pin Collabora version; moves fast
    restart: unless-stopped
    environment:
      - "extra_params=--o:ssl.enable=false"
      - aliasgroup1=https://.*:443
    command:
      - /bin/bash
      - -c
      - |
        /bin/su -s /bin/bash -c '/start-collabora-online.sh' cool
    user: root
    ports:
      - "9980:9980"

volumes:
  filestash: {}
```

### Minimal (no Office)

```yaml
services:
  filestash:
    image: machines/filestash:latest
    container_name: filestash
    restart: unless-stopped
    ports:
      - "8334:8334"
    volumes:
      - filestash:/app/data/state/
    environment:
      - APPLICATION_URL=https://files.example.com

volumes:
  filestash: {}
```

### First-boot setup

Browse `http://<host>:8334/admin/setup` on first visit → set admin password. Admin panel is at `/admin/`.

Configure backends:
- **Static** — admin pre-defines a backend (e.g. an SFTP server), all users log in against it
- **Per-user** — users paste their own credentials (e.g. personal Dropbox); Filestash acts as a proxy
- **Multi-tenant / shared** — mix of above

## Data & config layout

Inside `/app/data/state/`:

- `config.json` — admin-configured backends, auth plugins, themes, workflow actions
- `state.json` — saved share links, public links, plugin state
- `plugin_*.so` — compiled Go plugins loaded at startup (for community / custom plugins)
- `db/` — SQLite index if search or caching plugins are enabled

Filestash is **mostly stateless** — if your backends are external (S3, FTP, etc.), the state volume is small (a few MB). Losing state = re-configuring admin + re-creating share links, but no user data is stored in Filestash itself.

## Backup

```sh
# Just the state volume
docker run --rm -v filestash:/src -v "$PWD":/backup alpine \
  tar czf /backup/filestash-state-$(date +%F).tgz -C /src .
```

Restore: extract the tar into a new filestash volume. Admin credentials + all backend configs come along.

## Upgrade

1. Releases: <https://github.com/mickael-kerjean/filestash/releases>.
2. Docker: `docker compose pull && docker compose up -d`. State volume persists across restarts.
3. **Pin Collabora too.** `collabora/code:latest` ships breaking changes frequently (branding assets, WOPI endpoints). Pin to a specific version and upgrade Filestash + Collabora in lockstep only after testing.
4. Plugin `.so` files are rebuilt per-release — custom plugins need recompilation against the new Filestash version.
5. No DB migrations in the normal sense (config.json is the state), but watch release notes for breaking config changes.

## Gotchas

- **First visitor to `/admin/setup` claims admin.** Bring Filestash up on a private network first, set admin, THEN expose publicly. Otherwise a race condition makes someone else your admin.
- **`APPLICATION_URL` empty** = Filestash tries to auto-detect from `Host` header. Works for LAN, breaks sometimes behind reverse proxies with weird forwarding. Set it explicitly for production.
- **Collabora integration is finicky.** `OFFICE_URL`, `OFFICE_FILESTASH_URL`, and `OFFICE_REWRITE_URL` must be consistent with how Collabora is reachable from browsers (`OFFICE_REWRITE_URL` — via your public URL) vs how Filestash reaches Collabora internally (`OFFICE_URL` — internal docker service). Misconfigured → "document failed to load".
- **Collabora license.** Collabora CODE (used here) is for personal/evaluation use. Commercial deployments (>20 users) need a Collabora license or should self-host OnlyOffice instead.
- **Per-user credentials are in the session cookie.** Filestash doesn't "store" your S3 key in a DB (for per-user backends); it's in the session. If a user clears cookies → they re-enter credentials.
- **Static backends have shared credentials.** An admin-configured SFTP backend uses one set of credentials for all users. Auth/authorization happens on the Filestash side (IP allowlist, password-gate) before proxying.
- **Share links never expire by default.** Create a share → anyone with the URL can access forever. Set expiry in share settings, or rotate URLs manually.
- **Workflow engine is powerful + foot-gun.** You can chain "on upload" actions to call external APIs, run antivirus, notify Slack, etc. Poorly configured → infinite loops or DoS your own webhook receiver.
- **Plugin `.so` files must match the Filestash version.** Custom plugins rebuilt for 0.7 don't work on 0.8. Plugin Go ABI isn't stable.
- **File previews load full file.** Preview of a 4 GB video = 4 GB downloaded (to Filestash, then streamed). Use a backend with transcoding (S3 + signed URLs with transforms) for large media.
- **AI features** (search, smart folders, OCR) require additional config + depend on Filestash Enterprise plugins. Not on by default in CE.
- **Antivirus plugin** (ClamAV) scans uploads; good for public-facing shares but adds latency per file.
- **IRC support channel** (libera.chat #filestash) is the main support venue; GitHub issues are accepted but less responsive.
- **Commercial "Filestash Enterprise"** unlocks SAML, auditing, and vendor support. CE covers most self-hosts.
- **AGPL-3.0.** Network copyleft — run a modified Filestash as a public service = offer source.
- **Alternatives worth knowing:**
  - **Nextcloud** — storage + more (calendar, contacts, collaborative office), heavier
  - **ownCloud Infinite Scale** — newer Nextcloud-fork architecture (Go + modular)
  - **Cloud Commander** — simpler web file manager
  - **FileBrowser** — simpler single-user-focused alternative, limited to local filesystem
  - **Seafile** — file-sync-first (not just a web UI)
  - **rclone web UI** — adds a WebUI to rclone's backends (different ergonomics)

## Links

- Repo: <https://github.com/mickael-kerjean/filestash>
- Docker compose: <https://github.com/mickael-kerjean/filestash/blob/master/docker/docker-compose.yml>
- Website: <https://www.filestash.app>
- Docs: <https://www.filestash.app/docs/>
- Plugin inventory: <https://www.filestash.app/docs/plugin/>
- Plugin development guide: <https://www.filestash.app/docs/guide/plugin-development.html>
- Workflow engine: <https://www.filestash.app/docs/guide/workflow-engine.html>
- Docker Hub: <https://hub.docker.com/r/machines/filestash>
- Demo: <https://demo.filestash.app>
- Commercial support: <https://www.filestash.app/pricing/>
- Collabora CODE (for office): <https://hub.docker.com/r/collabora/code>
