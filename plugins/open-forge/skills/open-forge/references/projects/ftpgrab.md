# FTPGrab

**What it is:** Command-line tool for periodically pulling files from remote FTP and SFTP servers to local storage. Built for unattended transfers — configure remote sources, run on a schedule, filter by include/exclude patterns, skip already-downloaded files, and receive notifications. Ideal for seedboxes and home servers.

**Docs:** https://crazymax.dev/ftpgrab/  
**GitHub:** https://github.com/crazy-max/ftpgrab  
**Docker Hub:** `crazymax/ftpgrab`  
**GHCR:** `ghcr.io/crazy-max/ftpgrab`  
**License:** MIT

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker Compose | Recommended; all config via env vars |
| NAS (Synology, QNAP, etc.) | Docker | Multi-arch: amd64, arm64, arm/v6, arm/v7, 386, ppc64le |
| Any Linux | Binary | Single binary from GitHub releases |

---

## Inputs to Collect

### Phase: Deploy

| Variable | Description |
|----------|-------------|
| `TZ` | Timezone (e.g. `America/New_York`) |
| `SCHEDULE` | Cron expression for run schedule (e.g. `*/30 * * * *`) |
| `FTPGRAB_SERVER_FTP_HOST` | FTP server hostname or IP |
| `FTPGRAB_SERVER_FTP_PORT` | FTP port (default `21`) |
| `FTPGRAB_SERVER_FTP_USERNAME` | FTP username |
| `FTPGRAB_SERVER_FTP_PASSWORD` | FTP password |
| `FTPGRAB_SERVER_FTP_SOURCES` | Comma-separated remote source paths (e.g. `/src1,/src2`) |
| `FTPGRAB_DOWNLOAD_UID` | UID for downloaded file ownership (e.g. `1000`) |
| `FTPGRAB_DOWNLOAD_GID` | GID for downloaded file ownership (e.g. `1000`) |

### Phase: Optional

| Variable | Description |
|----------|-------------|
| `FTPGRAB_DOWNLOAD_INCLUDE` | Regex pattern — only download matching filenames |
| `FTPGRAB_DOWNLOAD_EXCLUDE` | Regex pattern — skip matching filenames |
| `FTPGRAB_DOWNLOAD_SINCE` | Only download files newer than this ISO timestamp |
| `FTPGRAB_DOWNLOAD_RETRY` | Number of download retries on failure (default `5`) |
| `FTPGRAB_NOTIF_MAIL_HOST` | SMTP host for email notifications |
| `FTPGRAB_NOTIF_MAIL_PORT` | SMTP port |
| `FTPGRAB_NOTIF_MAIL_FROM` | Sender address |
| `FTPGRAB_NOTIF_MAIL_TO` | Recipient address |
| `LOG_LEVEL` | Log verbosity (`info`, `debug`, etc.) |
| `LOG_JSON` | Output logs as JSON (`true`/`false`) |

---

## Software-Layer Concerns

- **bbolt database** (`/db`) — tracks which files have already been downloaded to avoid re-downloading; persist this volume
- **Download directory** (`/download`) — where grabbed files land; mount to desired host path
- **Schedule** is a standard cron expression; runs FTPGrab on the configured interval
- **SFTP support** — use `FTPGRAB_SERVER_SFTP_*` env vars instead of `FTP` for SSH/SFTP servers
- **Multi-arch image** — runs on all common platforms including ARM (Raspberry Pi, NAS devices)

---

## Example Docker Compose

```yaml
services:
  ftpgrab:
    image: crazymax/ftpgrab:latest
    container_name: ftpgrab
    volumes:
      - "./db:/db:rw"
      - "./download:/download:rw"
    environment:
      TZ: America/New_York
      SCHEDULE: "*/30 * * * *"
      LOG_LEVEL: info
      FTPGRAB_SERVER_FTP_HOST: your.ftp.server
      FTPGRAB_SERVER_FTP_PORT: "21"
      FTPGRAB_SERVER_FTP_USERNAME: youruser
      FTPGRAB_SERVER_FTP_PASSWORD: yourpass
      FTPGRAB_SERVER_FTP_SOURCES: /remote/path
      FTPGRAB_DOWNLOAD_UID: "1000"
      FTPGRAB_DOWNLOAD_GID: "1000"
    restart: always
```

---

## Upgrade Procedure

1. Pull new image: `docker compose pull`
2. Restart: `docker compose up -d`
3. bbolt database persists across upgrades — no migration needed

---

## Gotchas

- **`/db` volume must be persisted** — without it, FTPGrab re-downloads all files on every run
- **UID/GID settings** — set to match the user who owns your download directory to avoid permission issues
- **Regex patterns** in `INCLUDE`/`EXCLUDE` use Go regex syntax — test patterns before relying on them
- **SFTP vs FTP** — use the correct env var prefix (`FTPGRAB_SERVER_SFTP_*` for SFTP, `FTPGRAB_SERVER_FTP_*` for FTP); they are not interchangeable
- FTPGrab runs as a one-shot command on each schedule tick — not a persistent daemon

---

## Links

- Docs: https://crazymax.dev/ftpgrab/
- GitHub: https://github.com/crazy-max/ftpgrab
- Docker Hub: https://hub.docker.com/r/crazymax/ftpgrab
