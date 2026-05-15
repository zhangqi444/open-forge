---
name: PicoShare
description: "Minimalist self-hosted file-sharing. Direct download links without size/format/encoding restrictions. Go + SQLite + optional Litestream cloud replication. AGPL-3.0. Michael Lynch (mtlynch) sole-maintainer. Active; demo site."
---

# PicoShare

PicoShare is **"imgur / Droplr / Filebin — but self-hosted + no restrictions + no ads"** — a minimalist web app for sharing files via direct download links. No file-size limit, no file-type restriction, no re-encoding/resizing. Upload → get direct link → share. Recipient views or downloads with no ads, no signups. Go single-binary + SQLite + optional **Litestream** replication to any S3-compatible storage (auto-backup + restore on restart).

Built + maintained by **Michael Lynch (mtlynch)** — prolific blogger + OSS developer (TinyPilot KVM, Zestful, others). License: **AGPL-3.0** (explicit). Active; Docker Hub; demo available; CircleCI; commit-activity badges visible.

Use cases: (a) **personal "share a file" tool** — drop file → send link (b) **image-sharing without imgur limits** — no size cap, no re-encoding (c) **music/video-file share** — no SoundCloud/Vimeo re-encoding (d) **embed-anywhere** — direct links work in markdown / emails (e) **ephemeral file drop** for clients/collaborators (f) **backup to S3-via-Litestream** — your data is replicated (g) **no-signup file delivery** — give someone a link; they download (h) **big-file workflows** — >25MB emails, >2GB file services.

Features (per README):

- **Direct download links** — no ads/signups on recipient side
- **No file restrictions** — any size, any type
- **No re-encoding** — bits exactly as uploaded
- **Shared-secret auth** (`PS_SHARED_SECRET`) for uploader side
- **Go single binary + SQLite**
- **Litestream replication** to S3/R2/Spaces for redundancy

- Upstream repo: <https://github.com/mtlynch/picoshare>
- Docker Hub: <https://hub.docker.com/r/mtlynch/picoshare>
- Litestream: <https://litestream.io>
- mtlynch blog: <https://mtlynch.io>

## Architecture in one minute

- **Go** — single binary
- **SQLite** — DB
- **Litestream** (optional) — continuous DB replication to S3-compatible
- **Resource**: very low — 30-80MB RAM
- **Port 4001** default

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **`mtlynch/picoshare`**                                         | **Primary**                                                                        |
| **Docker + Litestream** | **Built-in; just set Litestream env vars**                 | **Highly recommended for prod**                                                                        |
| Source             | `go run cmd/picoshare/main.go`                                  | Dev                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `share.example.com`                                         | URL          | TLS recommended                                                                                    |
| `PS_SHARED_SECRET`   | Upload-auth password                                        | **CRITICAL** | **Anyone with this can upload**                                                                                    |
| Port                 | 4001 default                                                | Network      |                                                                                    |
| Data volume          | `${PWD}/data:/data` for SQLite DB                           | Storage      |                                                                                    |
| Litestream S3 URL    | (optional) bucket + endpoint + keys                         | Backup       | AWS S3 / Backblaze B2 / Cloudflare R2 / Wasabi / etc.                                                                                    |

## Install via Docker + Litestream

```sh
docker run -d \
  --env "PORT=4001" \
  --env "PS_SHARED_SECRET=${PS_SHARED_SECRET}" \
  --env "LITESTREAM_BUCKET=${LITESTREAM_BUCKET}" \
  --env "LITESTREAM_ENDPOINT=${LITESTREAM_ENDPOINT}" \
  --env "LITESTREAM_ACCESS_KEY_ID=${LITESTREAM_ACCESS_KEY_ID}" \
  --env "LITESTREAM_SECRET_ACCESS_KEY=${LITESTREAM_SECRET_ACCESS_KEY}" \
  -p 4001:4001 \
  -v "${PWD}/data:/data" \
  --name picoshare \
  --restart unless-stopped \
  mtlynch/picoshare:1.5.1        # **pin version in prod**
```

## First boot

1. Set `PS_SHARED_SECRET` to a strong value (this is your upload password)
2. Start container
3. Browse `http://host:4001`
4. Enter shared secret → upload a file → verify direct download link
5. (Optional) Configure Litestream — kill container + restart → verify DB restored from S3
6. Put behind TLS reverse proxy (Caddy/nginx/Traefik/GoDoxy 102)
7. Consider rate-limiting at reverse-proxy level

## Data & config layout

- `/data/picoshare.db` — SQLite DB (metadata + blobs-or-references)
- Litestream WAL shipping to S3 (continuous replication)

## Backup

- **Litestream handles this automatically** when configured
- Manual: `cp data/picoshare.db picoshare-$(date +%F).db`

## Upgrade

1. Releases: <https://github.com/mtlynch/picoshare/releases>. Active.
2. Docker: pull + restart; SQLite migrations auto-run
3. Litestream state persists; restart doesn't lose data

## Gotchas

- **SHARED-SECRET AUTH = SINGLE-PASSWORD MODEL**:
  - One shared secret for ALL upload functionality
  - Compromise = anyone can upload + consume your storage
  - **Rotate secret** if leaked
  - **45th tool in immutability-of-secrets family** (PS_SHARED_SECRET; changing = invalidates authenticated sessions)
- **NO RECIPIENT AUTH = PUBLIC LINKS**:
  - Anyone with direct-link can download
  - By design — that's the point of "direct links"
  - **Link-URL-sufficient-entropy MATTERS**: verify PicoShare uses UUID-like IDs (not sequential)
  - Short / guessable URLs = risk of unauthorized access
- **CROWN-JEWEL Tier 2 + PUBLIC-UGC-HOST-ABUSE-CONDUIT-RISK META-FAMILY EXTENDED TO 6 TOOLS**:
  - **META-FAMILY now 6 tools**: Slash + Zipline + Opengist + OxiCloud (100) + FileGator (102) + **PicoShare** (103)
  - PicoShare is more purely-public than FileGator (no multi-user accounts; just shared-secret)
  - Abuse potential: attacker uploads illegal content + shares link widely; your server hosts the content
  - **Mitigation**: strong shared-secret (anti-upload), expiry policies, monitoring, CSAM scanning
  - **70th tool in hub-of-credentials family — Tier 2**
- **NO FILE RESTRICTIONS = MALWARE DISTRIBUTION RISK**:
  - Upload .exe, .apk, .dmg → direct-download link
  - If attacker gains upload access → distribute malware from your domain
  - Your domain reputation at risk
  - **Mitigation**: ClamAV scanning; Content-Disposition: attachment headers force download (prevents drive-by exec); domain-separation (use subdomain for shares)
- **LITESTREAM = SQLITE-LEVEL-REPLICATION INNOVATION**:
  - Litestream replicates SQLite WAL continuously
  - Near-zero-RTO: restart container → Litestream restores from S3 → app resumes
  - **Recipe convention: "Litestream-for-SQLite-replication" positive-signal** — rare + elegant solution
  - **NEW positive-signal convention** — 1st tool explicitly named (PicoShare)
  - Applies to: any SQLite-based tool; Flatnotes 101, Gramps 103 could use Litestream
- **AGPL-3.0 NETWORK-SERVICE-DISCLOSURE**:
  - Self-host PicoShare + expose to public = AGPL-triggered
  - Modifications must be disclosed
  - Recipe convention reinforced (Worklenz/Stoat/Speakr/Basic Memory precedents)
- **NO-RE-ENCODING = FIDELITY + RISK**:
  - Pro: files are bit-exact
  - Con: no sanitization (malicious EXIF, polyglot files, steganographic payloads pass through)
  - Direct-link + no-sanitization = drive-by-download attack potential
- **SMALL RAM FOOTPRINT = HOMELAB-FRIENDLY**:
  - 30-80MB RAM
  - Runs on Pi Zero, old laptops, cheapest VPS
  - Go compiles to static binary → tiny container
- **CROSS-S3-PROVIDER PORTABILITY**:
  - Litestream is S3-compatible: AWS S3, Cloudflare R2, Backblaze B2, DigitalOcean Spaces, MinIO, Wasabi
  - Easy to migrate cloud storage providers
  - **Recipe convention: "S3-API-as-portability-layer" positive-signal**
- **MTLYNCH-MAINTAINER-ECOSYSTEM**:
  - mtlynch also maintains: TinyPilot (KVM-over-IP hardware), Zestful (food-blog tool), logpaste (paste), several others
  - Consistent style: Go + Docker + prolific blogging + transparency
  - **Recipe convention reinforced: "prolific-sole-maintainer-with-coherent-toolset"** (DDNS Updater qdm12 was 1st in sub-tier; **mtlynch is 2nd prolific-solo-maintainer named**)
  - **Sub-tier now 2 tools** — solidifying
- **INSTITUTIONAL-STEWARDSHIP**: mtlynch sole + community + transparent-blog. **56th tool — prolific-sole-maintainer-with-coherent-toolset sub-tier (2nd tool).**
- **TRANSPARENT-MAINTENANCE**: active + Docker + demo-gif + AGPL-explicit + CircleCI + blog-transparency + commit-activity-badges. **64th tool in transparent-maintenance family.**
- **TRANSPARENT-BLOG-FOR-OSS-DEVELOPMENT**:
  - mtlynch.io blog documents his OSS decisions, revenue, tradeoffs
  - Rare level of transparency
  - **Recipe convention: "public-transparency-blog-for-OSS-project" positive-signal**
  - **NEW positive-signal convention** (PicoShare via mtlynch)
- **CROWN-JEWEL downgrade to Tier 2 note**:
  - Despite being public-file-host, PicoShare is "Tier 2" not Tier 1 because: no credential storage, no user data beyond uploaded blobs, limited attack surface
  - **Recipe distinction**: purely-file-host ≠ full-platform
- **FILE-HOST-CATEGORY**:
  - **PicoShare** — minimalist; Go; AGPL
  - **Zipline** (batch 98) — Node; feature-rich
  - **PingVin** — Node + Svelte; shares focus
  - **Transfer.sh** — Go; CLI-upload-focused
  - **0x0.st** / **0x0** — minimal paste+file
  - **Filebin** — Go; similar shape
  - **SendGB** / **WeTransfer-alternatives** (commercial + limited free)
  - **ShareX Custom Uploader** — multiple OSS options
- **ALTERNATIVES WORTH KNOWING:**
  - **Zipline** — if you want more features + ShareX-integration + multi-user
  - **PingVin** — if you want email-recipient + Node
  - **Transfer.sh** — if you want CLI-first workflow
  - **Choose PicoShare if:** you want minimal + Go + Litestream + AGPL + direct-links + single-shared-secret.
  - **Choose Zipline if:** you want multi-user + ShareX.
  - **Choose Transfer.sh if:** you want CLI.
- **PROJECT HEALTH**: active + Litestream-innovation + AGPL + transparent-blog + prolific-maintainer + Docker + demo. STRONG signals.

## Links

- Repo: <https://github.com/mtlynch/picoshare>
- Docker: <https://hub.docker.com/r/mtlynch/picoshare>
- Litestream: <https://litestream.io>
- mtlynch blog: <https://mtlynch.io>
- Zipline (alt, batch 98): <https://github.com/diced/zipline>
- PingVin (alt): <https://github.com/stonith404/pingvin-share>
- Transfer.sh (alt): <https://github.com/dutchcoders/transfer.sh>
- Filebin (alt): <https://github.com/espebra/filebin2>
