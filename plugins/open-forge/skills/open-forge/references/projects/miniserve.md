---
name: miniserve
description: "Tiny Rust-based CLI HTTP server for quickly sharing files + directories. Drop-in replacement for 'python -m http.server' but cross-platform, single binary, WAY more features: auth, uploads, TLS, QR code, index file, SPA mode. MIT."
---

# miniserve

**"For when you really just want to serve some files over HTTP right now!"**

miniserve is a **single-binary cross-platform CLI HTTP file server** — the grown-up, featureful replacement for `python -m http.server` / `python3 -m http.server`. Drop the binary on any machine, point it at a directory, instant HTTP file browser. Does uploads, basic auth, TLS, index files, QR codes for your phone, and supports SPA routing — all from flags on the command line. No config file, no daemon, no dependencies beyond the binary itself.

Killer use cases:

- Quickly share a file with someone on the same network
- Transfer files between phone and laptop via QR code
- Host a static site for a demo
- Serve a directory of installers/ISOs on a LAN
- Share a folder with a coworker via ngrok / Tailscale
- Serve a React/Vue/Svelte SPA dev build

Features:

- **Single binary** — no runtime, no deps; download + run
- **Cross-platform** — Linux/macOS/Windows/BSD
- **Directory listing** with dark mode, sort by name/size/date
- **Upload mode** (`-u`) — drag-drop files into browser
- **Basic auth** (`--auth user:pass` or hashed) + multiple users
- **TLS** (`--tls-cert` + `--tls-key`)
- **Index file** (`--index`) — serve HTML instead of listing
- **SPA mode** (`--spa`) — fallback to index.html for unknown routes
- **Pretty-printed directory listing** with breadcrumbs, nice filenames
- **On-the-fly ZIP/tar.gz** download of subtrees
- **QR code** — printed to terminal; scan with phone
- **Color themes** + dark mode
- **Readme rendering** — auto-renders `README.md` in listings
- **Random route** — obscure URL prefix for security-by-obscurity

- Upstream repo: <https://github.com/svenstaro/miniserve>
- Crates.io: <https://crates.io/crates/miniserve>
- Docker Hub: <https://hub.docker.com/r/svenstaro/miniserve>
- Releases: <https://github.com/svenstaro/miniserve/releases>

## Architecture in one minute

- **Rust**; single self-contained binary (~5-10 MB)
- **Actix-web** framework under the hood
- **Zero persistent state**
- **Runs as the invoking user**, in the foreground by default (daemonize with nohup / systemd if needed)

## Compatible install methods

| Infra       | Runtime                                          | Notes                                                           |
| ----------- | ------------------------------------------------ | --------------------------------------------------------------- |
| Any         | **Prebuilt binary from GitHub Releases**            | **Just download + run**                                             |
| Any         | `cargo install miniserve`                                | From Crates.io                                                          |
| Linux       | `apt install miniserve` (via repo / backports / PPAs)          | Debian/Ubuntu                                                           |
| macOS       | `brew install miniserve`                                              | Homebrew                                                                         |
| Docker      | `svenstaro/miniserve`                                                         | If you want containerized                                                                       |
| Windows     | `scoop install miniserve` / `winget install miniserve`                                 | Or .exe from Releases                                                                                   |
| Arch/NixOS  | Official packages                                                                             | Yes                                                                                                             |

## Inputs to collect

| Input           | Example                      | Phase     | Notes                                                       |
| --------------- | ---------------------------- | --------- | ----------------------------------------------------------- |
| Directory       | `/srv/files`                    | Path      | What to serve                                                     |
| Port            | `8080` (default)                   | Network   | Change with `-p`                                                         |
| Bind address    | `0.0.0.0` (default) / `127.0.0.1`      | Network   | Loopback for laptop-only; all for LAN                                        |
| Auth            | `user:password`                            | Security  | Or hashed; see below                                                                         |
| TLS cert/key    | paths to `.pem`                                  | Security  | For `https://`                                                                                          |
| Index file      | `index.html`                                         | Static    | Serve file instead of listing                                                                                  |
| Upload dir      | enabled with `-u`                                          | Write     | Careful — allows anyone at URL to upload                                                                                   |

## Quick recipes

```sh
# Serve current dir on http://0.0.0.0:8080
miniserve .

# Serve on specific port, show QR code
miniserve -p 3000 -q /srv/files

# Require basic auth
miniserve --auth alice:hunter2 /srv/files

# Hash the password (safer if sharing the command)
pw=$(echo -n "hunter2" | sha256sum | cut -f 1 -d ' ')
miniserve --auth alice:sha256:$pw /srv/files

# Allow uploads
miniserve -u /srv/incoming

# HTTPS
miniserve --tls-cert fullchain.pem --tls-key privkey.pem /srv/files

# Serve single page app
miniserve --spa --index index.html /srv/myapp/dist

# Random obscure path (security-by-obscurity)
miniserve --random-route /srv/files
# Prints: http://0.0.0.0:8080/abc123xyz/

# Multiple users
miniserve --auth alice:pw1 --auth bob:pw2 /srv/files

# Disable history navigation (directory listings only for given root)
miniserve --no-history /srv/files

# Color scheme
miniserve --color-scheme=monokai /srv/files
```

## Docker

```sh
docker run -d --name miniserve \
  -p 8080:8080 \
  -v /srv/files:/srv \
  svenstaro/miniserve:latest \
  /srv -a 0.0.0.0 --spa
```

## Run as a systemd service

```ini
# /etc/systemd/system/miniserve.service
[Unit]
Description=miniserve
After=network.target

[Service]
ExecStart=/usr/local/bin/miniserve -p 8080 --auth alice:sha256:HASH /srv/files
Restart=on-failure
User=fileserver

[Install]
WantedBy=multi-user.target
```

```sh
sudo systemctl enable --now miniserve
```

## First boot

Literally: `miniserve .` → browse the URL it prints. That's it.

For QR code printing + WiFi sharing: `miniserve -q .` → scan the QR with your phone.

## Data & config layout

There isn't any. `miniserve` holds no state; it's a serve-and-exit tool (or long-running daemon if you daemonize).

## Backup

N/A. Your content is your responsibility — miniserve never modifies served files (unless `-u` is enabled, in which case uploads land in the served dir).

## Upgrade

1. Releases: <https://github.com/svenstaro/miniserve/releases>.
2. Download the new binary, replace the old, restart the service (if running as one).
3. Breaking flag changes are rare but called out in release notes.

## Gotchas

- **Binding to 0.0.0.0 exposes to your LAN.** Use `-i 127.0.0.1` if you want loopback-only (great for Docker containers where another service proxies the traffic).
- **`-u` (upload enabled) = anyone who can reach the URL can write files.** Pair with `--auth` always. Don't expose `-u` to the public internet without a reverse-proxy auth in front.
- **Path traversal**: miniserve sanitizes `../` etc., but don't symlink secrets into a served directory. Serve only what you're willing to share.
- **HTTPS isn't automatic** — `--tls-cert` / `--tls-key` require you to have certs. For public-facing long-term deployments, reverse-proxy with Caddy/Traefik (which do Let's Encrypt automatically). miniserve's built-in TLS is for ad-hoc use.
- **Basic auth over HTTP is plaintext** — always pair `--auth` with TLS OR SSH tunnel / Tailscale / VPN.
- **Upload size limits** — miniserve has no built-in limit; limited by disk space + HTTP client behavior. Check your reverse proxy's `client_max_body_size` if fronting.
- **Large directories**: listing 10k+ files in a directory takes time; browser struggles to render. Not optimized for gigantic folders.
- **No directory watches**: changes to files while miniserve is running are reflected on next request; no SSE/websocket live reload.
- **No authentication beyond HTTP Basic.** For OIDC/LDAP/session auth, front with Authelia/Authentik/Traefik-forward-auth.
- **No access logs by default** — add `--verbose` for simple stdout logs. For structured logs + rotation, pipe into journald or a logger.
- **SPA mode caveat**: `--spa` serves `index.html` for anything that doesn't exist; make sure `index.html` is at the root of the served dir.
- **Symlinks**: miniserve follows symlinks by default. If you symlink outside the served tree, users can browse there. Use `--no-symlinks` to disable.
- **IPv6**: supported; use `-i ::` or specific `[::1]`.
- **Windows**: works; terminal color rendering depends on WT / CMD.exe quirks.
- **CPU usage**: Rust + Actix = basically free; runs fine on Pi Zero.
- **License**: MIT.
- **Not a production web server** — for production static sites use nginx, Caddy, or a CDN. miniserve is for ad-hoc / dev / homelab sharing.
- **Alternatives worth knowing:**
  - **`python -m http.server`** — builtin; no features; slow; prints "GET / 200" logs
  - **`npx serve`** / **`npx http-server`** — if you already have Node
  - **`darkhttpd`** — C; single-binary; similar niche
  - **`caddy file-server`** — Caddy's built-in file server; better auth + cert automation
  - **`busybox httpd`** — embedded Linux
  - **Nextcloud Files / Seafile / Filestash** — real file-share platforms (separate recipes)
  - **FileBrowser** — richer web UI; user management; editing (separate recipe)
  - **Dufs** — modern Rust alternative with more features
  - **`gossa`** — Go-based file browser
  - **Choose miniserve if:** you want dead-simple, fast, single-binary HTTP file serving with nice extras.
  - **Choose Caddy if:** you want auto-HTTPS + production config.
  - **Choose FileBrowser if:** you want an actual multi-user web file browser with editing + user management.

## Links

- Repo: <https://github.com/svenstaro/miniserve>
- Releases: <https://github.com/svenstaro/miniserve/releases>
- Docker Hub: <https://hub.docker.com/r/svenstaro/miniserve>
- Crates.io: <https://crates.io/crates/miniserve>
- Homebrew formula: <https://formulae.brew.sh/formula/miniserve>
- CLI reference: `miniserve --help`
- Pattern comparison (vs dufs/gossa): community benchmarks
- Dufs alternative: <https://github.com/sigoden/dufs>
- FileBrowser alternative: <https://github.com/filebrowser/filebrowser>
