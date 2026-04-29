---
name: Calibre-Web
description: Clean web UI to browse, read, and download ebooks from an existing Calibre library (`metadata.db`). Python/Flask. GPL-3.0. Often paired with Calibre desktop for library management.
---

# Calibre-Web

Calibre-Web is a read-and-browse frontend for a Calibre library. It does **not** manage your library the way the Calibre desktop app does — it reads `metadata.db` that Calibre created, lets users browse/search, sends books to Kindle/Kobo, serves OPDS, and supports on-the-fly conversion if a `calibre` binary is available.

For a self-hosting recipe, this means two decisions:

1. **Where does `metadata.db` live?** Typically a shared volume, written by the Calibre desktop/CLI and read by Calibre-Web.
2. **Do you need on-the-fly format conversion?** If yes, you need the full `calibre` binary — either via the LSIO `universal-calibre` mod or a second container.

- Upstream repo: <https://github.com/janeczku/calibre-web>
- Wiki (canonical docs): <https://github.com/janeczku/calibre-web/wiki>
- Community Docker: `lscr.io/linuxserver/calibre-web` (LinuxServer.io)
- Alternative Docker: upstream provides pip install; for Docker they explicitly point users to LSIO

## Compatible install methods

| Infra         | Runtime                                    | Notes                                                                      |
| ------------- | ------------------------------------------ | -------------------------------------------------------------------------- |
| Single VM     | Docker + `lscr.io/linuxserver/calibre-web` | **Recommended.** Upstream's README explicitly points to this image          |
| Single VM     | `pip install calibreweb` into venv         | Upstream's "recommended" non-Docker path                                   |
| Bare metal    | Distro package (some distros)              | Often stale; pip is fresher                                                 |
| NAS (Synology/QNAP/Unraid) | LSIO image                    | LinuxServer community maintains templates for every major NAS platform      |

## Inputs to collect

| Input               | Example                             | Phase    | Notes                                                                  |
| ------------------- | ----------------------------------- | -------- | ---------------------------------------------------------------------- |
| Calibre library     | `/srv/calibre/library` (contains `metadata.db`) | Data | **Pre-existing.** Calibre-Web does not initialize libraries     |
| `PUID` / `PGID`     | `1000` / `1000`                     | Runtime  | Match the owner of the library files to avoid permission fights        |
| Port                | `8083:8083`                         | Network  | No built-in TLS; put behind reverse proxy for HTTPS                    |
| `DOCKER_MODS`       | `linuxserver/mods:universal-calibre` | Runtime | Optional; adds ~400 MB but enables `ebook-convert` (x64 only)         |
| Admin login         | `admin` / `admin123`                | **SECURITY** | **Default admin is public.** Change on first login                      |
| Kindle email/SMTP   | any SMTP provider                   | Runtime  | Needed for "Send to Kindle" feature                                    |

## Install via Docker Compose (LinuxServer image)

From upstream README (pointing to LSIO):

```yaml
services:
  calibre-web:
    image: lscr.io/linuxserver/calibre-web:latest
    container_name: calibre-web
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
      - DOCKER_MODS=linuxserver/mods:universal-calibre   # optional: adds ebook-convert (x64 only)
      - OAUTHLIB_RELAX_TOKEN_SCOPE=1                     # optional: for some OAuth providers
    volumes:
      - /path/to/calibre-web/data:/config                # app state (sqlite, user settings)
      - /path/to/calibre/library:/books                  # your Calibre library (contains metadata.db)
    ports:
      - 8083:8083
    restart: unless-stopped
```

Prefer pinning instead of `:latest`. Browse available tags at <https://github.com/linuxserver/docker-calibre-web/pkgs/container/calibre-web>.

## Install via pip (upstream's "recommended")

Per <https://github.com/janeczku/calibre-web/blob/master/README.md>:

```sh
python3 -m venv calibre-web-env
source calibre-web-env/bin/activate
pip install calibreweb
cps                           # starts on :8083
```

For optional extras (SSO, LDAP, comics, Goodreads metadata), see <https://github.com/janeczku/calibre-web/wiki/Dependencies-in-Calibre-Web-Linux-and-Windows>.

Run under systemd with a unit that sources the venv and runs `cps`. The pip path does not handle `ebook-convert` for you — install Calibre separately and set the binary path in the admin UI.

## First-run setup

1. Browse `http://<host>:8083`.
2. Log in as `admin` / `admin123`. **Change the password.**
3. In `Admin → Configuration`, set `Location of Calibre database` to the path of the directory containing `metadata.db` — inside the container that's `/books` (LSIO image) or whatever you bind-mounted.
4. If using the `universal-calibre` mod: set `Path to Calibre Binaries` = `/usr/bin`, `Path to Unrar` = `/usr/bin/unrar`.
5. Optional: configure SMTP for "Send to Kindle"; enable OAuth/LDAP; create non-admin users.

## Data & config layout

- `/config` (LSIO container) → `app.db` (Calibre-Web's own sqlite with users/settings), `gdrive.db`, `session` files, `log.log`
- `/books` → Calibre library — contains `metadata.db` (Calibre's catalogue) + per-book directories with EPUBs/PDFs/cover images

**The two databases are separate.** `metadata.db` is Calibre's; `app.db` is Calibre-Web's. Never edit `metadata.db` directly while either Calibre or Calibre-Web is running — file-level locks are lax.

## Backup

```sh
# Calibre-Web state
docker run --rm -v /path/to/calibre-web/data:/src -v "$PWD":/backup alpine \
  tar czf "/backup/calibreweb-config-$(date +%F).tgz" -C /src .

# Library (large)
rsync -a --delete /path/to/calibre/library/ /backup/calibre-library/
```

If you also run Calibre desktop against the same library, stop it before snapshots of `metadata.db` to avoid torn pages.

## Upgrade

**LSIO image:** `docker compose pull && docker compose up -d`. LSIO rebuilds weekly on top of Alpine/Debian base images; upstream Calibre-Web releases are tracked.

**pip install:** `pip install --upgrade calibreweb`, then restart the service.

Calibre-Web occasionally changes the `app.db` schema; it auto-migrates on boot. Back up `/config/app.db` before major jumps.

Upgrade notes live on the wiki: <https://github.com/janeczku/calibre-web/wiki/Updates>.

## Gotchas

- **Default admin `admin` / `admin123` is public.** Change on first login. There is no "force change on first login" flag.
- **Calibre-Web does NOT manage your library.** It reads a library created by Calibre desktop or `calibredb`. Don't point it at an empty directory and expect it to create `metadata.db` — it will refuse to start with an error about missing database.
- **On-the-fly conversion needs Calibre binaries.** `DOCKER_MODS=linuxserver/mods:universal-calibre` adds ~400 MB but enables `ebook-convert`. **x86_64 only** — ARM users must pick: lightweight image with no conversion, or drop to running Calibre desktop alongside on a capable host.
- **PUID/PGID mismatches cause silent failures.** If the LSIO container runs as UID 1000 but your library is owned by UID 1001, Calibre-Web can read but not write (metadata edits silently fail). Match or chown.
- **"Send to Kindle" needs Amazon to allow your SMTP sender.** Add the from-address to each user's Amazon Approved Email list or mail bounces silently.
- **No built-in TLS.** Put behind Caddy/Traefik/nginx. Calibre-Web respects `X-Forwarded-Proto` and friends for reverse-proxy setups.
- **Default uploader role is off.** To let users upload, enable "Allow uploads" in user settings.
- **Google Drive integration exists but is fragile** — Google's OAuth flow requires a paid developer account for production verification. Most users ignore it and just mount a local library.
- **Reverse-proxy subpath deployments** (`https://example.com/calibre-web`) need `APPLICATION_ROOT` set in the Flask config AND the reverse proxy to not strip the prefix.
- **OPDS feed is unauthenticated by default** on some older versions — always enable OPDS authentication in admin settings, or the feed leaks your full catalogue.
- **Calibre library on a network share** (SMB/NFS) causes sporadic "database is locked" errors on busy servers. SQLite doesn't play well with many network filesystems; prefer local storage.
- **`metadata.db` written by a very new Calibre** may use schema features older Calibre-Web can't read. Keep Calibre desktop and Calibre-Web reasonably close in release timing.
- **`OAUTHLIB_RELAX_TOKEN_SCOPE=1`** is a workaround for providers that return fewer scopes than requested (GitHub, some Keycloak configs). Leave unset unless OAuth login fails with a scope error.
- **Comic-book support** (CBR/CBZ) needs the `unrar` binary inside the container — present in the LSIO image at `/usr/bin/unrar`, absent in some alternatives.
- **Goodreads scraping is rate-limited + frequently broken** upstream; don't rely on automatic metadata refresh for large imports.

## Links

- Repo: <https://github.com/janeczku/calibre-web>
- Wiki: <https://github.com/janeczku/calibre-web/wiki>
- Releases: <https://github.com/janeczku/calibre-web/releases>
- LinuxServer Docker repo: <https://github.com/linuxserver/docker-calibre-web>
- LinuxServer image: `lscr.io/linuxserver/calibre-web`
- `universal-calibre` DOCKER_MODS: <https://github.com/linuxserver/docker-mods/tree/universal-calibre>
- Configuration wiki: <https://github.com/janeczku/calibre-web/wiki/Configuration>
- Updates wiki: <https://github.com/janeczku/calibre-web/wiki/Updates>
- Main Calibre project (library manager): <https://calibre-ebook.com/>
