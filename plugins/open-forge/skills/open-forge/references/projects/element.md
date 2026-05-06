---
name: element
description: Element Web recipe for open-forge. Covers Docker (official vectorim/element-web image), Debian/Ubuntu package via Element's apt repository, and release tarball served behind a web server. Upstream install docs at https://github.com/element-hq/element-web/blob/master/docs/install.md.
---

# Element

Element (formerly Vector/Riot) is a Matrix web client built on the Matrix JS SDK. It provides a browser-based interface to any Matrix homeserver for encrypted messaging, voice/video calls, and spaces. Upstream: <https://github.com/element-hq/element-web>. Install guide: <https://github.com/element-hq/element-web/blob/master/docs/install.md>.

License: AGPL-3.0 or GPL-3.0 (multi-licensed; commercial licence also available from Element). For self-hosting the web client, AGPL-3.0 applies.

Element Web is a **static frontend**. It does not include a Matrix homeserver — you need a separate homeserver (e.g. Synapse, Conduit, Dendrite) or point it at an existing one (e.g. `matrix.org`). The web client is served as static files behind any HTTPS-capable web server or via the official Docker image (Nginx-based).

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker (`vectorim/element-web`) | <https://github.com/element-hq/element-web/blob/master/docs/install.md#docker> | ✅ | Recommended for self-hosted deployments; official image ships Nginx |
| Debian/Ubuntu apt package | <https://github.com/element-hq/element-web/blob/master/docs/install.md#debian-package> | ✅ | Native package management on Debian/Ubuntu; installs to `/usr/share/element-web` |
| Release tarball | <https://github.com/element-hq/element-web/blob/master/docs/install.md#release-tarball> | ✅ | Any Linux/BSD web server; untar and serve as static files |
| Build from source | <https://github.com/element-hq/element-web/blob/master/docs/monorepo.md> | ✅ | Contributors / custom theme/module development |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "Which install method — Docker, Debian package, or tarball?" | Choice | Drives which section below |
| config | "What is the Matrix homeserver URL for the default server?" | Free-text | e.g. `https://matrix.example.com` — required in `config.json` |
| config | "What domain will Element Web be served on?" | Free-text | e.g. `element.example.com` — used for TLS config and `config.json` `default_server_config` |
| tls | "Email for Let's Encrypt?" | Free-text | For the reverse proxy TLS cert |
| optional | "Custom display name for the server in Element's login screen?" | Free-text | Sets `default_server_config.m.homeserver.server_name` |

## Docker Compose

No upstream `docker-compose.yml` is provided in the element-web repo. The following is derived from the upstream Docker run instructions at <https://github.com/element-hq/element-web/blob/master/docs/install.md#docker>:

```yaml
# docker-compose.yml for element-web
# Serves Element Web on port 80 inside the container via Nginx.
# Put a reverse proxy (Nginx, Caddy, Traefik) in front for HTTPS.
services:
  element-web:
    image: vectorim/element-web:latest
    restart: unless-stopped
    ports:
      - "127.0.0.1:8080:80"
    volumes:
      # Mount your customised config.json over the default
      - ./config.json:/app/config.json:ro
    environment:
      # Override the internal Nginx port if needed (default 80)
      - ELEMENT_WEB_PORT=80
```

Start with:
```bash
docker compose up -d
```

Then put Nginx/Caddy in front on port 443.

### Minimal `config.json`

Copy `config.sample.json` from the release tarball (or from the Docker image) and at minimum set:

```json
{
  "default_server_config": {
    "m.homeserver": {
      "base_url": "https://matrix.example.com",
      "server_name": "example.com"
    },
    "m.identity_server": {
      "base_url": "https://vector.im"
    }
  },
  "brand": "Element"
}
```

Full configuration reference: <https://github.com/element-hq/element-web/blob/master/docs/config.md>

## Method — Debian/Ubuntu package

> **Source:** <https://github.com/element-hq/element-web/blob/master/docs/install.md#debian-package>

```bash
sudo apt install -y wget apt-transport-https
sudo wget -O /usr/share/keyrings/element-io-archive-keyring.gpg \
  https://packages.element.io/debian/element-io-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/element-io-archive-keyring.gpg] \
  https://packages.element.io/debian/ default main" \
  | sudo tee /etc/apt/sources.list.d/element-io.list
sudo apt update
sudo apt install element-web
```

Files land at:
- Webroot: `/usr/share/element-web/`
- Config: `/etc/element-web/config.json`

Point your web server at `/usr/share/element-web`. Serve over HTTPS.

## Method — Release tarball

> **Source:** <https://github.com/element-hq/element-web/blob/master/docs/install.md#release-tarball>

1. Download the latest `element-vX.Y.Z.tar.gz` from <https://github.com/element-hq/element-web/releases>
2. Verify GPG signature against <https://packages.element.io/element-release-key.asc>
3. Untar to your web server document root
4. Copy `config.sample.json` → `config.json` and edit
5. Configure your web server with correct caching headers (see Caching section below)

## Software-layer concerns

### Config paths

| Method | Config path |
|---|---|
| Docker | Bind-mounted `./config.json` → `/app/config.json` |
| Debian package | `/etc/element-web/config.json` |
| Tarball | `<webroot>/config.json` |

### Caching requirements

Element requires aggressive caching for static assets but **must not** cache `index.html` or `config.json`. Upstream recommends:

```nginx
# Nginx example
location / {
    try_files $uri $uri/ /index.html;
}
# Never cache index.html or config.json
location ~* (index\.html|config\.json)$ {
    add_header Cache-Control "no-cache, no-store";
}
# Cache static assets with content-addressed filenames
location ~* \.(js|css|png|jpg|woff2)$ {
    add_header Cache-Control "public, max-age=31536000, immutable";
}
```

See: <https://github.com/element-hq/element-web/blob/master/apps/web/README.md#caching-requirements>

### Security: important note on hosting

Element Web should be served from its **own origin** (domain or subdomain). Sharing an origin with other applications is a security risk — XSS in any co-hosted app could access user tokens. See: <https://github.com/element-hq/element-web/blob/master/apps/web/README.md#important-security-notes>

## Upgrade procedure

### Docker
```bash
docker compose pull
docker compose up -d
```

### Debian package
```bash
sudo apt update && sudo apt upgrade element-web
```

### Tarball
1. Download the new tarball from GitHub releases
2. Verify GPG signature
3. Untar alongside the existing version
4. Update the symlink or directory name
5. Copy `config.json` from the old version to the new one

## Gotchas

- **Element Web is a frontend only — you still need a Matrix homeserver.** Element does not include Synapse or any other homeserver. Point `config.json` at an existing homeserver.
- **Must be served over HTTPS** — browsers block WebRTC (voice/video) on plain HTTP. Exception: `localhost` is allowed.
- **Dedicated origin required** — do not share a domain/subdomain with other apps. XSS risk.
- **`index.html` and `config.json` must never be cached** — aggressive caching of these files causes users to run stale code after upgrades.
- **Docker port binding** — the official image runs Nginx internally on port 80 as a non-root user. If binding to port 80 on the host causes issues, set `ELEMENT_WEB_PORT` or bind to a higher port and use a reverse proxy.
- **Mobile clients** — Element Web is not recommended for mobile browsers in production. Use Element X (iOS/Android) instead.
- **Custom modules** — Element Web Modules can be injected via `/modules/` bind-mount in Docker; see upstream docs for the module API.

## Upstream docs

- Install guide: <https://github.com/element-hq/element-web/blob/master/docs/install.md>
- Configuration reference: <https://github.com/element-hq/element-web/blob/master/docs/config.md>
- Security notes: <https://github.com/element-hq/element-web/blob/master/apps/web/README.md#important-security-notes>
- Docker Hub: <https://hub.docker.com/r/vectorim/element-web>
- Releases: <https://github.com/element-hq/element-web/releases>
