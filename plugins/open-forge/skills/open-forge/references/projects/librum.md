---
name: Librum
description: "Cross-platform e-reader + online library sync — read + manage ebooks across Windows/Linux/macOS (iOS/Android coming), sync across devices via self-hostable Librum-Server. 70,000+ free books in-app. Qt 6 native client + .NET server. GPL-3.0."
---

# Librum

Librum is **a modern cross-platform e-reader with personal online library sync** — Windows/Linux/macOS (iOS + Android in development). Unlike Calibre-Web-Automated (batch 72) which is a web UI over a Calibre library, Librum is a **native Qt 6 reader app** paired with a **.NET (ASP.NET Core) backend server** that syncs your library + reading progress + highlights across devices. Ships with access to 70,000+ free public-domain books via built-in bookstore. Self-hostable via **Librum-Server** (the backend component) for full data sovereignty.

Developed by **David Lazarescu** and the Librum-Reader team. Active, polished UI; strong focus on "just works for normal readers."

**Architecture model:**
- **Librum** — native client (this repo; Qt 6)
- **Librum-Server** — the sync backend (separate repo; <https://github.com/Librum-Reader/Librum-Server>)
- **Librumreader.com** — hosted instance of the server (free tier + donations)

Features:

- **Cross-platform native reader** — Windows, macOS, Linux (iOS + Android "coming soon")
- **Wide format support** — PDF, EPUB, CBZ (comics), FB2, TIFF, MOBI, XPS, images
- **Online library sync** — books + reading positions + highlights synced across devices
- **70,000+ free books** — in-app public-domain bookstore
- **Book management** — collections, tags, sort
- **Highlighting + bookmarking + text search**
- **Customization** — fonts, colors, themes
- **Metadata editing**
- **Coming soon** — note-taking, TTS, reading statistics

- Upstream client repo: <https://github.com/Librum-Reader/Librum>
- Upstream server repo: <https://github.com/Librum-Reader/Librum-Server>
- Website: <https://librumreader.com>
- Wiki: <https://github.com/Librum-Reader/Librum/wiki>
- Contact: `contact@librumreader.com`
- Donate: <https://librumreader.com/contribute/donate>

## Architecture in one minute

- **Client**: Qt 6 + QML native app (C++)
- **Server (Librum-Server)**: ASP.NET Core (.NET 6+) + PostgreSQL + object storage (S3-compatible or filesystem)
- **Client talks to server** via REST API
- **Books + highlights synced** on server; progress updates pushed on open/close
- **Self-hosting**: run Librum-Server; configure client to point at your server URL instead of librumreader.com's managed instance
- **Resource**: server ~300-500 MB RAM; client depends on OS + book size

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Client**         | Native installer from <https://librumreader.com>                   | Desktop — Windows, macOS, Linux                                                    |
| Client build       | Source from repo (Qt 6.5 + cmake + g++)                                    | For advanced users                                                                         |
| **Server self-host** | Docker (check Librum-Server README for current image)                                  | Required for full self-sovereignty                                                                     |
| Server bare-metal  | .NET runtime + PostgreSQL                                                                     | Works                                                                                                   |
| Mobile             | Coming soon (iOS + Android per README)                                                                          | Not yet stable                                                                                                              |

## Inputs to collect

| Input                | Example                                          | Phase        | Notes                                                                    |
| -------------------- | ------------------------------------------------ | ------------ | ------------------------------------------------------------------------ |
| Server URL           | `https://books.home.lan:5001`                        | Sync         | For client config                                                                |
| Client config        | `~/.config/Librum-Reader/Librum.conf` (Linux)                    | Client       | Set `selfHosted=true` + `serverHost=...`                                                 |
| PostgreSQL           | managed or self-run                                              | Server       | Librum-Server requires Postgres                                                                          |
| Object storage       | Filesystem or S3-compatible (MinIO, Backblaze B2, S3)                            | Server       | For book files                                                                                           |
| Admin account        | first-run                                                                        | Bootstrap    | Strong password                                                                                                          |
| TLS cert             | Let's Encrypt via reverse proxy                                                                | Transport    | Client expects HTTPS in production                                                                                                       |

## Install client (desktop)

1. Download from <https://librumreader.com>
2. Install, launch once (generates config)
3. Create account or configure self-hosted (see below)

## Configure client for self-hosted server

After first launch, edit config file and set `selfHosted=true` + point at your server:

**Linux:** `~/.config/Librum-Reader/Librum.conf`

```ini
[General]
selfHosted=true
serverHost=https://books.home.lan:5001
```

**Windows:** Registry → `HKEY_CURRENT_USER\Software\Librum-Reader\Librum` → set `selfHosted=true` + `serverHost`

**macOS:** `~/Library/Preferences/com.Librum-Reader.Librum.plist`

## Install server (Librum-Server)

Follow <https://github.com/Librum-Reader/Librum-Server#self-hosting>. Typical Docker Compose includes Librum-Server + PostgreSQL + reverse proxy for TLS.

## First boot (server)

1. Start server → verify `/health` or similar endpoint
2. Register first user via API / seed script (per Librum-Server docs)
3. Configure client (see above) to point at URL
4. Sign in from client → upload test book → verify sync across two devices (install client on second machine, same server)
5. Configure storage backend (filesystem or S3) for book files
6. Put behind TLS reverse proxy (mandatory — client expects HTTPS)
7. Back up Postgres + book storage

## Data & config layout (server)

- **PostgreSQL** — users, library metadata, highlights, positions
- **Object storage** — book files (EPUB/PDF/etc.)
- **Config** — per Librum-Server env vars

## Backup

```sh
# PostgreSQL dump
pg_dump -U librum -d librum > librum-$(date +%F).sql
# Book storage
sudo tar czf librum-books-$(date +%F).tgz /var/lib/librum/books/    # or S3 sync
```

Users' highlights + notes live in Postgres — DB backup is critical.

## Upgrade

1. Releases (both repos):
   - Client: <https://github.com/Librum-Reader/Librum/releases>
   - Server: <https://github.com/Librum-Reader/Librum-Server/releases>
2. **Back up Postgres + book storage first.**
3. Server before client generally — client handles version skew more gracefully.
4. Client updates via bundled auto-updater on desktop (check prefs).

## Gotchas

- **Two repos, one system**: Librum (client) + Librum-Server (backend). For self-hosting, you need both. Don't confuse client-only install with full self-hosting.
- **Self-hosting is advanced path**: the default (and easiest) is using librumreader.com's managed instance. Self-hosted = more work but full data sovereignty.
- **Client config is per-user + per-machine**: each device needs `selfHosted=true` + server URL set. Writing to registry (Windows) or plist (macOS) or conf (Linux). No mobile sync of this setting.
- **Mobile "coming soon"**: iOS + Android are aspirational as of README snapshot. If mobile is critical, evaluate current state before committing; Calibre-Web-Automated (batch 72) + KOReader works today for mobile reading.
- **Client must talk TLS to server**: modern Qt HTTP stacks refuse plaintext to non-localhost. Use Let's Encrypt or internal CA + trust it on clients.
- **70,000 free books = public domain**: safe to use + distribute. Don't confuse this with arbitrary copyrighted content — Librum doesn't pirate; it's a curated public-domain bookstore.
- **Self-hosted server = your legal responsibility** for any books you upload. Don't upload copyrighted material and then share server access broadly.
- **PostgreSQL dependency**: server requires Postgres. Plan DB backup + upgrade separately. SQLite is not an option for server.
- **Format coverage comparison**:
  - Librum: PDF, EPUB, CBZ, FB2, TIFF, MOBI, XPS
  - Calibre-Web-Automated: everything Calibre handles
  - KOReader: everything Calibre handles + e-ink optimization
  - Librum is strong on format breadth for a native reader
- **Sync conflicts**: what happens if you read the same book offline on two devices? Docs not fully clear; test before relying on offline-heavy workflows.
- **Book library structure on server**: object-storage-keyed; don't hand-edit on filesystem — use API.
- **Not an e-reader device client**: Librum is desktop-first. If you want to read on a Kindle/Kobo/Boox device, pair with Calibre + send-to-device or use KOReader directly.
- **Not an audiobook player**: focused on text-based ebooks. For audiobooks use Audiobookshelf.
- **License**: **GPL-3.0** (both client + server).
- **Sustainability**: team-developed, donation-funded, active — but verify current project health before major commitment. Donation model means future depends on community support. (Bus-factor concerns less than single-dev projects like batch 70 Duplicacy or batch 73 TaxHacker.)
- **Alternatives worth knowing:**
  - **Calibre-Web-Automated** (batch 72) — web UI over Calibre library; more automation features
  - **Calibre** — native desktop; DIY sync; no built-in cross-device
  - **Kavita** — modern web-based reader + library (comics + ebooks)
  - **Komga** (batch 66) — comics-first
  - **Readest** (similar-era native cross-platform reader)
  - **KOReader** — e-ink-optimized open-source reader for Kindles/Kobos/Boox
  - **Moon+ Reader / ReadEra** — mobile-first readers (commercial)
  - **Apple Books / Google Play Books / Kindle** — walled gardens
  - **Choose Librum if:** you want a native desktop reader + self-hostable sync + polished UX + donation-model OSS.
  - **Choose CWA + KOReader if:** web UI + e-ink device + wider automation.
  - **Choose Kavita if:** browser-only + modern UI + mixed comics/ebooks.

## Links

- Client repo: <https://github.com/Librum-Reader/Librum>
- Server repo: <https://github.com/Librum-Reader/Librum-Server>
- Website: <https://librumreader.com>
- Wiki: <https://github.com/Librum-Reader/Librum/wiki>
- Self-hosting docs: <https://github.com/Librum-Reader/Librum-Server#self-hosting>
- Downloads: <https://librumreader.com/download>
- Donate: <https://librumreader.com/contribute/donate>
- Qt: <https://www.qt.io>
- KOReader (alt mobile/e-ink): <https://koreader.rocks>
- Kavita (alt web): <https://www.kavitareader.com>
- Calibre-Web-Automated (batch 72): <https://github.com/crocodilestick/Calibre-Web-Automated>
