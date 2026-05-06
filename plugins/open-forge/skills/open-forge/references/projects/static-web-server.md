---
name: static-web-server
description: Static Web Server (SWS) recipe for open-forge. Covers Docker and binary install. SWS is a tiny, fast Rust-based static file server with HTTP/2, TLS, compression, Basic Auth, CORS, directory listing, and more.
---

# Static Web Server (SWS)

Cross-platform, high-performance static file web server written in Rust. Built on Hyper + Tokio for async I/O. Ships as a single ~4 MB fully-static binary. Features HTTP/1 and HTTP/2, TLS, GZip/Brotli/Zstd compression, directory listing, CORS, Basic Auth, fallback pages for SPAs, configurable headers, and more. Upstream: <https://github.com/static-web-server/static-web-server>. Docs: <https://static-web-server.net>.

**License:** Apache-2.0 / MIT · **Language:** Rust · **Default port:** 80 (or configurable) · **Stars:** ~2,200

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker | <https://hub.docker.com/r/joseluisq/static-web-server> | ✅ | **Recommended** — multi-arch, easy config via env vars. |
| Binary release | <https://github.com/static-web-server/static-web-server/releases> | ✅ | Bare-metal / VM without Docker. |
| Cargo | `cargo install static-web-server` | ✅ | Rust development environments. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| root_dir | "Directory of static files to serve? (e.g. /var/www/html)" | Free-text | All methods. |
| port | "Port to listen on? (default: 80)" | Free-text | All methods. |
| tls | "Enable TLS? (requires cert/key files)" | AskUserQuestion: Yes / No | Optional. |
| auth | "Enable Basic Auth?" | AskUserQuestion: Yes / No | Optional. |

## Install — Docker

```bash
docker run -d \
  --name sws \
  -p 8080:8080 \
  -v /var/www/html:/public \
  joseluisq/static-web-server:2 \
  -p 8080 -d /public
```

### Docker Compose

```yaml
services:
  sws:
    image: joseluisq/static-web-server:2
    restart: unless-stopped
    ports:
      - "8080:8080"
    volumes:
      - ./public:/public:ro
    command: -p 8080 -d /public
    # Or use a config file:
    # volumes:
    #   - ./config.toml:/etc/sws/config.toml:ro
    #   - ./public:/public:ro
    # command: --config-file /etc/sws/config.toml
```

### With config file (Docker Compose)

Create `config.toml`:

```toml
[general]
host = "0.0.0.0"
port = 8080
root = "/public"
log-level = "info"

# Enable directory listing
directory-listing = true

# Enable compression (gzip, brotli, zstd)
compression = true
compression-level = "default"

# SPA fallback (serve index.html for unmatched paths)
page-fallback = "/public/index.html"

# Custom 404 page
page404 = "/public/404.html"

# CORS
cors-allow-origins = "*"

# Cache-Control
cache-control-headers = true
```

## Install — Binary

```bash
# Download from releases (example: Linux x86_64)
VERSION=v2.42.0
curl -LO https://github.com/static-web-server/static-web-server/releases/download/${VERSION}/static-web-server-${VERSION}-x86_64-unknown-linux-musl.tar.gz
tar xzf static-web-server-*.tar.gz

# Run
./static-web-server -p 8080 -d /var/www/html
```

Install as a systemd service:

```ini
# /etc/systemd/system/sws.service
[Unit]
Description=Static Web Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/static-web-server -p 8080 -d /var/www/html
Restart=unless-stopped
User=www-data

[Install]
WantedBy=multi-user.target
```

```bash
sudo cp static-web-server /usr/local/bin/
sudo systemctl enable --now sws
```

## Configuration options

SWS can be configured via CLI flags, environment variables, or a TOML config file.

| Option | Flag | Env var | Description |
|---|---|---|---|
| Root directory | `-d` | `SERVER_ROOT` | Directory to serve (required) |
| Port | `-p` | `SERVER_PORT` | Listen port (default: 80) |
| Host | `-a` | `SERVER_HOST` | Bind address (default: 0.0.0.0) |
| TLS cert | `--tls-cert` | `SERVER_TLS_CERT` | Path to TLS certificate (PEM) |
| TLS key | `--tls-key` | `SERVER_TLS_KEY` | Path to TLS private key (PEM) |
| HTTP/2 | `--http2` | `SERVER_HTTP2` | Enable HTTP/2 (requires TLS) |
| Compression | `--compression` | `SERVER_COMPRESSION` | Enable gzip/brotli/zstd |
| Directory listing | `--directory-listing` | `SERVER_DIRECTORY_LISTING` | Show directory index |
| Basic Auth | `--basic-auth` | `SERVER_BASIC_AUTH` | `"user:bcrypt-hash"` |
| CORS origins | `--cors-allow-origins` | `SERVER_CORS_ALLOW_ORIGINS` | Allowed origins (`*` or list) |
| 404 page | `--page404` | `SERVER_ERROR_PAGE_404` | Custom 404 page path |
| SPA fallback | `--page-fallback` | `SERVER_PAGE_FALLBACK` | Fallback page for unmatched routes |

## TLS (built-in, no reverse proxy needed)

```toml
[general]
port = 443
root = "/public"
http2 = true

[tls]
cert = "/certs/server.crt"
key = "/certs/server.key"
```

Or with env vars:

```bash
docker run -d \
  -p 443:443 \
  -v ./public:/public:ro \
  -v ./certs:/certs:ro \
  -e SERVER_PORT=443 \
  -e SERVER_HTTP2=true \
  -e SERVER_TLS_CERT=/certs/server.crt \
  -e SERVER_TLS_KEY=/certs/server.key \
  joseluisq/static-web-server:2 -d /public
```

## Software-layer concerns

| Concern | Detail |
|---|---|
| Static binary | The musl-linked binary has zero runtime dependencies — works on any Linux distro. |
| Multi-arch Docker | Images available for linux/amd64, linux/arm64, linux/arm/v7. Works on Raspberry Pi. |
| HTTP/2 + TLS | HTTP/2 requires TLS to be enabled (browser requirement). Use built-in TLS or terminate TLS at a reverse proxy (nginx/Caddy). |
| Compression | Compresses text-based files only (HTML, CSS, JS, JSON, etc.) — binary files are not recompressed. |
| SPA routing | Set `page-fallback = "/public/index.html"` to serve the SPA's index.html for any unmatched path (React/Vue/Angular routing). |
| Basic Auth | Password must be bcrypt-hashed. Generate with: `htpasswd -bnB user password` (requires `apache2-utils`). |
| Rewrites/redirects | Advanced URL rewrites not supported — use nginx/Caddy if complex routing is needed. |

## Upgrade procedure

```bash
# Docker
docker pull joseluisq/static-web-server:2
docker compose up -d

# Binary: download new release, replace binary
sudo systemctl stop sws
sudo cp new-static-web-server /usr/local/bin/static-web-server
sudo systemctl start sws
```

## Gotchas

- **HTTP/2 requires TLS:** Browsers only support HTTP/2 over TLS. If you want HTTP/2, you must provide TLS certs — either to SWS directly or via a TLS-terminating reverse proxy.
- **`:2` tag vs `:latest`:** The Docker Hub image is tagged by major version (`:2`). Using `:2` gives you the latest v2.x releases. Using `:latest` may jump to a breaking major version unexpectedly.
- **Basic Auth bcrypt only:** SWS only accepts bcrypt-hashed passwords for Basic Auth. Plain text passwords are not accepted.
- **No virtual hosting:** SWS serves one root directory per instance. For multiple sites, run multiple SWS containers on different ports behind a reverse proxy.
- **Compression and SPAs:** Compression is on by default but only applies to HTTP responses for text-based MIME types. Binary assets (images, fonts, videos) are served as-is.

## Upstream links

- GitHub: <https://github.com/static-web-server/static-web-server>
- Website / docs: <https://static-web-server.net>
- Docker Hub: <https://hub.docker.com/r/joseluisq/static-web-server>
- Releases: <https://github.com/static-web-server/static-web-server/releases>
- Configuration reference: <https://static-web-server.net/configuration/config-file/>
