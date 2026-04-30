---
name: yarr (yet another rss reader)
description: "Minimalist web-based RSS/Atom feed aggregator + desktop app — single Go binary with embedded SQLite. Fever API for mobile-app compat. MIT. Single-user. Zero-config deploys."
---

# yarr

yarr (*"yet another rss reader"*) is **"the most boring possible self-hosted RSS reader — which is why it works"**. A **single Go binary with an embedded SQLite database**, no external services required, no Docker needed. Drop `yarr` on your machine (or phone-VPS, or Pi, or whatever), run it, point your browser at `localhost:7070`, and you have a feed reader. Also ships as **desktop apps** for macOS / Windows / Linux with tray icons.

Built + maintained by **nkanaev** (solo). **MIT-licensed**. Single-user by design. Minimal by philosophy. No plugins, no social features, no AI — just "here are your unread articles".

Use cases: (a) **homelab Feedly/Inoreader replacement** (b) **desktop RSS app** — native-ish via tray icon (c) **mobile-compatible RSS backend** via **Fever API** — connect Reeder / Fiery Feeds / ReadKit / NetNewsWire etc. to your self-hosted yarr (d) **Raspberry Pi tiny instance** for personal use (e) **zero-maintenance RSS reader** — it just runs.

Features:

- **Single binary** — no runtimes, no DB servers
- **Embedded SQLite** — everything in one file
- **RSS + Atom + JSON Feed** parsing
- **Fever API** — mobile app compat (Reeder, Fiery Feeds, Unread, NetNewsWire, ReadKit)
- **Basic auth** for self-host use
- **TLS flag** — `-cert`, `-key`
- **Desktop GUI builds** — tray icon for macOS/Win/Linux
- **Mark as read / starred**
- **Folders / categories**
- **Full-text extraction** (optional; uses Readability-style)
- **Keyboard shortcuts** — Vim-friendly
- **Search across articles**
- **OPML import / export**

- Upstream repo: <https://github.com/nkanaev/yarr>
- Releases: <https://github.com/nkanaev/yarr/releases>
- Build docs: <https://github.com/nkanaev/yarr/blob/master/doc/build.md>
- Fever API: <https://github.com/nkanaev/yarr/blob/master/doc/fever.md>
- Linux install script: <https://github.com/nkanaev/yarr/blob/master/etc/install-linux.sh>

## Architecture in one minute

- **Go** — single-binary static distribution
- **Embedded SQLite** — one DB file
- **Web UI** (HTML/JS; no heavy framework)
- **Resource**: tiny — 50-100MB RAM, single-digit MB disk for binary
- **Default port**: 7070

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Binary (Linux)     | Unzip `yarr_linux_amd64.zip` → `$HOME/.local/bin/yarr`         | Easiest self-host                                                                          |
| Binary + systemd   | `etc/install-linux.sh` sets up a service                                  | Reboot-safe                                                                                |
| Binary (macOS GUI) | `yarr.app` → `/Applications`                                                       | Menubar app                                                                                            |
| Binary (Windows GUI) | `yarr.exe` → tray icon                                                                          | Taskbar app                                                                                                        |
| Docker             | Community images                                                                                 | Not upstream-primary but works                                                                                                    |
| Build from source  | `make` with Go toolchain                                                                                          | For custom builds                                                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| `-addr`              | `-addr 127.0.0.1:7070` or `0.0.0.0:7070`                    | Network      | Bind address                                                                                    |
| `-auth-file`         | `user:password` file                                                    | Auth         | Basic auth — **mandatory for non-localhost**                                                                                    |
| `-cert` + `-key`     | TLS cert + key                                                                  | TLS          | Native TLS or reverse proxy (usually proxy)                                                                                                           |
| `-db`                | Path to SQLite DB                                                                                      | Storage      | Default: `~/.config/yarr/storage.db`                                                                                                                     |
| Feeds                | OPML import from Feedly / etc.                                                                                                   | Migration    | Import on first use                                                                                                                                     |

## Install (Linux)

```sh
curl -LO https://github.com/nkanaev/yarr/releases/latest/download/yarr_linux_amd64.zip
unzip yarr_linux_amd64.zip -d ~/.local/bin/
~/.local/bin/yarr -addr 127.0.0.1:7070 \
    -auth-file ~/.config/yarr/auth
```

Create `auth` with `echo "user:MyStrongPassword" > ~/.config/yarr/auth`.

Systemd: see `etc/install-linux.sh`.

## First boot

1. Run `yarr -h` → review flags
2. Start yarr → browse `http://host:7070` (or your auth-behind URL)
3. Log in with basic auth
4. Add first feed: URL or discover via homepage
5. OPML import if coming from Feedly/Inoreader
6. Configure refresh schedule (default works)
7. (opt) Connect mobile RSS app via Fever API — see `doc/fever.md`
8. Back up `storage.db`

## Data & config layout

- `~/.config/yarr/storage.db` — SQLite DB with feeds + articles + read-state
- Auth file (plain-text `user:password` per line)
- No other state

## Backup

```sh
sudo cp ~/.config/yarr/storage.db yarr-$(date +%F).db
# OR online snapshot:
sqlite3 ~/.config/yarr/storage.db ".backup yarr-$(date +%F).db"
```

## Upgrade

1. Releases: <https://github.com/nkanaev/yarr/releases>. Slow but steady.
2. Download new binary + replace old.
3. Auto-migrate on boot (schema changes are rare).
4. Back up `storage.db` FIRST.

## Gotchas

- **Single-user by design** — no multi-tenant. If you need multi-user feeds with shared folders: **Miniflux / FreshRSS / Tiny Tiny RSS** (all more featureful).
- **Binary-distribution trust**: you're downloading a binary from GitHub releases. Check the release is signed / verify the maintainer's signature if available. For critical infra, build from source with Go toolchain — the codebase is small + auditable.
- **Basic auth is WEAK** over HTTP — always use TLS (reverse proxy preferred). Basic auth over plain HTTP = password transmitted in base64 cleartext. Same class as Redis Commander (batch 85), every-other-basic-auth-tool. **Put TLS in front always.**
- **No authentication at all unless you pass `-auth-file`.** Easy to accidentally run yarr on `0.0.0.0:7070` without auth = everyone on the network reads + mutates your feed DB. **Always bind localhost + reverse-proxy with auth, OR use `-auth-file`.**
- **Fever API mobile-app pattern** is where yarr shines — native iOS RSS readers (Reeder, Fiery Feeds, Unread) connect to Fever-API-compatible backends. yarr's Fever compat = you get great iOS/Android RSS apps against your self-hosted feed server. Miniflux also supports Fever API; yarr is smaller-footprint alternative.
- **Fever API is a LEGACY API** — Fever was a commercial RSS service that shut down years ago; the community kept the API as a de-facto standard. Most apps still support it. Not a concern but worth knowing the heritage.
- **Desktop app mode** (tray icon builds) is convenient but locks you to one machine. For multi-device: run yarr as server + connect desktop + mobile to same server.
- **OPML import/export** — yarr supports OPML = you can migrate IN + OUT easily. Good lock-in-free design.
- **Full-text extraction** — yarr can fetch full article text (not just RSS summary) for feeds that only publish abstracts. Uses Readability-style extraction. Not always perfect.
- **No cloud sync** — yarr IS the cloud for you. Read-state syncs across devices connected to the same yarr instance.
- **Go binary = trivial to update**: download new binary, restart. No dependency hell.
- **License: MIT** — permissive + friendly. Same family as Rustpad (85), other minimalist ekzhang-style projects (though this is nkanaev). **Permissive-license-as-ecosystem-asset** applies.
- **Project health**: nkanaev solo + slow-cadence + long-running + MIT + simple-codebase. Bus-factor-1 BUT low-complexity codebase + forkable. Low concern.
- **Scaling limits**: single-user + embedded SQLite = fine up to maybe 1000 feeds + 100k articles. Beyond that, Miniflux (Postgres) or FreshRSS (MySQL/Postgres) scale better.
- **Alternatives worth knowing:**
  - **Miniflux** — Go + Postgres; multi-user-capable, more features, MIT — the "next step up" from yarr
  - **FreshRSS** — PHP + MySQL/Postgres; multi-user; mature; many themes
  - **Tiny Tiny RSS (tt-rss)** — PHP; long-running; polarizing community
  - **Commafeed** — Java; multi-user; lower-profile
  - **NewsBlur** — commercial + OSS
  - **Reeder (iOS/Mac)** — commercial desktop/mobile RSS with Fever backend support
  - **Feedly / Inoreader** — commercial SaaS
  - **Choose yarr if:** you want minimal + single-binary + single-user + Fever-API for mobile + MIT.
  - **Choose Miniflux if:** you want slightly-more-featureful + Postgres + multi-user capability.
  - **Choose FreshRSS if:** you want mature multi-user + PHP-hosting-friendly.

## Links

- Repo: <https://github.com/nkanaev/yarr>
- Releases: <https://github.com/nkanaev/yarr/releases>
- Build: <https://github.com/nkanaev/yarr/blob/master/doc/build.md>
- Fever API doc: <https://github.com/nkanaev/yarr/blob/master/doc/fever.md>
- Linux installer: <https://github.com/nkanaev/yarr/blob/master/etc/install-linux.sh>
- Miniflux (alt): <https://miniflux.app>
- FreshRSS (alt): <https://freshrss.org>
- Tiny Tiny RSS (alt): <https://tt-rss.org>
- Reeder (iOS/Mac client, commercial): <https://reederapp.com>
