# YeetFile

**What it is:** Privacy-focused encrypted file vault and file/text transfer service. All content is encrypted client-side before reaching the server — the server cannot decrypt anything. Supports local storage, Backblaze B2, and any S3-compatible backend. Offers a web UI and official CLI client. Self-hosted instances have no payment requirements; free/paid tiers only apply to the official yeetfile.com instance.

**Official URL:** https://github.com/benbusby/yeetfile  
**Docs:** https://docs.yeetfile.com  
**Official instance:** https://yeetfile.com

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Docker Compose | Recommended; includes PostgreSQL |
| Any Linux host | Systemd | Binary deployment documented in README |
| Any | Kamal | Deployment via Kamal documented in README |

---

## Inputs to Collect

| Phase | Input | Notes |
|-------|-------|-------|
| Deploy | `YEETFILE_DB_USER` | PostgreSQL username (default `postgres`) |
| Deploy | `YEETFILE_DB_PASS` | PostgreSQL password (default `postgres` — change this!) |
| Deploy | `YEETFILE_DB_NAME` | PostgreSQL database name (default `yeetfile`) |
| Deploy | Host port | Default `8090` |
| Optional | `YEETFILE_STORAGE` | Storage backend: `local` (default), `b2`, or S3-compatible |
| Optional | `YEETFILE_DEFAULT_USER_STORAGE` | Default storage quota per user in bytes (`-1` = unlimited) |
| Optional | `YEETFILE_DEFAULT_USER_SEND` | Default send quota per user in bytes (`-1` = unlimited) |
| Optional | `YEETFILE_HOST` | Bind address (default `0.0.0.0`) |
| Optional | `YEETFILE_PORT` | Container listen port (default `8090`) |
| Optional | `YEETFILE_DEBUG` | Enable debug logging (`1` to enable) |

---

## Software-Layer Concerns

### Docker image
```
ghcr.io/benbusby/yeetfile:latest
```

### docker-compose.yml
```yaml
services:
  api:
    image: ghcr.io/benbusby/yeetfile:latest
    container_name: yeetfile
    restart: unless-stopped
    ports:
      - 8090:${YEETFILE_PORT:-8090}
    depends_on:
      db:
        condition: service_healthy
    environment:
      - YEETFILE_DEBUG=${YEETFILE_DEBUG:-0}
      - YEETFILE_STORAGE=${YEETFILE_STORAGE:-local}
      - YEETFILE_DEFAULT_USER_STORAGE=${YEETFILE_DEFAULT_USER_STORAGE:--1}
      - YEETFILE_DEFAULT_USER_SEND=${YEETFILE_DEFAULT_USER_SEND:--1}
      - YEETFILE_HOST=${YEETFILE_HOST:-0.0.0.0}
      - YEETFILE_PORT=${YEETFILE_PORT:-8090}
      - YEETFILE_DB_USER=${YEETFILE_DB_USER:-postgres}
      - YEETFILE_DB_PASS=${YEETFILE_DB_PASS:-postgres}
      - YEETFILE_DB_NAME=${YEETFILE_DB_NAME:-yeetfile}
      - YEETFILE_DB_HOST=${YEETFILE_DB_HOST:-db}
    volumes:
      - ./volumes/yeetfile/uploads:/app/uploads

  db:
    image: postgres:16-alpine
    container_name: yeetfile-db
    restart: unless-stopped
    volumes:
      - ./volumes/yeetfile/data:/var/lib/postgresql/data
    environment:
      - POSTGRES_HOST_AUTH_METHOD=${POSTGRES_HOST_AUTH_METHOD:-md5}
      - POSTGRES_USER=${YEETFILE_DB_USER:-postgres}
      - POSTGRES_PASSWORD=${YEETFILE_DB_PASS:-postgres}
      - POSTGRES_DB=${YEETFILE_DB_NAME:-yeetfile}
    expose:
      - 5432
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 3s
      timeout: 5s
      retries: 5
```

### Storage
- **Local storage** (default): uploads stored in `./volumes/yeetfile/uploads`
- **Backblaze B2** or **S3-compatible**: set `YEETFILE_STORAGE` and additional B2/S3 credentials (see README for env var names)
- For large deployments, create an external named volume: `docker volume create --name=yeetfile_data`

---

## Upgrade Procedure

```bash
docker compose pull
docker compose up -d
```

PostgreSQL data and local uploads are in named volumes/mounts. Check release notes for schema migrations.

---

## Gotchas

- **Change default DB password** — the default `postgres`/`postgres` is insecure; always set a strong `YEETFILE_DB_PASS`
- **Client-side encryption** — the server never holds plaintext; this means **no server-side search** and **no account recovery** if you lose your password or encryption keys
- **No upload size limit for Vault** — the vault has no enforced size limit; Send transfers max at 10 downloads and 30-day expiry (configurable per transfer)
- **No payment required when self-hosting** — Stripe/BTC payment features only apply to the official instance; self-hosted instances are fully featured for free
- **CLI client** — an official CLI is available in releases and can be pointed at any self-hosted instance via config

---

## Links

- GitHub: https://github.com/benbusby/yeetfile
- Documentation: https://docs.yeetfile.com
- Security model: https://docs.yeetfile.com/security/
- Official instance: https://yeetfile.com
