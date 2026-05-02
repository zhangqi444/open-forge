---
name: hollo-project
description: Hollo recipe for open-forge. Single-user headless microblogging server powered by ActivityPub (fediverse). No built-in web UI — use any Mastodon-compatible client. PostgreSQL + S3 storage (MinIO or external). Upstream: https://github.com/fedify-dev/hollo
---

# Hollo

A single-user, headless ActivityPub microblogging server — think of it as a personal Mastodon instance stripped to the essentials. Hollo has no built-in web UI; instead it exposes Mastodon-compatible APIs so you use any existing Mastodon client. Connects to the broader fediverse (Mastodon, Misskey, etc.) via ActivityPub.

Upstream: <https://github.com/fedify-dev/hollo> | Docs: <https://docs.hollo.social>

Powered by [Fedify](https://fedify.dev/). Requires PostgreSQL and S3-compatible object storage (MinIO works out of the box).

> **"Headless"** means no browser UI for posting — you need a Mastodon client (iOS, Android, desktop). See the [tested clients list](https://docs.hollo.social/clients/).

## Compatible combos

| Infra | Storage | Notes |
|---|---|---|
| Any Linux host | MinIO (self-hosted S3) | Full self-hosted stack; 4 containers |
| Any Linux host | External S3 (AWS, Backblaze B2, Cloudflare R2, etc.) | 2 containers (hollo + postgres); simpler |
| Railway | S3 | One-click Railway template available |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Host port for Hollo?" | Default: `3000` |
| preflight | "S3 storage: MinIO (local) or external S3?" | Determines number of containers |
| security | "Generate SECRET_KEY?" | Random string — required; `openssl rand -hex 32` |
| security | "PostgreSQL password?" | Change from default `password` |
| security (MinIO) | "MinIO root user/password?" | Change from `minioadmin`/`minioadmin` |
| config | "S3 bucket name?" | Default: `hollo` |
| config | "Public storage URL base?" | e.g. `https://s3.example.com/hollo/` — used for media URLs |
| config | "Behind a reverse proxy?" | `BEHIND_PROXY=true` if fronting with nginx/Caddy/Traefik |

## Software-layer concerns

### Image

```
ghcr.io/fedify-dev/hollo:canary
```

> `canary` is the rolling development image. Check the [releases page](https://github.com/fedify-dev/hollo/releases) for tagged stable releases.

### Compose (MinIO — full self-hosted)

```yaml
services:
  hollo:
    image: ghcr.io/fedify-dev/hollo:canary
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      DATABASE_URL: "postgres://user:password@postgres:5432/database"
      SECRET_KEY: "change-this-to-a-random-secret"
      LOG_LEVEL: "info"
      BEHIND_PROXY: "true"           # set true if behind nginx/Caddy/Traefik
      DRIVE_DISK: s3
      STORAGE_URL_BASE: "http://localhost:9000/hollo/"   # public URL for media
      S3_REGION: us-east-1
      S3_BUCKET: hollo
      S3_ENDPOINT_URL: "http://minio:9000"
      S3_FORCE_PATH_STYLE: "true"
      AWS_ACCESS_KEY_ID: minioadmin       # CHANGE IN PRODUCTION
      AWS_SECRET_ACCESS_KEY: minioadmin   # CHANGE IN PRODUCTION
    depends_on:
      - postgres
      - create-bucket

  postgres:
    image: postgres:17
    restart: unless-stopped
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password    # CHANGE IN PRODUCTION
      POSTGRES_DB: database
    volumes:
      - postgres_data:/var/lib/postgresql/data

  minio:
    image: minio/minio
    restart: unless-stopped
    ports:
      - "9000:9000"
      - "9001:9001"   # MinIO console
    environment:
      MINIO_ROOT_USER: minioadmin       # CHANGE IN PRODUCTION
      MINIO_ROOT_PASSWORD: minioadmin   # CHANGE IN PRODUCTION
    volumes:
      - minio_data:/data
    command: ["server", "/data", "--console-address", ":9001"]

  create-bucket:
    image: minio/mc
    depends_on:
      - minio
    restart: on-failure
    entrypoint: |
      /bin/sh -c "
        /usr/bin/mc alias set minio http://minio:9000 minioadmin minioadmin;
        /usr/bin/mc mb minio/hollo;
        /usr/bin/mc anonymous set public minio/hollo;
        exit 0;
      "

volumes:
  postgres_data:
  minio_data:
```

> Source: upstream compose.yaml — <https://github.com/fedify-dev/hollo>

### Compose (external S3 — minimal)

```yaml
services:
  hollo:
    image: ghcr.io/fedify-dev/hollo:canary
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      DATABASE_URL: "postgres://user:password@postgres:5432/database"
      SECRET_KEY: "change-this-to-a-random-secret"
      BEHIND_PROXY: "true"
      DRIVE_DISK: s3
      STORAGE_URL_BASE: "https://your-bucket.s3.amazonaws.com/"
      S3_REGION: us-east-1
      S3_BUCKET: hollo
      AWS_ACCESS_KEY_ID: your-access-key
      AWS_SECRET_ACCESS_KEY: your-secret-key
    depends_on:
      - postgres

  postgres:
    image: postgres:17
    restart: unless-stopped
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
      POSTGRES_DB: database
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

### Key environment variables

| Variable | Required | Purpose |
|---|---|---|
| `DATABASE_URL` | ✅ | PostgreSQL connection string |
| `SECRET_KEY` | ✅ | Random signing secret — generate with `openssl rand -hex 32` |
| `BEHIND_PROXY` | | Set `true` when behind a reverse proxy (reads `X-Forwarded-*` headers) |
| `LOG_LEVEL` | | `debug`, `info`, `warning`, `error`, `fatal` |
| `DRIVE_DISK` | ✅ | `s3` for S3-compatible storage |
| `STORAGE_URL_BASE` | ✅ | Public base URL for media assets |
| `S3_REGION` | ✅ | S3 region (use `us-east-1` for MinIO/Backblaze) |
| `S3_BUCKET` | ✅ | S3 bucket name |
| `S3_ENDPOINT_URL` | | Custom S3 endpoint (required for MinIO/R2/B2) |
| `S3_FORCE_PATH_STYLE` | | `true` for MinIO and other path-style S3 endpoints |
| `AWS_ACCESS_KEY_ID` | ✅ | S3 access key |
| `AWS_SECRET_ACCESS_KEY` | ✅ | S3 secret key |

Full env var reference: <https://docs.hollo.social/install/env/>

### Reverse proxy requirement

Hollo **must** be served over HTTPS for ActivityPub federation to work (other fediverse servers will reject HTTP actor URLs). Front with Caddy, Traefik, or nginx.

Set `BEHIND_PROXY=true` so Hollo reads the correct hostname from `X-Forwarded-Host` / `X-Forwarded-Proto`.

### First-run setup

After starting, access the setup page (route documented at <https://docs.hollo.social/install/setup/>) to create your account and configure your actor handle.

### Fediverse / ActivityPub

Hollo implements ActivityPub. Your account is addressable as `@you@yourdomain.com` from any fediverse platform (Mastodon, Misskey, Pixelfed, etc.).

### Client apps

Hollo exposes Mastodon-compatible APIs. Any Mastodon client works:
- iOS: Ivory, Mona, Ice Cubes, Toot!
- Android: Tusky, Megalodon, Moshidon
- Desktop: Pinafore, Elk, Whalebird

Full tested client list: <https://docs.hollo.social/clients/>

### Search

Full-text search is available. See: <https://docs.hollo.social/search/>

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

PostgreSQL data and MinIO object storage persist in named volumes.

## Gotchas

- **HTTPS is mandatory for federation** — ActivityPub requires HTTPS. Without it, your actor profile is invalid and other fediverse servers won't federate with you. Always use a TLS-terminating reverse proxy.
- **`BEHIND_PROXY=true` required behind a proxy** — without it, Hollo generates HTTP actor URLs (wrong scheme), breaking federation.
- **Change all default credentials** — `minioadmin`/`minioadmin`, PostgreSQL `password`, and the `create-bucket` hardcoded credentials in the entrypoint script all need updating for production.
- **`STORAGE_URL_BASE` must be the public URL** — media URLs in posts are constructed from this base. Set it to the publicly reachable URL of your MinIO/S3 bucket, not the internal Docker service URL.
- **`S3_FORCE_PATH_STYLE=true` required for MinIO** — MinIO uses path-style URLs by default; without this flag, SDK uses virtual-hosted style and bucket requests fail.
- **`canary` tag is rolling** — pin to a specific release tag for production stability.
- **Single-user only** — Hollo is designed for one account per instance. It is not a multi-user platform.
- **No web posting UI** — you need a Mastodon-compatible client to post. There is no browser-based post editor.

## Links

- Upstream README (English): <https://github.com/fedify-dev/hollo/blob/HEAD/README.en.md>
- Documentation: <https://docs.hollo.social>
- Docker installation guide: <https://docs.hollo.social/install/docker/>
- Environment variables reference: <https://docs.hollo.social/install/env/>
- Setup guide: <https://docs.hollo.social/install/setup/>
- Tested clients: <https://docs.hollo.social/clients/>
- Fedify (underlying framework): <https://fedify.dev/>
