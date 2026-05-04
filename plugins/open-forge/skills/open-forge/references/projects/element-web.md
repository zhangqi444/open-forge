# Element Web

Web-based Matrix client. Element is the flagship client for the Matrix open-standard protocol — a decentralised, end-to-end encrypted messaging and collaboration platform. Self-hosting Element Web means serving the static SPA; it connects to your Matrix homeserver (typically Synapse or Conduit) for all messaging, rooms, and data. Upstream: <https://github.com/element-hq/element-web>. Docs: <https://element.io/get-started>.

> **Important:** Element Web is a **frontend client** — it does not store messages itself. It requires a separate **Matrix homeserver** (Synapse, Conduwuit, Dendrite, etc.) to function. Self-hosting Element Web is separate from self-hosting your Matrix homeserver. See `synapse.md` for the homeserver recipe.

Element Web is a static web app served on port `80` (or `443` with TLS). It has no backend process of its own.

## Compatible install methods

Verified against upstream docs at <https://github.com/element-hq/element-web#getting-started>.

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker (vectorim/element-web) | <https://hub.docker.com/r/vectorim/element-web> | ✅ | Easiest self-hosted deploy. Static files served via nginx. |
| Static build (nginx/Caddy) | <https://github.com/element-hq/element-web/releases> | ✅ | Download release archive, serve with any web server. |
| Build from source | <https://github.com/element-hq/element-web#building> | ✅ | When you need customization or the latest code. |
| Element Cloud (hosted) | <https://app.element.io> | ✅ | No self-hosting needed — use the official hosted instance. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| homeserver | "Default Matrix homeserver URL?" | Free-text (e.g. `https://matrix.example.com`) | All |
| branding | "Custom app name?" | Free-text (defaults to `Element`) | Optional |
| port | "Port to serve Element Web on?" | Number (default 80) | Docker |

## Software-layer concerns

### Configuration (`config.json`)

Element Web reads its config from a `config.json` file. The most important setting is the default homeserver:

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
  "brand": "Element",
  "integrations_ui_url": "https://scalar.vector.im/",
  "integrations_rest_url": "https://scalar.vector.im/api",
  "bug_report_endpoint_url": "https://element.io/bugreports/submit",
  "showLabsSettings": false,
  "features": {},
  "default_theme": "light"
}
```

Minimal config pointing at your homeserver:
```json
{
  "default_server_config": {
    "m.homeserver": {
      "base_url": "https://matrix.example.com",
      "server_name": "example.com"
    }
  }
}
```

### Docker Compose

```yaml
services:
  element-web:
    image: vectorim/element-web:latest
    ports:
      - "80:80"
    volumes:
      - ./config.json:/app/config.json:ro
    restart: unless-stopped
```

Place your `config.json` in the same directory as `docker-compose.yml`. The container serves it via nginx.

### Static build (nginx)

```bash
# Download latest release
wget https://github.com/element-hq/element-web/releases/latest/download/element-web-v<VERSION>.tar.gz
tar xzf element-web-v<VERSION>.tar.gz
cd element-web-v<VERSION>

# Copy and edit config
cp config.sample.json config.json
# Edit config.json to set your homeserver

# Serve with nginx (point root to this directory)
```

nginx config:
```nginx
server {
    listen 80;
    server_name element.example.com;
    root /var/www/element-web;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
```

### Data directories

Element Web is stateless — no data to persist on disk. All messages and room data are stored on the Matrix homeserver.

| Path | Contents |
|---|---|
| `config.json` (mounted) | Element Web configuration |
| Browser LocalStorage | Per-user session, keys, read receipts (client-side only) |

## Upgrade procedure

Docker:
1. `docker compose pull`
2. `docker compose up -d`

Static: download the new release archive and replace the files. Your `config.json` is outside the app dir, so it's unaffected.

## Gotchas

- **You need a Matrix homeserver.** Element Web without a homeserver is useless. Deploy Synapse or another homeserver first (see `synapse.md`).
- **E2E encryption keys are per-device.** Users should export their encryption key backup to a recovery key, or set up cross-signing, to avoid losing messages when switching devices or clearing browser data.
- **HTTPS is required for WebRTC (calls) and some browser APIs.** Serve Element Web over HTTPS in production.
- **Wellknown discovery.** For automatic server discovery, the Matrix homeserver must serve `/.well-known/matrix/client` at the server name domain. Without this, users must manually enter the homeserver URL.
- **Content Security Policy (CSP) headers.** If you're adding a reverse proxy, ensure CSP headers don't block Element's inline scripts. Review nginx/Caddy CSP config.
- **Branching vs. element-desktop.** Element Web is the browser app. Element Desktop (Electron) wraps Element Web for native use. This recipe covers the web version.

## Links

- Upstream: <https://github.com/element-hq/element-web>
- Docker Hub: <https://hub.docker.com/r/vectorim/element-web>
- Releases: <https://github.com/element-hq/element-web/releases>
- Config options: <https://github.com/element-hq/element-web/blob/develop/docs/config.md>
- Matrix homeserver (Synapse): see `synapse.md`
- Matrix spec: <https://spec.matrix.org>
