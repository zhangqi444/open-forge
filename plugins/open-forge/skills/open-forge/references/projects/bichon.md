---
name: Bichon
description: "Open-source email archiver with WebUI and full-text search. Docker. Rust. AGPLv3. rustmailer/bichon. IMAP sync + REST API + search — read-only archive, not an email client."
---

# Bichon

**Lightweight, high-performance email archiver with WebUI.** Connects to IMAP servers, continuously synchronizes emails, indexes them for full-text search, and provides a REST API and built-in WebUI for browsing. **Not an email client** — no sending, no MUA features. Purpose-built for **archiving, searching, and programmatic access** to historical email. Built in Rust with zero external dependencies.

Named after the puppy the maintainer's daughter adopted. Built + maintained by **rustmailer team**.

- Upstream repo: <https://github.com/rustmailer/bichon>
- Docker Hub: <https://hub.docker.com/r/rustmailer/bichon>
- Discord: <https://discord.gg/Bq4M2cDmF4>
- Docs: <https://deepwiki.com/rustmailer/bichon>

## Architecture in one minute

- **Single Rust binary** — no external runtime dependencies
- Port **15630** — WebUI + REST API
- IMAP sync → full-text index (envelope/index dir) + raw `.eml` storage (data dir)
- Run as a **non-root user** (Docker `user:` / `--user` flag)
- SQLite or internal index (no external DB required)
- Resource: **low** — Rust, small binary, efficient indexing

## Compatible install methods

| Infra       | Runtime                   | Notes                                              |
| ----------- | ------------------------- | -------------------------------------------------- |
| **Docker**  | `rustmailer/bichon`       | **Primary** — one-liner or compose                 |

## Inputs to collect

| Input                        | Example                          | Phase    | Notes                                                                         |
| ---------------------------- | -------------------------------- | -------- | ----------------------------------------------------------------------------- |
| IMAP server + credentials    | `imap.gmail.com:993` + app pw    | Auth     | Supports any IMAP server; app-specific password recommended for Gmail         |
| Domain (optional)            | `mail-archive.example.com`       | URL      | Front with reverse proxy + TLS if exposing publicly                           |
| UID / GID                    | `1000:1000`                      | Security | Set via Docker `user:` to match host filesystem owner                         |
| Storage paths (optional)     | `./bichon-data`, `./envelope`, `./eml` | Storage | Default: all under `BICHON_ROOT_DIR`; split for NAS arrangements        |
| CORS origins (optional)      | `https://mail-archive.example.com` | Security | Required v0.1.4+ if you set it; `*` is NOT supported — exact URLs only      |

## Install via Docker (one-liner)

```sh
mkdir -p ./bichon-data

docker run -d \
  --name bichon \
  -p 15630:15630 \
  -v $(pwd)/bichon-data:/data \
  --user 1000:1000 \
  -e BICHON_LOG_LEVEL=info \
  -e BICHON_ROOT_DIR=/data \
  rustmailer/bichon:latest
```

Visit `http://localhost:15630`.

## Install via Docker Compose

```yaml
services:
  bichon:
    image: rustmailer/bichon:latest
    container_name: bichon
    ports:
      - "15630:15630"
    volumes:
      - ./bichon-data:/data
    user: "1000:1000"
    environment:
      BICHON_ROOT_DIR: /data
      BICHON_LOG_LEVEL: info
    restart: unless-stopped
```

### Optional: custom storage layout (split index + data)

```yaml
    volumes:
      - ./bichon-data:/data
      - ./envelope:/envelope
      - ./eml:/eml
    environment:
      BICHON_ROOT_DIR: /data
      BICHON_INDEX_DIR: /envelope
      BICHON_DATA_DIR: /eml
```

## First boot

1. Deploy container.
2. Visit `http://localhost:15630` (or your domain).
3. Add an IMAP account in the WebUI (server + credentials).
4. Bichon begins syncing — full initial sync of large accounts can take time.
5. Use the WebUI or REST API to search and browse archived emails.
6. Set `BICHON_CORS_ORIGINS` if you access the WebUI from a different domain.
7. Put behind TLS (reverse proxy) if exposing beyond localhost.

## Environment variables

| Variable                | Default      | Effect                                                                                |
| ----------------------- | ------------ | ------------------------------------------------------------------------------------- |
| `BICHON_ROOT_DIR`       | `/data`      | Root for all storage (index + emails)                                                 |
| `BICHON_INDEX_DIR`      | (root)       | Override index storage location                                                       |
| `BICHON_DATA_DIR`       | (root)       | Override raw `.eml` storage location                                                  |
| `BICHON_LOG_LEVEL`      | `warn`       | `debug` / `info` / `warn` / `error`                                                   |
| `BICHON_CORS_ORIGINS`   | (allow all) | v0.1.4+: if set, list exact origins (comma-separated). `*` not supported.             |

## Data & config layout

- `/data/` — all archived email data (index + raw `.eml` files) unless split
- Optional `/envelope/` — search index only
- Optional `/eml/` — raw `.eml` email files only

## Backup

```sh
docker compose stop bichon
sudo tar czf bichon-$(date +%F).tgz bichon-data/
docker compose start bichon
```

Contents: **your entire email archive** — highly sensitive (personal + business correspondence, attachments, 2FA codes, account recovery emails). Encrypt backups; restrict backup target access. This is Tier-1 PII / crown-jewel material.

## Upgrade

1. Releases: <https://github.com/rustmailer/bichon/releases>
2. `docker compose pull && docker compose up -d`

## Gotchas

- **Read-only archive — no sending.** Bichon has zero email-sending capability. It's a pure sink: IMAP in, indexed archive out. If you want a full email client, look at Roundcube, Rainloop, or Snappymail.
- **Non-root UID/GID required.** Use Docker `user: "1000:1000"` (or `--user`) to match the host directory owner. Without this, volume writes either fail or create root-owned files you can't easily manage. `PUID`/`PGID` env vars (LinuxServer.io style) are **not used** — Docker-native `user:` only.
- **CORS origins `*` not supported (v0.1.4+).** If you set `BICHON_CORS_ORIGINS`, provide explicit URLs. An asterisk silently fails. If you don't set it at all, all origins are allowed (fine for local access, not for production).
- **Initial full-sync can be very slow for large accounts.** Decades of email with tens of thousands of messages will take hours. Don't mistake slow initial sync for a crash — check `BICHON_LOG_LEVEL=info` logs.
- **IMAP app passwords.** Gmail, Outlook, and most providers with 2FA require app-specific passwords for IMAP access (not your main login password). Create one per provider.
- **Email content is crown-jewel sensitive.** Archives of personal/business email contain bank statements, legal correspondence, credentials, 2FA recovery codes, health info. Treat the backup target with the same security posture as a password manager vault.
- **REST API for programmatic access.** Bichon exposes a REST API for searching/retrieving emails — useful for building integrations, compliance tooling, or mail-search interfaces. Review API docs on DeepWiki.
- **Project is young.** Discord community, roadmap survey, active development — expect rough edges; review release notes before upgrades.

## Project health

Active Rust development, Docker Hub, Discord, roadmap survey (2026). Maintained by rustmailer team. Growing contributor base.

## Email-archive-family comparison

- **Bichon** — Rust, IMAP sync, full-text search, REST API, WebUI; archive-only (no sending)
- **MailArchiva** — Java, enterprise-grade, complex; full archival compliance features
- **MailHog / Mailpit** — dev-only SMTP catchers; not IMAP archivers
- **Snappymail / Roundcube** — full webmail clients with inbox management; not archive-focused
- **imapbackup / mbsync** — CLI tools; raw maildir sync without indexing or WebUI

**Choose Bichon if:** you want a lightweight, low-dep Rust email archiver with search + REST API, and don't need to send email or manage inbox state.

## Links

- Repo: <https://github.com/rustmailer/bichon>
- Docker Hub: <https://hub.docker.com/r/rustmailer/bichon>
- Docs: <https://deepwiki.com/rustmailer/bichon>
- Discord: <https://discord.gg/Bq4M2cDmF4>
- Snappymail (full webmail alt): <https://snappymail.eu>
