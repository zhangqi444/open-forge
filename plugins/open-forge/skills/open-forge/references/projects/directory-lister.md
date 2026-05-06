---
name: directory-lister
description: Directory Lister recipe for open-forge. Covers self-hosting the PHP-based web directory browser for exposing folder contents for browsing and sharing. Upstream: https://github.com/DirectoryLister/DirectoryLister
---

# Directory Lister

Zero-configuration, drag-and-drop PHP web app that exposes any web-accessible folder for browsing and sharing. Features light/dark themes, file search, file hashes, README rendering, zip downloads, and multi-language support. Upstream: <https://github.com/DirectoryLister/DirectoryLister>. Docker Compose repo: <https://github.com/DirectoryLister/directory-lister-compose>.

**License:** MIT

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose (directory-lister-compose) | https://github.com/DirectoryLister/directory-lister-compose | ✅ | Production self-hosting |
| Manual (PHP web server) | https://docs.directorylister.com | ✅ | Shared hosting / existing PHP stacks |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| app | "Path to the files/folders you want to expose?" | Absolute path | Docker |
| app | "Port to expose Directory Lister on?" | Number (default: 80) | Docker |
| app | "Directory Lister version tag?" | Semver tag (default: 5) | Docker |
| cache | "Valkey/Redis version?" | Semver tag (default: 9) | Docker |

## Docker Compose

From the official [directory-lister-compose](https://github.com/DirectoryLister/directory-lister-compose) repo:

```yaml
services:

  directory-lister:
    image: directorylister/directorylister:${DIRECTORY_LISTER_VERSION:-5}
    env_file: environment.d/directory-lister.env
    environment:
      CACHE_DRIVER: valkey
      REDIS_HOST: cache
      REDIS_PORT: 6379
    ports:
      - ${DIRECTORY_LISTER_PORT:-80}:80
    volumes:
      - ${FILES_PATH}:/data
      - /etc/localtime:/etc/localtime:ro
    depends_on: [cache]
    restart: unless-stopped

  cache:
    image: valkey/valkey:${VALKEY_VERSION:-9}
    volumes:
      - ${CACHE_VOLUME:-cache-data}:/data
      - /etc/localtime:/etc/localtime:ro
    restart: unless-stopped

  watchtower:
    image: containrrr/watchtower:${WATCHTOWER_VERSION:-latest}
    env_file: environment.d/watchtower.env
    environment:
      WATCHTOWER_SCOPE: ${COMPOSE_PROJECT_NAME}
    volumes:
      - ${DOCKER_SOCKET:-/var/run/docker.sock}:/var/run/docker.sock
      - /etc/localtime:/etc/localtime:ro
    labels:
      com.centurylinklabs.watchtower.scope: ${COMPOSE_PROJECT_NAME}
    restart: unless-stopped

volumes:
  cache-data: {}
```

## Software-layer concerns

### Key env vars (.env)

```
FILES_PATH=/path/to/your/files   # host directory to expose
DIRECTORY_LISTER_PORT=80         # host port
DIRECTORY_LISTER_VERSION=5       # image tag
VALKEY_VERSION=9
CACHE_VOLUME=cache-data
DOCKER_SOCKET=/var/run/docker.sock
```

### Config

- App config lives in `environment.d/directory-lister.env` (initialized via `make init` or manually from `.skeleton/`)
- Full configuration reference: https://docs.directorylister.com/configuration
- Key config options include: `APP_TITLE`, `SORT_ORDER`, `HIDE_FILES`, `DISPLAY_READMES`, `ENABLE_HASH_VERIFICATION`, `ENABLE_ZIP_DOWNLOADS`, `LANGUAGE`

### Data directories

| Path (container) | Purpose |
|---|---|
| `/data` | The files/folders exposed for browsing |

## Installation (Docker Compose)

```bash
git clone https://github.com/DirectoryLister/directory-lister-compose.git
cd directory-lister-compose
make init          # copies .skeleton/ config files; or run Makefile commands manually
# Edit .env — set FILES_PATH at minimum
# Edit environment.d/directory-lister.env for app-level config
docker compose config    # validate config
docker compose up -d
```

## Upgrade procedure

```bash
# Pull latest image tags
docker compose pull
docker compose up -d
```

Watchtower is included in the Compose stack and will auto-update containers within the defined scope. To disable auto-updates, remove the `watchtower` service from `docker-compose.yaml`.

Check upstream releases for breaking changes: https://github.com/DirectoryLister/DirectoryLister/releases

## Gotchas

- **`FILES_PATH` is required.** The `${FILES_PATH}` variable has no default; the container will fail to start if it is not set.
- **Valkey (not Redis).** The cache service uses Valkey (the open-source Redis fork). The `CACHE_DRIVER=valkey` env var must match the service name `cache` in the compose file.
- **PHP 8.2+ required for manual installs.** The Zip, DOM, and Fileinfo extensions are also required for zip downloads and README rendering.
- **Watchtower is optional.** If you manage updates manually, you can remove the `watchtower` service from the compose file.
- **Permissions.** Ensure the `FILES_PATH` directory is readable by the container user.

## Upstream docs

- GitHub README: https://github.com/DirectoryLister/DirectoryLister
- Docker Compose repo: https://github.com/DirectoryLister/directory-lister-compose
- Configuration docs: https://docs.directorylister.com/configuration
- Help & Support: https://docs.directorylister.com/help-and-support
