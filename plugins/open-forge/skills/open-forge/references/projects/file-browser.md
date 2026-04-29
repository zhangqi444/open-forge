---
name: file-browser-project
description: File Browser recipe for open-forge. Apache-2.0 single-binary Go web file manager — browse, upload, preview, edit files and folders through a web UI with multi-user support + per-user scopes. As of 2026 upstream (`filebrowser/filebrowser` original) is in **maintenance-only mode** per hacdias (no new features, bug/security fixes only). An actively-developed community fork `gtsteffaniak/filebrowser` exists. Covers the original maintenance-mode binary (Docker + systemd), the `filebrowser/filebrowser` Docker image, and the gtsteffaniak fork as a modern alternative.
---

# File Browser

Apache-2.0 single-binary Go web file manager. Upstream: <https://github.com/filebrowser/filebrowser>. Docs: <https://filebrowser.org>.

A web interface in front of a specified directory — browse, upload, download, preview (images, PDFs, video, audio), edit text files, create/delete/rename/move, share files via public links, per-user access scopes, basic auth.

## ⚠️ Maintenance-only upstream as of 2026

Per upstream README (quoting hacdias, 2026-03-11):

> *This project is a finished product which fulfills its goal: be a single binary web File Browser which can be run by anyone anywhere. That means that File Browser is currently on **maintenance-only** mode.*
> *- It can take a while until someone gets back to you. Please be patient.*
> *- No new features are planned. Pull requests for new features are not guaranteed to be reviewed.*
> *- The priority is triaging issues, addressing security issues and reviewing pull requests meant to solve bugs.*

**Translation:** security fixes yes, bug fixes maybe, new features no.

Active alternatives:

- **gtsteffaniak/filebrowser** (<https://github.com/gtsteffaniak/filebrowser>) — a community fork with active development, more features (better search, multiple sources, improved permissions), and a compatible data format.
- **Files.gg / Nextcloud Files / Pydio Cells / Cryptpad** — heavier but actively developed if you need a full sync-and-share platform.

This recipe covers the upstream `filebrowser/filebrowser` as the default (many users are still on it and it works) AND calls out the fork path.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker image (`filebrowser/filebrowser`) | Docker Hub | ✅ | Most self-hosters. |
| Binary (download + systemd) | <https://github.com/filebrowser/filebrowser/releases> | ✅ | Bare metal / non-Docker hosts. |
| Install script (`curl | bash`) | <https://raw.githubusercontent.com/filebrowser/get/master/get.sh> | ✅ | Downloads the right binary for your OS/arch. |
| Build from source (Go) | `go build` | ✅ | Custom builds. |
| `gtsteffaniak/filebrowser` fork | <https://github.com/gtsteffaniak/filebrowser> | ⚠️ Fork, active | If you want ongoing new features. Config format is compatible but some options differ. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Use upstream (maintenance-only) or `gtsteffaniak` fork?" | `AskUserQuestion` | Sets which image/binary you install. |
| preflight | "Install method?" | `AskUserQuestion`: `docker` / `binary` / `install-script` | Drives section. |
| data | "Host path to manage?" | Free-text, default `/srv` | Mounted at `/srv` inside the container. This is what users browse. |
| storage | "Where to put config/DB?" | Free-text, default `./filebrowser-data/` | Contains `filebrowser.db` (bolt DB with users+settings). |
| admin | "Initial admin credentials?" | Free-text (sensitive) | Default is `admin` / (generated — printed to logs on first boot) OR `admin` / `admin` in older images. **Change on first login.** |
| dns | "Public domain?" | Free-text | For reverse proxy + TLS. |
| tls | "Reverse proxy? (Caddy / nginx / Traefik / skip)" | `AskUserQuestion` | File Browser has built-in TLS via flags but a reverse proxy is cleaner. |

## Install — Docker (upstream)

```yaml
# compose.yaml
services:
  filebrowser:
    image: filebrowser/filebrowser:latest     # pin a specific digest in prod
    container_name: filebrowser
    restart: unless-stopped
    ports:
      - "8080:80"
    volumes:
      - /srv:/srv                              # files users will see
      - ./filebrowser-data/database.db:/database.db
      - ./filebrowser-data/.filebrowser.json:/.filebrowser.json
    user: "1000:1000"                          # match host user owning /srv
```

Bootstrap on first run:

```bash
mkdir -p ./filebrowser-data
touch ./filebrowser-data/database.db ./filebrowser-data/.filebrowser.json
sudo chown -R 1000:1000 ./filebrowser-data

# Example minimal config
cat > ./filebrowser-data/.filebrowser.json <<'EOF'
{
  "port": 80,
  "baseURL": "",
  "address": "",
  "log": "stdout",
  "database": "/database.db",
  "root": "/srv"
}
EOF

docker compose up -d
docker compose logs filebrowser | grep -i 'password\|admin'
```

The first boot generates a random admin password and **prints it to stdout exactly once.** Log in with `admin` + that password, then change it immediately via **Settings → User Management → admin → Password**.

### Single `docker run`

```bash
docker run -d \
  --name filebrowser \
  -v /srv:/srv \
  -v "$(pwd)/filebrowser-data/database.db:/database.db" \
  -v "$(pwd)/filebrowser-data/.filebrowser.json:/.filebrowser.json" \
  -p 8080:80 \
  -u "$(id -u):$(id -g)" \
  filebrowser/filebrowser:latest
```

## Install — Binary (install script)

```bash
# Upstream install script
curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash
# Installs to /usr/local/bin/filebrowser
```

Initialize + run:

```bash
sudo mkdir -p /var/lib/filebrowser
cd /var/lib/filebrowser

# Create the bolt DB
sudo filebrowser -d /var/lib/filebrowser/filebrowser.db config init
sudo filebrowser -d /var/lib/filebrowser/filebrowser.db config set \
  --address 127.0.0.1 \
  --port 8080 \
  --root /srv \
  --log stdout

# Create the initial admin user
sudo filebrowser -d /var/lib/filebrowser/filebrowser.db users add admin 'strong-password' --perm.admin

# Run
sudo filebrowser -d /var/lib/filebrowser/filebrowser.db
```

### systemd unit

```ini
# /etc/systemd/system/filebrowser.service
[Unit]
Description=File Browser
After=network.target

[Service]
Type=simple
User=filebrowser
Group=filebrowser
ExecStart=/usr/local/bin/filebrowser -d /var/lib/filebrowser/filebrowser.db
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
```

```bash
sudo useradd --system --home /var/lib/filebrowser --shell /usr/sbin/nologin filebrowser
sudo chown -R filebrowser:filebrowser /var/lib/filebrowser /srv
sudo systemctl daemon-reload
sudo systemctl enable --now filebrowser
```

## Install — `gtsteffaniak` fork (active alternative)

```yaml
# compose.yaml for the fork
services:
  filebrowser:
    image: gtstef/filebrowser:latest    # the actively-maintained fork
    container_name: filebrowser
    restart: unless-stopped
    ports:
      - "8080:80"
    volumes:
      - /srv:/srv
      - ./fb-config:/config
    user: "1000:1000"
```

See <https://github.com/gtsteffaniak/filebrowser/wiki> for its config schema (not identical to upstream's — sources, permissions, and search config are restructured).

## Reverse proxy (Caddy)

```caddy
files.example.com {
    reverse_proxy filebrowser:80
}
```

## User + permissions model

File Browser's users are NOT host OS users — they're app-level users stored in the bolt DB. Each user has:

- **Scope**: a subdirectory of `root` they can access (e.g. `alice` has scope `/alice/`, sees `/srv/alice/` as her root)
- **Permissions**: view / create / rename / modify / delete / share / execute (commands) / admin
- **Commands**: allowed-list of shell commands they can execute via the "Execute Command" UI

Create users via the admin UI (**Settings → User Management**) OR CLI:

```bash
filebrowser -d filebrowser.db users add alice 'strong-pass' --scope /alice --perm.admin=false --perm.execute=false
```

## Share links

Users (with share permission) can generate public URLs to files/folders with optional password + expiration. Shares are exposed at `/share/<hash>`. Expired shares auto-revoke. Shares bypass authentication by design — treat them like Google Drive "anyone with the link" shares.

## Data layout

| Path | Content |
|---|---|
| `filebrowser.db` (bolt) | Users, settings, shares, rules. Single file. Back this up. |
| `.filebrowser.json` | Config file (optional; CLI flags override). |
| The `root` dir (`/srv` default) | The files users browse. Back up separately. |

**Backup** = stop the process, tar `filebrowser.db` + `.filebrowser.json` + whatever `root` points at. The bolt DB is fine to copy while running but stopping is safer.

## Upgrade procedure

### Docker

```bash
docker compose pull
docker compose up -d
docker compose logs -f filebrowser
```

### Binary

Re-run the install script, or manually download the newer binary from the releases page and replace `/usr/local/bin/filebrowser`.

Upstream schema is stable — File Browser rarely requires migration. Major version jumps document any DB migrations in release notes.

## Gotchas

- **Upstream maintenance-only.** New features unlikely. Bugs may linger. If that's a dealbreaker, use `gtsteffaniak/filebrowser` fork. For bug-free-static-is-fine use cases, upstream is still fine.
- **First-boot admin password.** Older images: `admin`/`admin` default (terrible). Newer images: generates random and logs it. Grep `docker logs filebrowser | head -30` for it. Change immediately.
- **The `user:` in Docker must match host ownership of the mounted dirs.** If `/srv/` is owned by `1000:1000` on the host but the container runs as `0:0`, files uploaded via the UI have mismatched ownership; files already there may be unwritable. Set `user: "1000:1000"` in compose.
- **No auth on the reverse proxy yet = open internet.** Before exposing `filebrowser` publicly, verify authentication is actually on. Misconfigured `noauth` mode is a common footgun. Check settings → Authentication Method = `JSON` (default) or `proxy` (if fronting with Authelia/oauth2-proxy).
- **Share links are unauthenticated by design.** If a user shares `/sensitive.pdf` without a password, anyone with the URL can download. Educate users; consider disabling share permissions globally.
- **"Execute Command" is remote code execution.** Users with `perm.execute=true` can run shell commands on the host. That's the intended feature, but it means adding a user with `--perm.execute=true` is equivalent to giving them shell access. Default: off for non-admins.
- **bolt DB is single-writer.** Fine for dozens of concurrent users. Not a Dropbox replacement for hundreds.
- **File uploads > a few hundred MB need reverse-proxy tuning.** Set `client_max_body_size 100G` in nginx, or the equivalent in Caddy/Traefik. File Browser itself has no hard upload limit.
- **Image/video previews are generated on-demand in memory** — slow on first access for large files, no persistent thumbnail cache.
- **Search is substring-only on filenames (upstream).** No full-text. The fork has better search.
- **No versioning / soft-delete.** When a user deletes a file, it's gone. No recycle bin. Back up `root`.
- **CORS / CSRF.** If you access File Browser's API from a different origin (e.g. a custom frontend), you need to configure CORS. Default is same-origin only.
- **TLS via `--cert` + `--key` flags works** but is fiddly; use a reverse proxy instead for auto-renewal (Caddy / Traefik).

## Links

- Upstream repo: <https://github.com/filebrowser/filebrowser>
- Docs: <https://filebrowser.org>
- Installation docs: <https://filebrowser.org/installation>
- Configuration docs: <https://filebrowser.org/configuration>
- Maintenance-mode announcement: <https://hacdias.com/2026/03/11/filebrowser/>
- Active fork: <https://github.com/gtsteffaniak/filebrowser>
- Releases: <https://github.com/filebrowser/filebrowser/releases>
- Docker Hub: <https://hub.docker.com/r/filebrowser/filebrowser>
