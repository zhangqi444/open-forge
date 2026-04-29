---
name: glance-project
description: Glance recipe for open-forge. AGPL-3.0 lightweight Go-based dashboard for displaying feeds and widgets in a single pane — RSS, Reddit, Hacker News, YouTube, Twitch, weather, Docker container status, markets, calendar, custom widgets. Single <20MB binary, YAML-configured, no database. Covers the upstream docker-compose-template (recommended), manual Docker Compose, precompiled binary, and the custom-widgets API (iframe / html / extension / custom-api).
---

# Glance

AGPL-3.0 lightweight self-hosted dashboard. Upstream: <https://github.com/glanceapp/glance>. Docs: <https://github.com/glanceapp/glance/tree/main/docs>.

A single Go binary (<20MB) that serves a customizable YAML-configured dashboard. Widgets include:

- RSS / Atom feeds
- Subreddit posts
- Hacker News, Lobsters
- YouTube channel uploads
- Twitch channels online status
- Weather forecasts (Open-Meteo)
- Market prices (Yahoo Finance)
- Docker container status (reads Docker socket)
- Server stats
- GitHub releases
- Calendar
- Clock / iframe / custom HTML / extension / custom-api (fetch JSON, render with template)

No database, no user accounts, no state beyond the YAML config + a file-based cache. Pages load in ~1s uncached.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose + `docker-compose-template` | <https://github.com/glanceapp/docker-compose-template> | ✅ Recommended | Upstream-curated template with sensible defaults, `config/home.yml`, `.env`, `assets/` for custom CSS. |
| Manual Docker Compose | Minimal inline compose | ✅ | Quick start if you don't want the template structure. |
| Precompiled binary | <https://github.com/glanceapp/glance/releases/latest> | ✅ | systemd on bare metal. Linux/Windows/macOS, x86/amd64/arm/arm64. |
| Build from source (Go) | `go build -o glance .` | ✅ | Requires Go 1.23+. Contributors or customization. |
| Build Docker image from source | `docker build -t owner/glance .` | ✅ | Custom forks. |
| Proxmox VE Helper Script | <https://community-scripts.github.io/ProxmoxVE/scripts?id=glance> | ⚠️ 3rd party | Quick LXC provisioning on Proxmox. |
| NixOS package | `pkgs.glance` (unstable) | ⚠️ 3rd party | NixOS deploys. |
| Coolify | <https://coolify.io/docs/services/glance/> | ⚠️ 3rd party | If you're on Coolify. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion`: `compose-template` / `compose-manual` / `binary` / `source` | Drives section. |
| ports | "Host port?" | Free-text, default `8080` | Glance listens on `:8080` internally. |
| config | "Dashboard layout preference?" | `AskUserQuestion`: `start-with-template` / `start-blank` | Template has sensible defaults (RSS, weather, markets); blank lets you build from scratch. |
| dns | "Public domain?" | Free-text | For reverse proxy. |
| tls | "Reverse proxy? (Caddy / nginx / Traefik / skip)" | `AskUserQuestion` | Glance does not terminate TLS. LAN-only + skip is fine. |
| widgets | "Widgets to enable?" | Multi-select from [Glance's widget list](https://github.com/glanceapp/glance/blob/main/docs/configuration.md#configuring-glance) | Each widget = YAML block in `glance.yml`. |
| integrations | "Docker container status widget?" | Boolean | If yes, mount `/var/run/docker.sock:ro` into the container. Grants read access to ALL container metadata. |
| cache | "Widget cache dir?" | Default (`/tmp/glance` inside container) | Some widgets cache results; persist if you want cache survival across restarts. |

## Install — Docker Compose with upstream template (recommended)

```bash
# 1. Create directory + download template
mkdir glance && cd glance && curl -sL https://github.com/glanceapp/docker-compose-template/archive/refs/heads/main.tar.gz | tar -xzf - --strip-components 2

# 2. Review the generated files
ls -la
# docker-compose.yml
# config/home.yml        — the page definition
# config/glance.yml      — global settings (theme, pages, includes)
# .env
# assets/user.css        — custom CSS

# 3. Edit config/home.yml to pick widgets
# 4. Bring up
docker compose up -d
docker compose logs glance
```

Visit `http://<host>:8080/`.

## Install — Manual Docker Compose

```yaml
# compose.yaml
services:
  glance:
    container_name: glance
    image: glanceapp/glance:latest     # pin a specific tag in prod
    restart: unless-stopped
    volumes:
      - ./config:/app/config
      # Optional: Docker container status widget needs socket access
      # - /var/run/docker.sock:/var/run/docker.sock:ro
    ports:
      - "8080:8080"
```

```bash
mkdir -p config
wget -O config/glance.yml https://raw.githubusercontent.com/glanceapp/glance/refs/heads/main/docs/glance.yml
docker compose up -d
```

## Install — Precompiled binary + systemd

```bash
# 1. Download the right binary for your arch
VERSION=$(curl -s https://api.github.com/repos/glanceapp/glance/releases/latest | grep tag_name | cut -d'"' -f4 | sed 's/^v//')
curl -LO "https://github.com/glanceapp/glance/releases/download/v${VERSION}/glance-linux-amd64.tar.gz"
sudo mkdir -p /opt/glance
sudo tar -xzf "glance-linux-amd64.tar.gz" -C /opt/glance
sudo chmod +x /opt/glance/glance

# 2. Starter config
sudo wget -O /etc/glance.yml https://raw.githubusercontent.com/glanceapp/glance/refs/heads/main/docs/glance.yml

# 3. systemd unit
sudo tee /etc/systemd/system/glance.service > /dev/null <<'EOF'
[Unit]
Description=Glance dashboard
After=network-online.target

[Service]
Type=simple
User=glance
Group=glance
WorkingDirectory=/opt/glance
ExecStart=/opt/glance/glance --config /etc/glance.yml
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

sudo useradd --system --no-create-home --shell /usr/sbin/nologin glance
sudo chown -R glance:glance /opt/glance
sudo systemctl daemon-reload
sudo systemctl enable --now glance
```

## Configuration

`glance.yml` (or `config/glance.yml` in Docker) is the entry point. Structure:

```yaml
# config/glance.yml
theme:
  background-color: 225 14 15
  primary-color: 50 98 73

pages:
  - name: Home
    columns:
      - size: small
        widgets:
          - type: calendar
          - type: weather
            location: London, United Kingdom

      - size: full
        widgets:
          - type: rss
            feeds:
              - url: https://selfh.st/rss/
              - url: https://news.ycombinator.com/rss
          - type: hacker-news

      - size: small
        widgets:
          - type: markets
            markets:
              - symbol: SPY
              - symbol: BTC-USD

  - name: Dev
    columns:
      - size: full
        widgets:
          - type: releases
            repositories:
              - glanceapp/glance
              - go-gitea/gitea

  - name: Docker
    columns:
      - size: full
        widgets:
          - type: docker-containers   # needs /var/run/docker.sock mount
```

Full config reference: <https://github.com/glanceapp/glance/blob/main/docs/configuration.md>.

### Pages / columns / widgets

- Top-level `pages` is a list; each page is a tab.
- Each page has `columns` (up to 3, typically: `small`, `full`, `small`).
- Each column has `widgets` stacked vertically.

### Themes

- Built-in + community themes: <https://github.com/glanceapp/glance/blob/main/docs/themes.md>
- Custom CSS: drop `assets/user.css` and reference via `custom-css-file` in `glance.yml`.

### Custom widgets (no-code extensibility)

Four built-in ways to add content not provided by the stock widgets:

| Widget type | What it does |
|---|---|
| `iframe` | Embed any URL in an iframe (respects its X-Frame-Options). |
| `html` | Render static HTML block. |
| `extension` | Fetch HTML from a URL + render inline. For home-grown microservices. |
| `custom-api` | Fetch JSON from a URL, render with a Go text/template. Most powerful. |

Community widgets (pre-built custom-api templates): <https://github.com/glanceapp/community-widgets>.

## Reverse proxy (Caddy)

```caddy
dash.example.com {
    reverse_proxy glance:8080
}
```

## Data layout

Glance is almost stateless. What exists:

| Path | Content |
|---|---|
| `config/glance.yml` | Main config |
| `config/*.yml` | Included pages (if `pages` uses `!include`) |
| `assets/user.css` | Optional custom CSS |
| `.env` | Environment variables (referenced in YAML via `${VAR}`) |
| In-memory cache | Widget fetch results. Lost on restart. |

**Backup** = the `config/` dir. That's the entire state.

## Upgrade procedure

### Docker

```bash
docker compose pull
docker compose up -d
docker compose logs glance
```

Glance is actively developed; upstream ships regular releases. Read release notes before upgrading:

- Check <https://github.com/glanceapp/glance/releases> for config-schema changes.
- Upstream's contributing guidelines say "avoid backwards-incompatible configuration changes," so config stays stable in practice.

### Binary

```bash
sudo systemctl stop glance
# Re-download the new binary, overwrite /opt/glance/glance
sudo systemctl start glance
```

## Gotchas

- **Widget timeouts with Pi-hole / AdGuard Home.** Per upstream README: many widgets make outbound DNS requests on page load; DNS ad-blockers with aggressive rate limits can time out Glance's widgets. Fix: increase rate limit in your DNS ad-blocker for the Glance host's IP.
- **Broken layout = Dark Reader extension.** If markets / bookmarks / some widgets look broken, disable Dark Reader for the Glance domain. (Upstream README flags this explicitly.)
- **`cannot unmarshal !!map into []glance.page`** means you have nested `pages:` — the top-level glance.yml has `pages:`, and so does one of your included page files. Remove the inner one.
- **No built-in auth.** Anyone who can reach the port sees your dashboard. Put it on LAN / VPN, OR behind a reverse proxy with auth (Authelia / oauth2-proxy / basic auth).
- **`docker-containers` widget requires Docker socket mount.** Mounting `/var/run/docker.sock` into a container effectively gives that container root on the host (can create new containers with `--privileged`). Only expose Glance to trusted networks when this widget is active, OR use a Docker socket proxy like `tecnativa/docker-socket-proxy` to whitelist specific API calls.
- **Widget cache is in-memory.** First page load after a restart re-fetches everything. For expensive widgets (market data at rate-limited providers), this can hit API quotas.
- **`rss` widget trusts the feed.** Malicious HTML in RSS descriptions could contain scripts. Glance sanitizes via a Go HTML sanitizer, but zero-day XSS via a compromised feed is possible. Don't subscribe to feeds you don't trust.
- **Pin an image version in production.** `glanceapp/glance:latest` ships new minor versions regularly; most are non-breaking, but auto-pull (Watchtower) can surprise you.
- **Podman compatibility quirk.** If running on Podman and requests time out, add the `networks: podman: external: true` stanza shown in upstream README.
- **No dynamic refresh.** Pages don't auto-update widget data — you refresh the page. Clock + "time ago" relative timestamps are the only live-updating elements.
- **`iframe` widget limited by target site's `X-Frame-Options`.** Many sites (GitHub, Twitter, Google) refuse to be iframed. Not Glance's fault.
- **`custom-api` templates are Go `text/template` syntax.** Non-trivial to write. Copy-paste from `community-widgets` and adapt is the easy mode.
- **Configuration is single-file YAML by default.** For huge dashboards, split pages into separate files and `!include` them; see docs for the syntax.

## Links

- Upstream repo: <https://github.com/glanceapp/glance>
- docker-compose-template: <https://github.com/glanceapp/docker-compose-template>
- Community widgets: <https://github.com/glanceapp/community-widgets>
- Preconfigured pages: <https://github.com/glanceapp/glance/blob/main/docs/preconfigured-pages.md>
- Configuration reference: <https://github.com/glanceapp/glance/blob/main/docs/configuration.md>
- Themes: <https://github.com/glanceapp/glance/blob/main/docs/themes.md>
- Releases: <https://github.com/glanceapp/glance/releases>
- Docker image: <https://hub.docker.com/r/glanceapp/glance>
- Discord: <https://discord.com/invite/7KQ7Xa9kJd>
