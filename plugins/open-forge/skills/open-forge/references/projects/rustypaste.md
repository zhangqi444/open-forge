---
name: Rustypaste
description: "Minimal self-hosted file upload and pastebin service. Docker or binary. Rust. orhun/rustypaste. curl-based API, URL shortening, one-shot links, expiry, auth, no database, pet-name filenames. MIT."
---

# Rustypaste

**Minimal self-hosted file upload and pastebin service.** Upload files or text via `curl`; get a shareable URL. One-shot links (view once then delete), expiring links, URL shortening, random filename generation (pet names, alphanumeric), no database — files stored directly on the filesystem. Single Rust binary with a TOML config file.

Built + maintained by **orhun (Orhun Parmaksız)**. MIT license.

- Upstream repo: <https://github.com/orhun/rustypaste>
- Docker Hub: <https://hub.docker.com/r/orhunp/rustypaste>
- Crates.io: <https://crates.io/crates/rustypaste>
- Docs: <https://docs.rs/rustypaste/>

## Architecture in one minute

- **Rust** binary — single executable; fast, minimal memory usage
- Config: `config.toml` (TOML format) — hot reload supported
- Storage: filesystem (`./upload/` directory — no database)
- Port **8000**
- Auth: optional HTTP Basic Auth token
- Resource: **tiny** — Rust async; near-zero overhead

## Compatible install methods

| Infra        | Runtime                     | Notes                                         |
| ------------ | --------------------------- | --------------------------------------------- |
| **Docker**   | `orhunp/rustypaste`         | **Primary** — Docker Hub                      |
| **Cargo**    | `cargo install rustypaste`  | From crates.io                                |
| **Arch**     | AUR: `rustypaste`           | Arch Linux                                    |
| **Alpine**   | `apk add rustypaste`        | Alpine Linux (community)                      |
| **FreeBSD**  | ports/packages              | FreeBSD ports                                 |
| **Binary**   | GitHub Releases             | Pre-built binaries                            |

## Inputs to collect

| Input              | Example          | Phase   | Notes                                         |
| ------------------ | ---------------- | ------- | --------------------------------------------- |
| `config.toml`      | see below        | Config  | Mount into container at `/app/config.toml`    |
| Upload dir         | `./upload/`      | Storage | Where uploaded files live; persist this volume |
| Auth token (opt.)  | random string    | Auth    | Protects upload endpoint                      |

## Install via Docker Compose

```yaml
services:
  rustypaste:
    image: orhunp/rustypaste:latest
    container_name: rustypaste
    restart: always
    environment:
      - RUST_LOG=info
    env_file:
      - ./.env          # optional: override config values via env
    ports:
      - "8000:8000"
    volumes:
      - ./upload:/app/upload
      - ./config.toml:/app/config.toml
```

Create `config.toml`:

```toml
[server]
address = "0.0.0.0:8000"

[paste]
random_url = { enabled = true, type = "petname", words = 2 }
default_expiry = "1d"        # optional: expire all pastes after 1 day
# max_content_length = "10MB"

[auth]
tokens = []                  # add tokens here for authentication
# tokens = ["my-secret-token"]
```

Visit `http://localhost:8000`.

## Usage (curl)

```bash
# Upload a file
curl -F "file=@/path/to/file.txt" https://paste.example.com
# → https://paste.example.com/happy-otter.txt

# Upload text inline
echo "hello world" | curl -F "file=@-" https://paste.example.com

# Upload with custom expiry
curl -F "file=@notes.txt" -H "expire=1h" https://paste.example.com

# One-shot link (auto-deletes after first view)
curl -F "oneshot=true" -F "file=@secret.txt" https://paste.example.com

# URL shortening
curl -F "url=https://very-long-url.example.com/path/to/page" https://paste.example.com
# → https://paste.example.com/short-link

# Upload from a remote URL
curl -F "remote=https://example.com/image.png" https://paste.example.com

# With authentication
curl -F "file=@file.txt" -H "Authorization: my-secret-token" https://paste.example.com

# Download with forced download header
curl https://paste.example.com/happy-otter.txt?download=true
```

## Config reference

```toml
[server]
address = "0.0.0.0:8000"

[paste]
# Random filename generation
random_url = { enabled = true, type = "petname", words = 2 }
# type options: "petname" (e.g. happy-otter), "alphanumeric" (e.g. yB84D2Dv)
# or: random_url = { enabled = true, type = "suffix", length = 6 }
# (appends random suffix to original filename: file.MRV5as.txt)

default_expiry = "1d"    # global default expiry
max_content_length = "10MB"
duplicate_files = false  # prevent duplicate uploads (SHA256 check)

[auth]
tokens = ["your-secret-token"]  # leave empty for no auth

[cleanup]
enabled = true
expired_files_dir = "/tmp/rustypaste-expired"
```

## Filename generation modes

| Type | Example | Config |
|------|---------|--------|
| Pet name | `happy-otter.txt` | `type = "petname", words = 2` |
| Alphanumeric | `yB84D2Dv.txt` | `type = "alphanumeric", length = 8` |
| Random suffix | `notes.MRV5as.txt` | `type = "suffix", length = 6` |

## Features overview

| Feature | Details |
|---------|---------|
| File upload | Any file type; auto MIME type detection |
| URL shortening | POST a URL → get short link |
| Remote URL | Paste content from a remote URL |
| Expiring links | `expire` header per upload; or `default_expiry` global |
| One-shot | `oneshot=true` → link works once, then file deleted |
| One-shot URLs | Same for URL shortening |
| Authentication | HTTP Basic Auth tokens |
| No duplicates | Optional SHA256 dedup check |
| List endpoint | `GET /list` — lists all uploaded files (auth required) |
| Delete | `DELETE /file.txt` with auth token |
| Hot reload | Edit `config.toml` → changes apply without restart |
| No database | Files on filesystem; easy to inspect/backup |
| Custom landing page | Replace the default with your own HTML |
| Override filename | `filename` header to set a specific name |

## Gotchas

- **Config file is required.** Unlike most Docker apps, Rustypaste needs a `config.toml` mounted at `/app/config.toml`. Without it, the server won't start. Copy the example from the repo.
- **Hot reload.** The config reloads automatically when `config.toml` changes. No restart needed for most config tweaks. Exceptions: `server.address` changes require a restart.
- **Authentication is per-token, not per-user.** There are no user accounts — just a list of auth tokens. Anyone with a valid token can upload. Use separate tokens for different clients.
- **No web UI.** Rustypaste is a pure API — no upload form by default. It's designed for `curl`/scripts/shareX. There's an HTML form endpoint but it's minimal. Add a custom landing page if you want a friendly UI.
- **Expiry cleanup.** Expired files are moved to `expired_files_dir` (not deleted immediately). Set up a cron job or the built-in cleanup to actually remove them.
- **`?download=true`** forces `Content-Disposition: attachment` — useful for files that browsers would render inline (HTML, SVG, etc.) but you want to offer as a download.
- **Duplicate detection.** When `duplicate_files = false`, Rustypaste computes SHA256 of each upload and returns the existing URL if the file already exists. Good for de-duplication but slightly increases upload latency.
- **ShareX integration.** Rustypaste works well as a ShareX custom uploader. Configure ShareX with the URL, auth header, and response field (`url`).

## Backup

```sh
docker compose stop rustypaste
sudo tar czf rustypaste-$(date +%F).tgz upload/
docker compose start rustypaste
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Project health

Active Rust development, Docker Hub, crates.io, AUR, Alpine, FreeBSD ports, binary releases, hot config reload. Maintained by orhun. MIT license.

## Pastebin-family comparison

- **Rustypaste** — Rust, curl API, one-shot, URL shortening, expiry, no DB, tiny, MIT
- **PrivateBin** — PHP, E2E encrypted, web UI, self-hosted
- **Hemmelig** — Node.js, TweetNaCl client-side encryption, secret sharing focus
- **Hastebin** — Node.js, text only, simple web UI
- **Pastefy** — Java, web UI, syntax highlighting, accounts

**Choose Rustypaste if:** you want a minimal, curl-friendly self-hosted pastebin/file-upload service with one-shot links, URL shortening, expiry, and zero database overhead.

## Links

- Repo: <https://github.com/orhun/rustypaste>
- Docker Hub: <https://hub.docker.com/r/orhunp/rustypaste>
- crates.io: <https://crates.io/crates/rustypaste>
