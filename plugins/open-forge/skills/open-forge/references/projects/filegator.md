---
name: FileGator
description: "Self-hosted PHP multi-user file manager. Web-based CRUD + zip/unzip + chunked upload with resume + multiple storage adapters (local, S3, FTP, DigitalOcean Spaces). MIT license. Active; Patreon-backed; demo site."
---

# FileGator

FileGator is **"a web-based multi-user file manager with chunked resumable uploads + multiple storage backends"** — manage files on your server via browser. Upload/download/copy/move/rename/zip/unzip. Multi-user with roles + per-user home directories. Chunked upload with pause/resume handles huge files regardless of PHP server config. Connects to local disk, S3, FTP, DigitalOcean Spaces via Flysystem adapters. MIT licensed. Stable, low-maintenance.

Built + maintained by **alcalbg (Filip Galetic)** + community + Patreon backers. License: **MIT** (explicit). Active; demo at demo.filegator.io; CI-tested (PHP + Node); Codecov; Docker via community images.

Use cases: (a) **family shared drive via browser** — like Synology File Station but self-host (b) **client file delivery** — upload large files to per-client folder + share download link (c) **team shared storage** with access controls (d) **S3-bucket browsing UI** — sysadmin tool for inspecting buckets (e) **FTP-to-browser migration** — replace aging FTP access with modern web UI (f) **low-resource file server** — PHP runs on everything, from shared hosting to Raspberry Pi (g) **read-only content delivery** — anonymous role for public file downloads.

Features (per README):

- **Multi-user** — admins + users + roles + home folders + permissions
- **All basic file ops** — copy, move, rename, edit, create, delete, preview, zip, unzip, download, upload
- **Multi-file/folder download** (zipped on-the-fly)
- **Chunked upload** — drag&drop, progress bar, pause + resume
- **Large-file support** regardless of PHP config limits (chunking bypasses upload_max_filesize)
- **Storage adapters** — local, S3, FTP, DigitalOcean Spaces (Flysystem-powered)
- **Vue.js frontend**

- Upstream repo: <https://github.com/filegator/filegator>
- Demo: <https://demo.filegator.io>
- Website: <https://filegator.io>
- Patreon: <https://www.patreon.com/alcalbg>
- BACKERS: <https://github.com/filegator/filegator/blob/master/BACKERS.md>

## Architecture in one minute

- **PHP 7+/8+** (Slim framework)
- **Vue.js** frontend
- **Flysystem** — storage-adapter abstraction
- **SQLite / JSON** — user DB (small)
- **Resource**: very low — 100-200MB RAM
- **Port 80/443** via nginx/Apache

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **LAMP/LEMP**      | **Upload files to webroot**                                     | **Primary (PHP-typical)**                                                          |
| Docker             | Community images                                                 | Alternative                                                                                   |
| Shared hosting     | cPanel-style                                                                                 | Easy                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `files.example.com`                                         | URL          | TLS MANDATORY                                                                                    |
| Storage adapter      | local / S3 / FTP / Spaces                                   | Config       |                                                                                    |
| Storage creds        | S3 access key + secret; FTP user/pass                       | **CRITICAL** | Encrypted at-rest ideally                                                                                    |
| Data dir             | Local: `/var/www/filegator/repository/`                     | Storage      |                                                                                    |
| Admin creds          | First-boot / default admin user                                                                                 | Bootstrap    | **CHANGE the default password IMMEDIATELY**                                                                                    |
| Per-user quotas      | Optional                                                                                                      | Policy       |                                                                                                            |

## Install

1. Download release: <https://github.com/filegator/filegator/releases>
2. Extract to webroot
3. Configure web server (nginx/Apache) — docs at filegator.io
4. Configure `configuration.php`:
   - `repository_path` — where files are stored
   - `users_file` — where user DB lives
   - Storage adapter
5. Browse to URL
6. **Log in as default `admin/admin123` — CHANGE PASSWORD IMMEDIATELY**
7. Create additional users + roles
8. Put behind TLS + HTTP auth (for defense-in-depth)

## Data & config layout

- `configuration.php` — all config (storage, users DB path, etc.)
- `repository/` — default local storage
- `private/users.json` — user DB
- `logs/`

## Backup

```sh
sudo tar czf filegator-$(date +%F).tgz repository/ private/
```

## Upgrade

1. Releases: <https://github.com/filegator/filegator/releases>. Active but infrequent (stable).
2. Back up; replace files; preserve config.
3. MIT license; stable API.

## Gotchas

- **DEFAULT CREDS `admin/admin123` = CRITICAL EXPOSURE**:
  - Default admin password is well-known
  - Internet-facing default install = instant takeover
  - **ALWAYS change admin password on first boot** — before exposing to any non-trusted network
  - **9th tool in default-creds-risk class** (after Peppermint 99 8th) — default-creds-risk pattern continues
- **FILE-HOST = HUB-OF-CREDENTIALS TIER 2 + PUBLIC-UGC-RISK**:
  - All uploaded files
  - User credentials (hashed)
  - Storage-adapter credentials (S3/FTP creds in config file — plaintext typically)
  - Admin account = all files access
  - **65th tool in hub-of-credentials family — Tier 2 with file-sensitivity density**
- **PUBLIC-UGC-HOST-ABUSE-CONDUIT-RISK META-FAMILY extended to 5 tools**:
  - **META-FAMILY now 5 tools**: Slash + Zipline + Opengist + OxiCloud (100) + **FileGator** (when open-registration + public-sharing)
  - Mitigation: close registration; admin-approval; per-user quotas; scan uploads (ClamAV); audit
- **S3 / FTP CREDENTIAL STORAGE**:
  - `configuration.php` typically holds S3/FTP creds in plaintext
  - File permissions (600/root-only) = mandatory
  - Consider env-var-based config or secrets-manager integration
  - **Recipe convention: "config-file-with-plaintext-cloud-creds" risk**
- **MULTI-USER WITH PER-USER HOME DIRS**:
  - Home-dir isolation prevents users from seeing each other's files
  - Verify isolation is enforced server-side (not just UI)
  - Permission model: read/write/create/delete per-folder per-user
- **CHUNKED UPLOAD = BYPASSES PHP UPLOAD LIMITS**:
  - Uploading 10GB file through PHP with `upload_max_filesize=10M`? FileGator's chunked upload handles it
  - **Positive feature** for large-file workflows
  - Server-side disk space is the real limit; monitor
- **FLYSYSTEM ADAPTERS**:
  - Flysystem = battle-tested PHP filesystem abstraction
  - Supports many backends; can plug in custom adapters
  - Standard interface = less adapter-specific bugs
- **ZIP/UNZIP = LARGE-FILE ATTACK SURFACE**:
  - Zip-bombs: malicious compressed files explode to massive sizes on extraction
  - **Mitigation**: server-side extraction-size limits; timeout; disk-quota
- **PREVIEW FEATURE**:
  - In-browser preview of files
  - Preview of crafted files may trigger bugs in preview libraries (CVE class)
  - Verify preview is sandboxed or relies on safe formats only
- **PHP VERSION**:
  - FileGator supports PHP 7+/8+
  - **PHP 7 is EOL (since Nov 2022)** — upgrade to PHP 8+ for security
  - **Recipe convention: "PHP-version-EOL-check" callout** — for all PHP tools
  - **NEW recipe convention** — 1st tool named (FileGator)
- **INSTITUTIONAL-STEWARDSHIP**: alcalbg + Patreon-backers + sponsors (LinkPreview, CorrectMe, Interactive32). **51st tool — "sole-maintainer-with-visible-sponsor-support" sub-tier (5th tool)** — now matches pattern of MediaManager/AdventureLog/Viseron/Flatnotes.
  - **Sub-tier now 5 tools** — very solidified
- **TRANSPARENT-MAINTENANCE**: active + demo + CI + Codecov + Patreon + visible backers + BACKERS.md. **58th tool in transparent-maintenance family.**
- **MIT LICENSE**: permissive; commercial re-use allowed; common for infra tools.
- **STABLE BUT SLOW-DEVELOPMENT**:
  - Stable = few breaking changes
  - Mature codebase; not rapidly evolving
  - Suitable for "deploy + forget" use cases
  - If you need cutting-edge features → consider alternatives
- **ALTERNATIVES WORTH KNOWING:**
  - **Filebrowser (filebrowser.org)** — Go; minimal; active
  - **h5ai** — PHP; index-only; no edit
  - **CloudCMD** — Node.js; dual-pane
  - **Nextcloud Files** — if you want full cloud suite
  - **Seafile Files** — fast block-level sync
  - **Pydio Cells** — Go + React; enterprise
  - **Apache webdav-as-file-browser** — basic
  - **Tiny File Manager** (TFM) — PHP; minimal single-file
  - **Choose FileGator if:** you want multi-user + S3/FTP adapters + MIT + PHP.
  - **Choose Filebrowser if:** you want Go + minimalist.
  - **Choose Nextcloud if:** you want full cloud suite.
  - **Choose TFM if:** you want "upload one PHP file" simplicity.
- **PROJECT HEALTH**: stable + demo + CI + sponsors + active issues. Mature-stable signals.

## Links

- Repo: <https://github.com/filegator/filegator>
- Demo: <https://demo.filegator.io>
- Website: <https://filegator.io>
- Patreon: <https://www.patreon.com/alcalbg>
- Filebrowser (alt): <https://filebrowser.org>
- CloudCMD (alt): <https://cloudcmd.io>
- Pydio Cells (alt): <https://pydio.com>
- Nextcloud: <https://nextcloud.com>
- Seafile: <https://www.seafile.com>
- Tiny File Manager (alt): <https://github.com/prasathmani/tinyfilemanager>
- h5ai (alt): <https://larsjung.de/h5ai/>
