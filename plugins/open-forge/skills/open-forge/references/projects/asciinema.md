---
name: asciinema server
description: Self-hosted host-and-share platform for terminal session recordings (`.cast` / asciicast v3) and live terminal streams. Elixir/Phoenix + Postgres. Apache-2.0.
---

# asciinema server

The server half of the asciinema ecosystem. It stores terminal-session recordings uploaded by the [asciinema CLI](https://github.com/asciinema/asciinema), renders them with the asciinema player, provides full-text search over the actual terminal contents (via embedded `avt` terminal), and supports live streaming of sessions. <https://asciinema.org> is the managed instance; self-hosting is fully supported and is what this recipe covers.

- Upstream repo: <https://github.com/asciinema/asciinema-server>
- Self-hosting docs: <https://docs.asciinema.org/manual/server/self-hosting/>
- Quick start: <https://docs.asciinema.org/manual/server/self-hosting/quick-start/>
- Configuration reference: <https://docs.asciinema.org/manual/server/self-hosting/configuration/>
- Image: `ghcr.io/asciinema/asciinema-server` (Docker Hub copy also available)

## Compatible install methods

| Infra              | Runtime             | Notes                                                              |
| ------------------ | ------------------- | ------------------------------------------------------------------ |
| Single VM          | Docker + Compose    | **Recommended.** Upstream docs-site is Docker-Compose-native        |
| Kubernetes         | Plain manifests     | Straightforward given the minimal service set                       |
| Bare metal (Elixir) | Build from source  | Possible; not the documented path                                   |

## Inputs to collect

| Input              | Example                                 | Phase     | Notes                                                                     |
| ------------------ | --------------------------------------- | --------- | ------------------------------------------------------------------------- |
| `SECRET_KEY_BASE`  | 64 random alphanumerics                 | Runtime   | **Required.** Signs sessions + login-link tokens                           |
| `URL_HOST`         | `asciinema.example.com`                 | Runtime   | Must match DNS exactly — used in every generated link                     |
| `URL_SCHEME`       | `https` (TLS) / `http` (lan)            | Runtime   | Pick one; affects cookie `Secure` flag                                    |
| `URL_PORT`         | `443` / `80` / custom                    | Runtime   | Only set when non-default for the scheme                                  |
| SMTP config        | any provider                             | Runtime   | **Login is email-link based.** No mail = no login (except reading logs)   |
| Postgres           | `postgres:14`                            | Data      | Upstream-pinned in docs; 14+ required                                     |
| S3 (optional)      | bucket + keys                            | Data      | Replaces local file store for recordings                                  |

## Install via Docker Compose (HTTPS, with Caddy)

From upstream quick-start (<https://docs.asciinema.org/manual/server/self-hosting/quick-start/>):

```yaml
services:
  asciinema:
    image: ghcr.io/asciinema/asciinema-server:20260207   # pin; check releases link below
    environment:
      - SECRET_KEY_BASE=REPLACE_WITH_64_CHARS
      - URL_HOST=asciinema.example.com
      - URL_SCHEME=https
      - SMTP_HOST=smtp.example.com
      - SMTP_USERNAME=asciinema@example.com
      - SMTP_PASSWORD=REPLACE_ME
    volumes:
      - asciinema_data:/var/lib/asciinema
    depends_on:
      postgres:
        condition: service_healthy

  postgres:
    image: docker.io/library/postgres:14
    environment:
      - POSTGRES_HOST_AUTH_METHOD=trust
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -U postgres']
      interval: 2s
      timeout: 5s
      retries: 10

  caddy:
    image: caddy:2
    command: caddy reverse-proxy --from https://asciinema.example.com --to http://asciinema:4000
    ports:
      - '80:80'
      - '443:443'
      - '443:443/udp'
    volumes:
      - caddy_data:/data
      - caddy_config:/config

volumes:
  asciinema_data:
  postgres_data:
  caddy_data:
  caddy_config:
```

Generate `SECRET_KEY_BASE`:

```sh
tr -dc A-Za-z0-9 </dev/urandom | head -c 64; echo
```

`docker compose up -d`, browse `URL_HOST`. Log in via email — Caddy auto-provisions a Let's Encrypt cert on first access.

### HTTP-only variant (no TLS)

For a lan-only instance, omit Caddy and publish Phoenix directly:

```yaml
services:
  asciinema:
    image: ghcr.io/asciinema/asciinema-server:20260207
    ports:
      - '80:4000'
    environment:
      - SECRET_KEY_BASE=REPLACE_WITH_64_CHARS
      - URL_HOST=asciinema.example.com
      - URL_PORT=80
      - SMTP_HOST=smtp.example.com
      - SMTP_USERNAME=asciinema@example.com
      - SMTP_PASSWORD=REPLACE_ME
    volumes:
      - asciinema_data:/var/lib/asciinema
    depends_on:
      postgres:
        condition: service_healthy
  postgres: # same as above
```

## Connecting the CLI

```sh
export ASCIINEMA_SERVER_URL=https://asciinema.example.com   # CLI 3.x
# or:
export ASCIINEMA_API_URL=https://asciinema.example.com      # CLI 2.x
asciinema auth           # prints a one-time login URL
asciinema rec demo.cast  # record
asciinema upload demo.cast
```

## Data & config layout

- `/var/lib/asciinema/` inside container → recordings + any derived files
- Container's `DATABASE_URL` defaults to `postgresql://postgres@postgres/postgres` — the upstream compose leans on this, so the service name `postgres` matters
- Full env reference (100+ flags for SMTP, S3, SSO, streaming, rate limits): <https://docs.asciinema.org/manual/server/self-hosting/configuration/>

## Backup

```sh
# Database
docker compose exec -T postgres pg_dump -U postgres postgres | gzip > asciinema-db-$(date +%F).sql.gz

# Recordings (local file store)
docker run --rm -v asciinema_data:/data -v "$PWD":/backup alpine \
  tar czf /backup/asciinema-data-$(date +%F).tgz -C /data .
```

If you switch to S3 (`FILE_STORE=s3` + AWS creds), the `asciinema_data` volume becomes effectively empty.

## Upgrade

1. Releases: <https://github.com/asciinema/asciinema-server/releases>.
2. Bump image tag → `docker compose pull && docker compose up -d`.
3. The server runs Ecto migrations on boot. Watch logs.
4. Before major version jumps, take a Postgres dump.
5. Upgrading guide: <https://docs.asciinema.org/manual/server/self-hosting/upgrading/>.

## Gotchas

- **Login is email-link only.** No passwords, no SSO out of the box. If SMTP is broken, **the server log prints the login URL** (by design, for bootstrap) — useful rescue hatch but means log access == admin access.
- **`SECRET_KEY_BASE` rotation invalidates all sessions.** Generate once, keep stable.
- **`URL_HOST`/`URL_SCHEME`/`URL_PORT` must match external URL exactly.** Wrong value = broken share links and broken CLI auth flow.
- **`POSTGRES_HOST_AUTH_METHOD=trust`** in the quick-start compose is fine because Postgres only listens on the compose network. **Do not** expose the `postgres` service externally with `trust` auth.
- **Live streams need a reverse proxy that forwards WebSocket + SSE properly.** Caddy v2 handles this automatically; hand-rolled nginx needs `proxy_http_version 1.1`, `Upgrade`/`Connection` headers, and disabled buffering.
- **Recordings include the full terminal session.** Treat them as sensitive — an unlisted URL is security-through-obscurity; use the `private` visibility for anything containing secrets.
- **Full-text search is over the terminal contents**, not just titles. This is a feature, but also means search results can leak fragments of "private" recordings to anyone with search access. Scope access accordingly.
- **Default file-store is local disk.** For multi-instance HA or very large deployments, switch to S3-compatible storage via the `FILE_STORE=s3` block — see the config reference.
- **API tokens are per-install.** Users running `asciinema auth` against your instance get a token valid only there; no sharing with asciinema.org.
- **Container image is large-ish (~350 MB).** Bundles the Erlang runtime + compiled Phoenix release.
- **Postgres 14 is pinned in upstream docs** but newer majors work; upgrade with `pg_dump` → restore into a new volume (no in-place cross-major upgrade for the postgres image).
- **AGPL? Actually Apache-2.0.** Unlike some self-hostable competitors, asciinema server is permissively licensed. Good for internal corporate use.

## Links

- Repo: <https://github.com/asciinema/asciinema-server>
- Self-hosting docs: <https://docs.asciinema.org/manual/server/self-hosting/>
- Quick start: <https://docs.asciinema.org/manual/server/self-hosting/quick-start/>
- Configuration reference: <https://docs.asciinema.org/manual/server/self-hosting/configuration/>
- Upgrade guide: <https://docs.asciinema.org/manual/server/self-hosting/upgrading/>
- Releases: <https://github.com/asciinema/asciinema-server/releases>
- Image: <https://github.com/asciinema/asciinema-server/pkgs/container/asciinema-server>
- asciinema CLI: <https://github.com/asciinema/asciinema>
- Player: <https://github.com/asciinema/asciinema-player>
