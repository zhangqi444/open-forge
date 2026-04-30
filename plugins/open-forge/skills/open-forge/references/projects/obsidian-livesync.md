---
name: Obsidian LiveSync (Self-hosted)
description: Community plugin for Obsidian that syncs vaults via your own CouchDB, S3-compatible object store, or experimental peer-to-peer WebRTC. End-to-end encryption, handles conflicts, cross-platform. Alternative to Obsidian Sync (the paid first-party offering). MIT.
---

# Obsidian LiveSync (Self-hosted)

This is a community Obsidian plugin (`obsidian-livesync` by `vrtmrz`) that handles syncing your Obsidian vault across devices via **a backend you run** — so Obsidian users who don't want to pay for "Obsidian Sync" (the first-party commercial sync service) can still have real-time sync across desktop + mobile + tablets.

The recipe focuses on **self-hosting the sync backend** that the plugin talks to. The plugin itself you install inside Obsidian from the Community Plugins catalog.

Backend options:

- **CouchDB** (recommended) — real-time bidirectional sync; lowest latency; small VPS OK
- **S3-compatible object storage** (MinIO, Ceph, Cloudflare R2, Backblaze B2, AWS S3) — periodic sync; simpler to host; costs pennies/month on R2
- **WebRTC P2P** (experimental) — no server, direct device-to-device; requires at least one device online
  - **livesync-serverpeer** — pseudo-client on your server to keep data flowing even when devices are offline
  - **webpeer** — web-based pseudo-client

- Plugin repo: <https://github.com/vrtmrz/obsidian-livesync>
- Related projects:
  - `livesync-serverpeer`: <https://github.com/vrtmrz/livesync-serverpeer>
  - `webpeer` (hosted at <https://fancy-syncing.vrtmrz.net/webpeer/>)
- Docs (setup guides):
  - Setup CouchDB on Fly.io: <https://github.com/vrtmrz/obsidian-livesync/blob/main/docs/setup_flyio.md>
  - Setup your own CouchDB: <https://github.com/vrtmrz/obsidian-livesync/blob/main/docs/setup_own_server.md>
  - IBM Cloudant option: <https://github.com/vrtmrz/obsidian-livesync/blob/main/docs/setup_cloudant.md>
  - Quick setup: <https://github.com/vrtmrz/obsidian-livesync/blob/main/docs/quick_setup.md>
- Backup companion plugin (strongly recommended): `diffzip` — <https://github.com/vrtmrz/diffzip>

## Architecture in one minute

### CouchDB mode (recommended)

- **CouchDB** runs on your server; exposes HTTP(S) API
- Obsidian plugin creates a CouchDB database + admin user + client user
- Each device connects to CouchDB; changes stream via Continuous Replication
- CouchDB handles conflict resolution; plugin auto-merges simple conflicts
- **End-to-end encryption** inside the plugin — CouchDB sees ciphertext only (if enabled)
- Port: `5984` (CouchDB default)

### S3 mode

- Plugin periodically uploads diffs to S3 bucket
- Other devices pull diffs on their own schedule
- Cheaper + simpler to host than CouchDB; higher latency (not real-time)
- E2E encrypted in the plugin

### WebRTC P2P (experimental)

- Direct device-to-device via WebRTC
- Uses a signaling server (can be public); optional TURN relay
- No server-side storage; "at least one device must be online to sync"
- Pseudo-peers (livesync-serverpeer, webpeer) fill in the online-ness gap

## Compatible install methods (backend-side)

| Backend           | Infra                                        | Notes                                                                 |
| ----------------- | -------------------------------------------- | --------------------------------------------------------------------- |
| CouchDB on VPS    | Docker / native                               | **Recommended for most users**                                          |
| CouchDB on Fly.io | Fly's Docker service                           | **3-minute setup** per upstream — easiest managed path                    |
| CouchDB on Raspberry Pi | Native install                          | Works; watch security if exposing internet                               |
| IBM Cloudant      | Managed CouchDB-compatible                     | Alternative to Fly.io; free tier exists                                  |
| MinIO / R2 / B2   | Docker MinIO OR hosted R2/B2                   | For S3 mode                                                              |
| WebRTC P2P        | No server OR `livesync-serverpeer` on VPS      | Experimental; simpler but has caveats                                     |

## Inputs to collect

| Input                   | Example                                | Phase     | Notes                                                               |
| ----------------------- | -------------------------------------- | --------- | ------------------------------------------------------------------- |
| CouchDB hostname        | `couch.example.com`                    | DNS       | Must be TLS (HTTPS) for Obsidian mobile to connect                     |
| CouchDB admin user/pw   | strong                                  | Security  | First user; do not share with clients                                    |
| CouchDB client user/pw  | strong; separate from admin              | Security  | Plugin uses this; limited to the sync DB                                   |
| E2E passphrase          | strong memorable phrase                  | Security  | **Client-side encryption**; losing = data loss; upstream can't recover       |
| Database name           | e.g. `obsidian`                          | Storage   | Create in CouchDB                                                            |
| TLS cert                | Let's Encrypt                            | Security  | Required for mobile                                                            |

## Install CouchDB via Docker (self-host)

```yaml
services:
  couchdb:
    image: couchdb:3.4      # pin major; CouchDB 3.x
    container_name: couchdb
    restart: unless-stopped
    ports:
      - "5984:5984"
    environment:
      COUCHDB_USER: admin
      COUCHDB_PASSWORD: <strong>
    volumes:
      - couchdb-data:/opt/couchdb/data
      - couchdb-conf:/opt/couchdb/etc/local.d
      - ./local.ini:/opt/couchdb/etc/local.d/10-livesync.ini:ro

volumes:
  couchdb-data:
  couchdb-conf:
```

Minimal `local.ini` for Obsidian LiveSync:

```ini
[couchdb]
single_node=true
max_document_size = 50000000

[chttpd]
require_valid_user = true
max_http_request_size = 4294967296
enable_cors = true

[chttpd_auth]
require_valid_user = true
authentication_redirect = /_utils/session.html

[cors]
origins = app://obsidian.md, capacitor://localhost, http://localhost
credentials = true
headers = accept, authorization, content-type, origin, referer
methods = GET, PUT, POST, HEAD, DELETE
max_age = 3600
```

**The CORS config is critical** — without it, Obsidian desktop/mobile cannot connect.

## Reverse proxy (TLS — required for mobile)

Put behind nginx/Caddy with Let's Encrypt:

```nginx
server {
    listen 443 ssl http2;
    server_name couch.example.com;

    client_max_body_size 64M;

    location / {
        proxy_pass http://127.0.0.1:5984;
        proxy_redirect off;
        proxy_buffering off;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Or Caddy (simpler):

```
couch.example.com {
    reverse_proxy 127.0.0.1:5984
    request_body {
        max_size 64MB
    }
}
```

## Configure the Obsidian plugin

On each device:

1. **Settings → Community Plugins → Browse → "Self-hosted LiveSync" → Install → Enable**
2. Plugin settings: **Setup wizard**
3. Enter `https://couch.example.com`, client user + password, database name, E2E passphrase
4. **First device**: choose "Fetch everything from local + upload as initial"
5. **Subsequent devices**: choose "Fetch all data from remote" (downloads vault from CouchDB)

## Data & config layout

CouchDB side: single database (e.g., `obsidian`) holds chunks of your encrypted vault. Each note is split into chunks for efficient diff-sync.

Plugin side: vault stored normally on each device as Markdown; plugin writes a small state file in `.obsidian/plugins/obsidian-livesync/`.

## Backup

CouchDB:

```sh
# Full dump via the CouchDB API
curl -u admin:<pw> "http://localhost:5984/obsidian/_all_docs?include_docs=true" > obsidian-$(date +%F).json.bak

# Or volume-level
docker run --rm -v couchdb-data:/src -v "$PWD":/backup alpine \
  tar czf /backup/couchdb-$(date +%F).tgz -C /src .
```

**Critical**: independently back up your Obsidian vault with a normal file-based tool (Git, Syncthing, Borg, rsync, etc.). The upstream README warns explicitly:

> Before installing or upgrading this plug-in, please back up your vault.

Companion plugin **[Differential ZIP Backup (`diffzip`)](https://github.com/vrtmrz/diffzip)** is explicitly recommended.

## Upgrade

- **Plugin**: Settings → Community Plugins → Update. Plugin follows Obsidian plugin update flow.
- **CouchDB**: `docker compose pull && docker compose up -d`. Read [CouchDB release notes](https://docs.couchdb.org/en/stable/whatsnew/) — 3.x series is stable, 4.x will be a breaking change.
- **Back up before every plugin upgrade**. Plugin releases can have schema-migration quirks that need clean restore points.

## Gotchas

- **"Do not enable this plugin alongside another sync solution"** — iCloud, Obsidian Sync (official), Syncthing-pointed-at-`.obsidian`, Dropbox — simultaneously. Race conditions corrupt vault state. Pick one.
- **E2E passphrase loss = data loss**. Your vault chunks in CouchDB are encrypted client-side; no one can recover without the passphrase. Write it down.
- **Back up vault BEFORE install/upgrade.** Upstream README shouts this. A bad plugin config can commit weird state to CouchDB.
- **CouchDB MUST be TLS** for Obsidian mobile. Mobile WebView refuses plaintext HTTP. Use a Let's Encrypt-fronted reverse proxy.
- **CouchDB CORS must allow the Obsidian origins** — `app://obsidian.md`, `capacitor://localhost`, `http://localhost`. Missing any = mobile/desktop can't connect.
- **CouchDB `require_valid_user = true`** + **admin password strong** — otherwise anyone on the internet can reset your DB.
- **Single-document size ~50 MB max** — Obsidian notes rarely hit this, but pasted images embedded as base64 can. Plugin handles chunking.
- **Conflict resolution** is mostly automatic for markdown (line-level merge); rare cases present a conflict picker UI.
- **Fly.io free tier is gone** (upstream notes this) — Fly is still cheap (a few USD/month) but not free. IBM Cloudant free tier is an alternative for very small vaults.
- **S3 mode is simpler to operate** (S3 bucket + creds; no CouchDB to babysit) but higher latency and less "real-time feel."
- **P2P WebRTC** is experimental — great for two-laptop users; worse when devices are rarely on simultaneously. `livesync-serverpeer` or `webpeer` add "always-online relay" at the cost of reintroducing a server.
- **Not compatible with Obsidian's official "Sync" service** (which is their paid first-party offering). Pick one or the other.
- **Plugin is only for Obsidian** — not Logseq, Notion, etc.
- **Mobile battery** — continuous sync is energy-hungry. Plugin has a "periodic" mode for phones if real-time is too draining.
- **Vault with many images** — CouchDB DB can grow large. Consider Obsidian's "Attachment Management" to keep images external.
- **Git-based syncing is a different philosophy** — some users prefer `git` for version history + sync; pair with GitHub/Gitea. Less "LiveSync feel," stronger versioning.
- **MIT license** — permissive.
- **Alternatives worth knowing:**
  - **Obsidian Sync (official, commercial)** — $5/month; simplest; closed-source backend
  - **Syncthing** — file-level sync; reliable but can cause Obsidian to reload mid-type
  - **Remotely Save** — other community plugin; supports WebDAV / S3 / Dropbox / OneDrive / Google Drive
  - **`git` + mobile Git plugin** — versioning + free; manual pushes
  - **iCloud / OneDrive / Dropbox** — works but not atomic; can corrupt `.obsidian` state
  - **NextCloud Files** — WebDAV sync via Remotely Save or Nextcloud app
  - **Logseq + user-chosen sync** — if you're considering switching editors

## Links

- Plugin repo: <https://github.com/vrtmrz/obsidian-livesync>
- Plugin in Obsidian community catalog: search "Self-hosted LiveSync"
- Setup (Fly.io quickstart): <https://github.com/vrtmrz/obsidian-livesync/blob/main/docs/setup_flyio.md>
- Setup own CouchDB: <https://github.com/vrtmrz/obsidian-livesync/blob/main/docs/setup_own_server.md>
- IBM Cloudant setup: <https://github.com/vrtmrz/obsidian-livesync/blob/main/docs/setup_cloudant.md>
- Quick setup: <https://github.com/vrtmrz/obsidian-livesync/blob/main/docs/quick_setup.md>
- Settings reference: <https://github.com/vrtmrz/obsidian-livesync/blob/main/docs/settings.md>
- P2P explanatory article: <https://fancy-syncing.vrtmrz.net/blog/0034-p2p-sync-en.html>
- Companion backup plugin: <https://github.com/vrtmrz/diffzip>
- livesync-serverpeer: <https://github.com/vrtmrz/livesync-serverpeer>
- webpeer hosted instance: <https://fancy-syncing.vrtmrz.net/webpeer/>
- CouchDB docs: <https://docs.couchdb.org/>
- Obsidian: <https://obsidian.md/>
