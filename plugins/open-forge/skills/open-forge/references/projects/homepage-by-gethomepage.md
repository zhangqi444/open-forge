---
name: homepage-by-gethomepage
description: Homepage (by gethomepage) recipe for open-forge. Covers Docker Compose (recommended), Docker with labels for auto-discovery, and source/npm builds. Highly customizable application dashboard with 100+ service integrations. Based on upstream docs at https://gethomepage.dev/ and the gethomepage/homepage repo.
---

# Homepage by gethomepage

Highly customizable application dashboard (startpage) with Docker integration, service API widgets, weather, search, and over 100 service integrations. Configured via YAML files or Docker label auto-discovery. Upstream: <https://github.com/gethomepage/homepage>. Docs: <https://gethomepage.dev/>.

Homepage is a statically generated Next.js app that proxies API requests to backend services server-side, keeping API keys hidden from the browser. Supports AMD64 and ARM64.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | https://gethomepage.dev/installation/docker/ | Yes | Recommended. YAML config via mounted volume. |
| Docker with label discovery | https://gethomepage.dev/configs/docker/#automatic-service-discovery | Yes | Auto-discovers services from Docker labels — minimal manual config. |
| npm / source | https://gethomepage.dev/installation/source/ | Yes | When Docker is unavailable or for development. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | Which install method? | Choose from table above | Drives which section loads |
| data | Where should Homepage store its config files? (host path, e.g. /opt/homepage/config) | Free-text path | Docker installs |
| network | Which host port? (default: 3000) | Integer | Docker install |
| hostname | Hostname or IP where Homepage will be accessed (for HOMEPAGE_ALLOWED_HOSTS) | Free-text | Docker install |
| docker_socket | Mount Docker socket for container status/auto-discovery? | Yes/No | Docker install |

## Software-layer concerns

| Concern | Detail |
|---|---|
| Config directory | /app/config inside container. Mount a host path here. Contains services.yaml, widgets.yaml, bookmarks.yaml, settings.yaml, docker.yaml, kubernetes.yaml. |
| Default port | 3000 |
| Required env var | HOMEPAGE_ALLOWED_HOSTS: must be set to the hostname/IP:port where Homepage is accessed. Prevents unauthorized embedding. |
| Docker socket | Mount /var/run/docker.sock read-only for container status widgets and label-based auto-discovery. Security note: grants Homepage read access to Docker API. |
| API proxying | All service API calls (Sonarr, Radarr, Plex, etc.) are proxied server-side. API keys are in YAML config files, never sent to the browser. |
| Static generation | Pages are pre-built at startup. Config file changes require container restart to take effect (or use hot reload if running from source). |
| Image registry | ghcr.io/gethomepage/homepage (GitHub Container Registry) |

## Method — Docker Compose (recommended)

Source: https://gethomepage.dev/installation/docker/

    services:
      homepage:
        image: ghcr.io/gethomepage/homepage:latest
        container_name: homepage
        ports:
          - 3000:3000
        volumes:
          - /path/to/config:/app/config
          - /var/run/docker.sock:/var/run/docker.sock:ro  # optional, for Docker integrations
        environment:
          HOMEPAGE_ALLOWED_HOSTS: gethomepage.dev  # replace with your hostname/IP

Replace /path/to/config with your chosen config directory and HOMEPAGE_ALLOWED_HOSTS with your actual hostname or IP (with port if non-standard, e.g. homeserver.local:3000).

Start:

    mkdir -p /opt/homepage/config
    docker compose up -d

On first run, Homepage auto-generates default config files in the config directory. Edit them to add your services.

### Running as non-root

    services:
      homepage:
        image: ghcr.io/gethomepage/homepage:latest
        ports:
          - 3000:3000
        volumes:
          - /path/to/config:/app/config
          - /var/run/docker.sock:/var/run/docker.sock:ro
        environment:
          HOMEPAGE_ALLOWED_HOSTS: yourhost
          PUID: 1000   # or $PUID from .env
          PGID: 1000   # or $PGID from .env

Ensure the config directory is owned by the PUID/PGID user.

## Method — Docker label auto-discovery

Source: https://gethomepage.dev/configs/docker/#automatic-service-discovery

Add labels to any container to have Homepage auto-discover and display it:

    services:
      myapp:
        image: myapp:latest
        labels:
          - homepage.group=Media
          - homepage.name=My App
          - homepage.icon=myapp.png
          - homepage.href=http://localhost:8096
          - homepage.description=My awesome app
          - homepage.widget.type=myapp        # optional service widget
          - homepage.widget.url=http://localhost:8096
          - homepage.widget.key=${MYAPP_API_KEY}

Homepage reads these labels via the Docker socket and automatically adds the service to the dashboard. No manual services.yaml entry needed.

## Config files overview

Source: https://gethomepage.dev/configs/

| File | Purpose |
|---|---|
| services.yaml | Service cards grouped into categories |
| widgets.yaml | Top-level information widgets (weather, time, search, etc.) |
| bookmarks.yaml | Bookmark groups (quick links) |
| settings.yaml | Global settings (theme, layout, language, etc.) |
| docker.yaml | Docker socket connections for container integration |
| kubernetes.yaml | Kubernetes cluster connections (optional) |

Environment variable secrets: use {{HOMEPAGE_VAR_MYKEY}} in YAML files and set HOMEPAGE_VAR_MYKEY in the container environment to avoid hardcoding API keys in config files.

## Upgrade procedure

    docker compose pull
    docker compose up -d

Config files in the mounted volume are preserved across upgrades. Check the release notes at https://github.com/gethomepage/homepage/releases for any breaking config changes.

## Gotchas

- HOMEPAGE_ALLOWED_HOSTS is required: without it (or with the wrong value), Homepage returns a 400 error. Include port if non-default (e.g. homeserver:3000 or 192.168.1.100:3000).
- Config changes require restart: YAML config file edits don't hot-reload in Docker. Restart the container: docker compose restart homepage.
- Docker socket security: mounting /var/run/docker.sock gives Homepage read access to the Docker API. Running as non-root (PUID/PGID) does not limit socket access — use a Docker socket proxy (e.g. tecnativa/docker-socket-proxy) for stricter isolation.
- :latest tag drift: Homepage releases frequently. Pin to a version tag (e.g. ghcr.io/gethomepage/homepage:v1.12.3) for predictable upgrades.
- Service widget API keys in config: env var substitution ({{HOMEPAGE_VAR_KEY}}) keeps keys out of YAML files on disk — use this pattern for all secrets.
- ARM64 supported: the same image works on Raspberry Pi and Apple Silicon without a separate tag.
- Docs site is authoritative: https://gethomepage.dev/ is the canonical reference for all service widgets, config options, and integration docs.

## Links

- Docs: https://gethomepage.dev/
- Installation (Docker): https://gethomepage.dev/installation/docker/
- Service widgets: https://gethomepage.dev/widgets/
- Docker integration: https://gethomepage.dev/configs/docker/
- Config reference: https://gethomepage.dev/configs/
- GitHub: https://github.com/gethomepage/homepage
- Releases: https://github.com/gethomepage/homepage/releases
