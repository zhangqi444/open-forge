---
name: myDrive
description: "Open-source cloud file storage server — self-hosted Google Drive clone. Upload/download files + folders, AES-256 encryption, photo/video gallery, sharing, mobile-friendly. React + Node.js + MongoDB + filesystem/S3. AGPL-3.0."
---

# myDrive

myDrive is **"self-hosted Google Drive"** — an open-source cloud file-storage server with a Google-Drive-style web UI for uploading, browsing, sharing, and previewing files. File metadata (name, owner, folder tree, shares) lives in **MongoDB**; actual file bytes live in your choice of **Amazon S3, S3-compatible (Minio, Wasabi, Backblaze B2), or local filesystem**. **AES-256 encryption** at rest for file content.

Built + maintained by **subnub**. Active development; solo-led. AGPL-3.0. Reasonable feature coverage for personal + small-team use; not pretending to be Nextcloud-scope.

Use cases: (a) personal Google Drive replacement (b) small-team file sharing when Nextcloud feels too heavy (c) photo/video gallery with media preview (d) simple "upload-share-link" workflow.

Features:

- **Upload files** + **upload folders**
- **Download folders as zip** (auto-conversion)
- **Multi-storage backend**: S3, filesystem, (historically also S3-compatible)
- **Photo viewer** + **video viewer** + **media gallery**
- **Auto-generated thumbnails** for photos + videos
- **File sharing** (public/private links)
- **PWA** (Progressive Web App) — install to home screen
- **AES-256 encryption** at rest
- **Service worker** — offline-ish support
- **Mobile-friendly** UI
- **Email verification** on signup
- **JWT (access + refresh tokens)** auth
- **Docker** first-class

- Upstream repo: <https://github.com/subnub/myDrive>
- Homepage: <https://mydrive-storage.com>
- Live demo: per README
- Docker Hub: <https://hub.docker.com/r/subnub/mydrive>

## Architecture in one minute

- **React** frontend
- **Node.js** / Express backend
- **MongoDB** (metadata + GridFS file chunks IF using default DB storage OR just metadata if using S3/FS)
- **Storage backends**: S3-compatible OR local filesystem OR MongoDB (historical)
- **Resource**: 300-500 MB RAM typical; MongoDB footprint scales with metadata; actual file bytes go to chosen backend

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Docker Compose     | **`subnub/mydrive`** + MongoDB + storage backend               | **Upstream-primary**                                                               |
| Bare-metal         | Node 18+ + MongoDB + file storage                                         | Documented; more complex                                                                   |
| Kubernetes         | Standard Docker deploy                                                                              | Community                                                                                                |
| ARM (Pi)           | Supported via ARM Docker images if available; check release                                                         | Varies                                                                                                    |

## Inputs to collect

| Input                    | Example                                                   | Phase        | Notes                                                                    |
| ------------------------ | --------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain                   | `drive.example.com`                                             | URL          | TLS required                                                                                  |
| MongoDB                  | Mongo 4.4+ (or ARM-compat per older notes)                             | DB           | Bundled or external                                                                              |
| Storage backend          | `filesystem` or `s3`                                                    | Storage      | S3 = scale; FS = simpler                                                                                       |
| `FS_DIRECTORY`           | `/data/files` for filesystem backend                                                | Storage      | Persistent volume                                                                                             |
| S3 endpoint + creds      | if `s3` backend                                                                             | Storage      | Endpoint URL, access key, secret, bucket                                                                                                  |
| `PASSWORD_ACCESS`        | JWT access token secret                                                                                  | Secret       | Random 32+ chars; immutable                                                                                                                  |
| `PASSWORD_REFRESH`       | JWT refresh token secret                                                                                             | Secret       | Random 32+ chars; immutable                                                                                                                  |
| `ENCRYPTION_KEY`         | AES-256 encryption key for file-at-rest                                                                                          | Secret       | **CRITICAL — losing = all stored files unreadable**                                                                                                                  |
| SMTP (opt)               | For email verification                                                                                                             | Email        | If enabling email verification                                                                                                                                 |
| `REMEMBER_ME_KEY`        | JWT "remember me" secret                                                                                                                       | Secret       | Random; immutable                                                                                                                                                |
| `URL`                    | Public URL                                                                                                                                               | Config       | Tells myDrive its own URL for links                                                                                                                                              |

## Install via Docker Compose

```yaml
services:
  mydrive:
    image: subnub/mydrive:latest                     # **pin version** in prod
    restart: unless-stopped
    ports: ["3000:3000"]
    volumes:
      - ./mydrive-data:/data
    environment:
      MONGODB_URL: mongodb://mongo:27017/mydrive
      URL: https://drive.example.com
      FS_DIRECTORY: /data/files
      NODE_ENV: production
      PASSWORD_ACCESS: ${JWT_ACCESS_SECRET}
      PASSWORD_REFRESH: ${JWT_REFRESH_SECRET}
      REMEMBER_ME_KEY: ${REMEMBER_ME_SECRET}
      KEY: ${ENCRYPTION_KEY}                          # AES-256 at-rest encryption
      DB_TYPE: fs                                     # or 's3'
    depends_on: [mongo]

  mongo:
    image: mongo:6
    volumes:
      - ./mongo-data:/data/db
```

See <https://github.com/subnub/myDrive#running> for authoritative env var list.

## First boot

1. Generate strong `ENCRYPTION_KEY` + JWT secrets (store in secrets manager)
2. Deploy
3. Sign up (first user is admin)
4. Upload test file → verify persistence + preview
5. Test folder download (zip conversion)
6. Test sharing
7. Put behind TLS
8. Back up MongoDB + storage + secrets
9. Configure SMTP + email verification if wanted

## Data & config layout

- **MongoDB** — users, file metadata, folder tree, share links
- **Filesystem backend**: `FS_DIRECTORY` — encrypted file blobs
- **S3 backend**: your bucket — encrypted objects
- **Env vars** — all secrets + config

## Backup

```sh
# Mongo
mongodump --uri="mongodb://localhost:27017/mydrive" --out=./backup-$(date +%F)/

# Filesystem backend
sudo tar czf mydrive-files-$(date +%F).tgz mydrive-data/files/

# CRITICAL: back up ENCRYPTION_KEY + JWT secrets SEPARATELY to a secure vault
# Without ENCRYPTION_KEY, file contents are unrecoverable.
```

## Upgrade

1. Releases: <https://github.com/subnub/myDrive/releases>. Solo-led cadence.
2. Docker: bump tag; run migrations per release notes.
3. **Back up Mongo + files before major versions.**
4. Some major versions have migration scripts; read the README's "Updating from a previous version of myDrive" section.

## Gotchas

- **`ENCRYPTION_KEY` is THE crown jewel.** AES-256 encrypts file content at rest. **If you lose the key → every file is unreadable. If the key leaks with DB/FS access → every file is decryptable.** Treatment (same as Nexterm batch 81 pattern):
  - Generate with `openssl rand -hex 32`
  - Store in a password manager or secrets vault
  - Back up SEPARATELY from data (if you back up together + lose both, game over)
  - NEVER commit to git
  - Rotation procedure is painful (re-encrypt all files) — plan accordingly
- **Hub-of-personal-files = crown-jewel target.** myDrive holds your files. Hardening like a bastion host:
  - **TLS mandatory** — credentials + file content in transit
  - **MFA/2FA** — check current version; not clear if built-in
  - **Reverse proxy with strong auth or VPN-only access** for sensitive data
  - **Rate-limit login** — credential stuffing is real
  - **Log + monitor** — watch for exfil patterns
- **MongoDB on NFS = bad idea** (officially unsupported, per YourSpotify recipe batch 80). Use local disk.
- **MongoDB on ARM caveat** — older ARM (ARMv7) needs Mongo 4.4, not 5+. Same warning from YourSpotify (batch 80).
- **Solo-maintainer bus factor.** subnub is solo core. Mitigations: (a) AGPL open-source (b) standard MongoDB + Node stack (re-buildable by many) (c) MongoDB dumps + file blobs are extractable (low lock-in IF you keep ENCRYPTION_KEY). Still: don't depend on myDrive for business-critical data without a Plan B. Same bus-factor-1 concern as Papra (81), MicroBin (81), Wakapi (81 maintenance-mode).
- **Feature scope**: upload + browse + share + gallery. NOT: real-time collaboration, document editing, calendar/contacts, end-to-end-encrypted sharing (AES-256 at-rest ≠ E2E — server decrypts to serve previews). Compare to Nextcloud scope if you need more.
- **File sharing via public links** — links grant read access to anyone with the URL. Consider: (a) link expiry (b) password protection on shares (c) download-tracking (d) limit per-file anonymous access. Public-link convenience vs exposure tradeoff.
- **Preview generation (thumbnails)** — server decrypts files to generate thumbs. Means: the server has cleartext access. If you need true zero-knowledge encryption (server never sees cleartext), myDrive is NOT that tool. Use **Cryptomator + any storage** or **Filen** for zero-knowledge.
- **Photo/video gallery** — good for casual use; not a photo-library app. Pair with **Immich** or **PhotoPrism** for dedicated photo management.
- **File-size limits**: Node.js streaming has memory-pressure concerns for very large files. Test your expected max-file-size before production.
- **MongoDB GridFS historical** — some older myDrive versions stored files in Mongo GridFS; current versions prefer filesystem/S3. Don't use Mongo-only storage in production (DB grows huge fast).
- **Email verification** is optional but recommended for public instances (stops bot signups).
- **JWT access + refresh tokens**: short-lived access + long-lived refresh = standard pattern. `PASSWORD_ACCESS` + `PASSWORD_REFRESH` secrets must both be set + both must be immutable.
- **License**: **AGPL-3.0** — self-host free; commercial SaaS = source disclosure.
- **Project health**: solo maintainer; active. Donations + demo site. Bus-factor-1 warning applies (mitigate with regular backups + documented procedures).
- **Alternatives worth knowing:**
  - **Nextcloud** — the incumbent; massive feature set (calendar/contacts/docs/chat); heavier
  - **ownCloud Infinite Scale (ocis)** — Go rewrite; modern
  - **Seafile** — fast file sync; C-based server; less feature-rich UI
  - **Filestash** — multi-backend file browser (FTP/WebDAV/S3/SFTP); not a storage server itself
  - **Pydio Cells** — Go-based; Nextcloud-competitor
  - **OpenCloud** (batch 72) — modern ownCloud-adjacent
  - **FileRun** — commercial Drive-like
  - **Cryptomator** — client-side E2E encryption over any cloud
  - **Immich** (photos) / **PhotoPrism** (photos) — dedicated photo tools
  - **Choose myDrive if:** simple Google-Drive UX + MongoDB stack + AES-256-at-rest + solo/small-team.
  - **Choose Nextcloud if:** want full suite (drive + calendar + contacts + editor) + bigger community.
  - **Choose Seafile if:** want fast sync + dedicated clients.
  - **Choose Cryptomator + S3 if:** want true zero-knowledge client-side encryption.

## Links

- Repo: <https://github.com/subnub/myDrive>
- Homepage: <https://mydrive-storage.com>
- Docker Hub: <https://hub.docker.com/r/subnub/mydrive>
- Releases: <https://github.com/subnub/myDrive/releases>
- Nextcloud (alt): <https://nextcloud.com>
- ownCloud ocis (alt): <https://owncloud.dev/ocis>
- Seafile (alt): <https://www.seafile.com>
- Cryptomator (alt): <https://cryptomator.org>
- OpenCloud (alt — see batch 72 recipe): <https://opencloud.eu>
- Immich (photos): <https://immich.app>
- PhotoPrism (photos): <https://www.photoprism.app>
