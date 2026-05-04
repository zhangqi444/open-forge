---
name: adminer-project
description: Adminer recipe for open-forge. Covers Docker-based deployment of Adminer, a single-file PHP web UI for database management supporting MySQL, PostgreSQL, SQLite, MS SQL, Oracle, MongoDB, and Elasticsearch. Includes network scoping, auth proxy guidance, design plugins, and gotchas.
---

# Adminer

Adminer is a single-file PHP web UI for database management. Supports MySQL, PostgreSQL, SQLite, MS SQL, Oracle, MongoDB, and Elasticsearch. Upstream: <https://github.com/vrana/adminer>. Docs: <https://www.adminer.org/>. Docker Hub: <https://hub.docker.com/_/adminer>.

Adminer ships as a single PHP file but the Docker image wraps it in a minimal web server (Alpine + PHP + either Apache or nginx depending on the variant). It connects to databases on your Docker network by hostname, so the primary deployment concern is keeping it on the same network as your target databases and not exposing it to the public internet without an auth proxy.

## Install method

Adminer is Docker-only for self-hosted deployments. There is no separate binary install path for server use — the official Docker image is the standard approach.

## Inputs to collect

| Phase | Prompt | Applicability |
|---|---|---|
| preflight | "Which database(s) will Adminer connect to?" | Determines which Docker networks to attach |
| preflight | "Default database server hostname?" | Sets `ADMINER_DEFAULT_SERVER` |
| preflight | "Desired UI design theme?" | Sets `ADMINER_DESIGN` (optional) |
| auth | "Will you protect Adminer with an auth proxy (e.g. Authelia, nginx basic auth)?" | Required for any internet-exposed deployment |

## Docker Compose deployment

```yaml
# compose.yaml
services:
  adminer:
    image: adminer
    container_name: adminer
    restart: unless-stopped
    ports:
      - "8080:8080"    # Remove or change if behind a reverse proxy
    environment:
      ADMINER_DEFAULT_SERVER: "${ADMINER_DEFAULT_SERVER:-db}"
      ADMINER_DESIGN: "${ADMINER_DESIGN:-pepa-linha}"   # optional
    networks:
      - db_network

networks:
  db_network:
    external: true    # attach to the existing network where your DB lives
```

If your database is in a separate Compose project, use `external: true` and reference the network by name. If deploying in the same Compose file as your DB, share the default network instead.

## Key environment variables

| Variable | Default | Purpose |
|---|---|---|
| `ADMINER_DEFAULT_SERVER` | (unset) | Pre-fills the "Server" field on the login page (e.g. `db` or `postgres`) |
| `ADMINER_DESIGN` | (unset) | CSS design theme name from <https://github.com/vrana/adminer/tree/master/designs> |
| `ADMINER_PLUGINS` | (unset) | Space-separated list of plugin names to enable (e.g. `tables-filter tinymce`) |

## Supported databases

Adminer auto-detects available drivers from the PHP extensions included in the image tag:

| Tag variant | Drivers |
|---|---|
| `adminer` (default) | MySQL, PostgreSQL, SQLite, MS SQL, Oracle (where PHP extension exists) |
| `adminer:fastcgi` | Same, served via FastCGI |

MongoDB and Elasticsearch are supported via plugins — not included in the base image by default. For those, use a custom image (see Plugins section below).

## Themes (ADMINER_DESIGN)

Popular built-in themes:

- `pepa-linha` — clean, minimal
- `lucas-sandery` — dark sidebar
- `brade` — dark mode
- `ng9` — Bootstrap-style

Browse all options: <https://github.com/vrana/adminer/tree/master/designs>

## Plugins

To enable plugins (e.g. for MongoDB support, table filters, or an editor), create a custom image:

```dockerfile
FROM adminer
RUN mkdir -p /var/www/html/plugins-enabled
# Enable a plugin by creating a symlink
RUN ln -s /var/www/html/plugins/tables-filter.php /var/www/html/plugins-enabled/
```

Or mount a `plugins-enabled/` directory as a volume.

## Auth proxy (strongly recommended for internet exposure)

Adminer has **no built-in authentication** beyond the database credentials entered on the login form. If Adminer is reachable from the internet, anyone can attempt to log in with any credentials. Always put Adminer behind an auth proxy:

- **Authelia** — full SSO with 2FA
- **nginx basic auth** — simple HTTP auth gate
- **Traefik middleware** (ForwardAuth)
- **Caddy basicauth** directive

Ensure the Adminer port is NOT published to `0.0.0.0` if the host is internet-facing. Bind to `127.0.0.1` and let the reverse proxy handle external access:

```yaml
ports:
  - "127.0.0.1:8080:8080"
```

## Verify

```bash
docker compose ps adminer                          # running
curl -sI http://localhost:8080/                    # HTTP 200
```

Open the browser at `http://localhost:8080/` (or via your reverse proxy URL). The login form should appear with the "Server" field pre-filled if `ADMINER_DEFAULT_SERVER` was set.

## Lifecycle (upgrade)

Adminer is stateless — upgrading is just pulling the new image and recreating the container:

```bash
docker compose pull adminer
docker compose up -d adminer
```

## Gotchas

- **No built-in auth.** Adminer relies entirely on DB credentials. Do not expose it to the internet without an auth proxy layer.
- **Network scope is critical.** Adminer must be on the same Docker network as the databases it manages. If you have multiple DB networks, attach Adminer to all of them — it can connect to any host visible on those networks.
- **Default server must match the DB service name.** `ADMINER_DEFAULT_SERVER=db` only works if there is a service named `db` on the shared network. Use the exact Docker service name or hostname.
- **SQLite requires volume access.** To manage a SQLite file, mount its containing directory into the Adminer container; it cannot access host paths otherwise.
- **Design plugins are cosmetic only.** `ADMINER_DESIGN` changes the CSS; it does not affect functionality or security.
- **Image is Alpine-based and small.** The default image is under 100 MB but may lag slightly behind the latest Adminer release. Check Docker Hub for current tags.
