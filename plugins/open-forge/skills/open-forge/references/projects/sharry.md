---
name: Sharry
description: "Self-hosted resumable file sharing via unique links. Docker. Scala/JVM + PostgreSQL. eikek/sharry. tus protocol, password protection, expiry, alias pages for receiving files, multi-user."
---

# Sharry

**Self-hosted file sharing web app.** Upload files; get a unique URL to share with anyone. Features: resumable uploads via the tus protocol (survives connection drops on large files), optional password protection, configurable download expiry period, and alias pages (let anyone upload files to you via a hard-to-guess URL). Multi-user with authentication.

Built + maintained by **eikek (Eike Kettner)**. GPLv3+ license.

- Upstream repo: <https://github.com/eikek/sharry>
- Docs: <https://eikek.github.io/sharry>
- Quick start: <https://eikek.github.io/sharry/doc/quickstart>
- Docker Hub: `eikek0/sharry`

## Architecture in one minute

- **Scala / JVM** backend + web frontend
- **PostgreSQL** (or H2 for simple installs) database
- Port **9090** (HTTP)
- Config file: `sharry.conf` (HOCON format) — mounted as `/opt/sharry.conf`
- Docker: single `restserver` container + `postgres` container
- Resource: **low-to-medium** — JVM startup; steady-state is lean

## Compatible install methods

| Infra          | Runtime                    | Notes                                                  |
| -------------- | -------------------------- | ------------------------------------------------------ |
| **Docker**     | `eikek0/sharry`            | **Primary** — Docker Hub; needs config file mount      |
| **Deb package**| `.deb` from releases       | For Debian/Ubuntu bare metal; systemd service          |
| **Zip/binary** | `bin/sharry-restserver`    | Unzip + run script; cross-platform JVM                 |
| **Nix**        | nixpkgs + NixOS module     | Nix package manager; NixOS module available            |

## Inputs to collect

| Input                      | Example                            | Phase    | Notes                                                                                  |
| -------------------------- | ---------------------------------- | -------- | -------------------------------------------------------------------------------------- |
| `DB_USER` / `DB_PASSWORD`  | `dbuser` / strong random           | Storage  | PostgreSQL credentials                                                                 |
| `DB_NAME`                  | `sharry`                           | Storage  | PostgreSQL database name                                                               |
| Admin password             | strong random                      | Auth     | Set in `sharry.conf` under `signup.mode` or admin account                             |
| `sharry.conf`              | config file                        | Config   | HOCON config with DB URL, storage path, base URL, auth settings                       |
| Base URL                   | `https://share.example.com`        | Network  | Set in config for correct share link generation                                        |

## Install via Docker Compose

```yaml
services:
  restserver:
    image: eikek0/sharry:v1.15.0
    container_name: sharry
    command: /opt/sharry.conf
    ports:
      - "9090:9090"
    volumes:
      - ./sharry.conf:/opt/sharry.conf
    depends_on:
      db:
        condition: service_healthy

  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: dbuser
      POSTGRES_PASSWORD: changeme
      POSTGRES_DB: sharry
      PGUSER: dbuser
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: pg_isready -q -d sharry
      interval: 15s
      timeout: 5s
      retries: 3

volumes:
  postgres_data:
```

Create `sharry.conf` — minimal example:

```hocon
sharry.server {
  base-url = "http://localhost:9090"
  bind.address = "0.0.0.0"
  jdbc {
    url = "jdbc:postgresql://db:5432/sharry"
    user = "dbuser"
    password = "changeme"
  }
  signup.mode = open   # or "closed" to disable new registrations
}
```

Full config reference: <https://eikek.github.io/sharry/doc/configure>

## First boot

1. Create `sharry.conf` with DB connection + base URL.
2. `docker compose up -d`.
3. Visit `http://localhost:9090` → register the first (admin) user.
4. Set `signup.mode = closed` in config and restart if you don't want open registration.
5. Upload a file → share the generated URL.
6. Set up **alias pages** for receiving files from others (My Aliases → Create).
7. Put behind TLS; update `base-url` in config.

## How sharing works

### Authenticated users → others
1. Log in → Upload files + optional password + expiry period
2. Sharry returns a unique download URL
3. Share the URL (e.g. via email)
4. Anyone with the URL can download (optionally password-protected)
5. File auto-expires after the configured period

### Others → authenticated users (alias pages)
1. User creates an **alias page** (hard-to-guess URL)
2. Anyone with the alias URL can upload files to that user
3. User receives notification (email) when files are uploaded
4. Alias can be disabled or deleted anytime

## tus protocol advantages

- Resumable uploads: connection drops mid-upload → resume from where it left off
- Reliable for large files (video, archives) over flaky connections
- Compatible with tus clients (browser built-in via sharry UI or external tools)

## Gotchas

- **Config file is required.** Unlike most Docker apps, Sharry configuration lives in a HOCON file (`sharry.conf`) — not environment variables. Mount it into the container at `/opt/sharry.conf` and pass it as the Docker `command`.
- **Base URL must be correct.** Share links embed the `base-url` from config. If set to `localhost`, shared links won't work for external recipients. Set it to your public domain.
- **JVM startup time.** Scala/JVM apps take 5–15s to start. The container will show as healthy once HTTP is ready — use the healthcheck.
- **H2 vs PostgreSQL.** H2 (embedded) works for single-user testing but is not recommended for production or multi-user. Use PostgreSQL.
- **Signup mode.** Default may be open registration. After creating your admin account, set `signup.mode = closed` (or `invited`) in config and restart to prevent unwanted signups.
- **File storage location.** Files are stored on disk (path configured in `sharry.conf` under `files.directory`). Ensure this path is on a persistent volume. The default in Docker may be ephemeral.
- **Email notifications for alias pages.** Requires SMTP configuration in `sharry.conf`. Without SMTP, alias page upload notifications don't send.
- **Expiry is hard.** Once a share expires, the files are deleted on next cleanup cycle. There's no undo.

## Backup

```sh
# PostgreSQL dump
docker exec db pg_dump -U dbuser sharry > sharry-$(date +%F).sql
# File storage directory (configure path in sharry.conf)
sudo tar czf sharry-files-$(date +%F).tgz /path/to/sharry/files/
```

## Upgrade

1. Releases: <https://github.com/eikek/sharry/releases>
2. `docker compose pull && docker compose up -d`
3. Sharry handles DB migrations automatically on startup.

## Project health

Active Scala/JVM development, Docker Hub, .deb packages, Nix support, tus protocol, alias pages. Solo-maintained by eikek. GPLv3+.

## File-sharing-family comparison

- **Sharry** — Scala+JVM, PostgreSQL, tus (resumable), alias pages, password + expiry, GPLv3+
- **PsiTransfer** — Node.js, simple S3-compatible, no auth required
- **Pairdrop** — local network WebRTC file drop; no server storage
- **Lufi** — Perl, end-to-end encrypted file sharing
- **FileShelter** — C++, simple, no DB; file-system only
- **Send (Firefox)** — archived; was E2E encrypted file sharing

**Choose Sharry if:** you want a polished self-hosted file-sharing app with resumable tus uploads, alias "receive" pages, password protection, and multi-user support.

## Links

- Repo: <https://github.com/eikek/sharry>
- Docs: <https://eikek.github.io/sharry>
- Config reference: <https://eikek.github.io/sharry/doc/configure>
- Docker Hub: `eikek0/sharry`
