---
name: OxiCloud
description: "Rust-based self-hosted cloud suite: files, WebDAV, CalDAV, CardDAV, OIDC/SSO, shares, quotas. Nextcloud-lite philosophy — fast + standards-first + no PHP. Postgres + Rust. MIT. Docker/Helm/Nix modules. Active."
---

# OxiCloud

OxiCloud is **"Nextcloud — but Rust + standards-first + no PHP"** — a self-hosted cloud that aims for the useful 80% of Nextcloud's features (files, calendar, contacts, office editing) without the operational weight of a PHP stack. Emphasis on standard protocols (WebDAV, CalDAV, CardDAV) so any compliant desktop/mobile client works without custom sync tooling. Modern auth (OIDC/SSO), quotas, roles, shared links. Docker Compose + Helm chart + Nix module.

Built + maintained by **DioCrafts (Atalaya Labs)** + community. License: **MIT** (explicitly). Active; rising-star; GitHub Pages docs; CI-tested; Docker Hub image; issue templates; feature-request workflow.

Use cases: (a) **homelab cloud** — lightweight vs Nextcloud (b) **small team shared-drive** with WebDAV desktop mounting (c) **calendar + contact sync** — self-hosted CalDAV/CardDAV without running Baikal separately (d) **privacy-first cloud** — no telemetry + standard-protocols means you're not locked in (e) **Rust-ecosystem-aligned shops** — prefer Rust's memory safety + performance profile (f) **NAS-appliance cloud** — low-resource footprint fits on QNAP/Synology/TrueNAS (g) **Nextcloud-frustrated** users (Nextcloud has accumulated complexity over years; OxiCloud is greenfield).

Features (per README):

- **WebDAV + CalDAV + CardDAV** built-in
- **Files, previews, sharing, trash, search, favorites, recent**
- **OIDC/SSO**
- **Quotas + roles + shared links**
- **Native desktop + mobile clients** work via standards
- **Docker Compose + env-based config + Helm chart + Nix module**

- Upstream repo: <https://github.com/DioCrafts/OxiCloud>
- Docs: <https://diocrafts.github.io/OxiCloud/>
- Docker Hub: <https://hub.docker.com/r/diocrafts/oxicloud>
- MIT license

## Architecture in one minute

- **Rust 1.93+** — single-binary-ish backend + HTML/JS frontend
- **PostgreSQL** — DB
- **File storage** — local filesystem (extensible)
- **Resource**: low — 100-300MB RAM (Rust-typical)
- **Port 8086** default

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker Compose** | **Upstream-primary**                                            | **Primary**                                                                        |
| Helm               | Chart available                                                 | Kubernetes                                                                                   |
| Nix module         | Available                                                       | NixOS                                                                                   |
| Build from source  | Rust 1.93+ + Postgres                                                            | DIY                                                                                               |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `cloud.example.com`                                         | URL          | TLS required                                                                                    |
| `OXICLOUD_BASE_URL`  | Public URL                                                  | Config       | **MUST BE SET BEFORE FIRST LOGIN** (otherwise OIDC/sharing breaks)                                                                                    |
| DB                   | PostgreSQL                                                  | DB           |                                                                                    |
| OIDC provider (optional) | Keycloak / Authelia / Authentik etc.                    | SSO          |                                                                                    |
| Storage dir          | File storage volume (can be LARGE)                                                                           | Storage      | Plan for TBs                                                                                    |
| Admin creds          | First-boot signup                                                                                 | Bootstrap    | Strong                                                                                    |

## Install via Docker

```sh
git clone https://github.com/DioCrafts/OxiCloud.git
cd OxiCloud
cp example.env .env
# Edit .env: set OXICLOUD_BASE_URL, DB credentials, admin password
docker compose up -d
# Browse http://localhost:8086
```

## First boot

1. **Set `OXICLOUD_BASE_URL` in `.env` BEFORE first login** (critical — reverse-proxy URL)
2. Start → browse the base URL
3. Register admin
4. Configure OIDC (optional)
5. Create first user + quota
6. Mount WebDAV in a desktop client; verify file sync
7. Connect CalDAV/CardDAV in phone calendar + contacts app
8. Put behind TLS reverse proxy
9. Back up DB + storage volume

## Data & config layout

- PostgreSQL — metadata, shares, users, sessions
- Storage volume — actual user files
- `.env` — all config

## Backup

```sh
docker compose exec postgres pg_dump -U oxicloud oxicloud > oxicloud-$(date +%F).sql
sudo tar czf oxicloud-files-$(date +%F).tgz storage/
```

## Upgrade

1. Releases: <https://github.com/diocrafts/OxiCloud/releases>. Active; rising.
2. Docker: pull + restart; migrations likely auto-run (verify).
3. Pre-1.0 likely — test upgrades in staging + back up.

## Gotchas

- **RUST-WRITTEN-CLOUD CATEGORY (emerging, niche)**:
  - OxiCloud is in early adopter-phase of a small Rust-cloud category
  - Competitors/peers: **Filestash** (Go + Rust components), **Seafile** (C + Python), **Flarum** (PHP/forum — off-category), **Pimalion** (doesn't exist)
  - **Recipe convention: "Rust-self-hosted-cloud" category — 1st tool named (OxiCloud)**
- **NEXTCLOUD-COMPARISON (the elephant)**:
  - **Nextcloud**: PHP, huge plugin ecosystem, 200k+ installations, large community, slow for some use cases, complex config
  - **OxiCloud**: Rust, lean, standards-first, new, less-feature-rich, fewer integrations
  - **When to choose OxiCloud**: you want minimalism + Rust + standards-over-plugins
  - **When to choose Nextcloud**: you want plugins (Talk, Groupware, Office, Phone-Sync-with-Nextcloud)
  - **When to choose OwnCloud Infinite Scale (oCIS)**: Go-based Nextcloud-alternative by oCIS/OwnCloud team; enterprise-scale
- **STANDARDS-FIRST PHILOSOPHY = ANTI-VENDOR-LOCK**:
  - WebDAV/CalDAV/CardDAV = standard protocols
  - Any compliant client works (no vendor-specific sync tool needed)
  - **Migration story**: if OxiCloud disappears, users keep their data + can migrate to any other WebDAV/CalDAV/CardDAV server
  - **Recipe convention: "standards-first-vendor-lock-mitigation" signal** — positive signal worth noting
- **HUB-OF-CREDENTIALS TIER 2 + FILE-HOST-RISK**:
  - All user files (highly-sensitive possibly — tax docs, medical, work-confidential, photos)
  - WebDAV credentials for every connected client
  - OIDC client secrets
  - Shared-link tokens (compromise = data exfil)
  - Admin account = everyone's files access
  - **57th tool in hub-of-credentials family — Tier 2 with HIGH file-sensitivity density.**
- **BASE-URL IMMUTABILITY**:
  - `OXICLOUD_BASE_URL` must be set correctly BEFORE first login
  - Changing it post-setup breaks OIDC redirects, shared links, client-stored sync URLs
  - **Recipe convention**: base-URL-immutability is a common pattern in self-hosted-cloud tools (Nextcloud has same issue)
  - **NEW: "base-URL-immutability" sub-convention** under immutability-of-secrets family (though not exactly a secret; operational-URL-immutability)
- **PRE-1.0 STATUS**: expect breaking changes + bugs; back up before every upgrade.
- **SHARED LINKS = DATA EXFIL RISK**:
  - Public shared-links leak to anyone with URL
  - **Recipe convention**: audit shared-links regularly; use password-protected + expiring shares; log share creation
- **PUBLIC-UGC-HOST-ABUSE-CONDUIT-RISK META-FAMILY OVERLAP**:
  - OxiCloud with open-registration + public-sharing = can be abused for illegal-content hosting
  - **Same category as Zipline 98 + Opengist 98 + Slash 97**
  - **Meta-family extended**: Slash + Zipline + Opengist + **OxiCloud** = 4 tools when open-registration + public-sharing enabled
  - **Mitigation**: close registration, require admin approval, scan uploaded files (ClamAV), audit + honeypot for CSAM via PhotoDNA
  - OxiCloud is primarily PRIVATE cloud (closed signup is default); abuse-conduit risk much lower than public-paste tools
- **RUST MEMORY-SAFETY BENEFIT**: fewer buffer-overflow + use-after-free vulnerabilities than PHP/C equivalents. Nextcloud has had multiple RCE CVEs over years; Rust's memory safety reduces this class of bugs (but not logic bugs).
- **MIT LICENSE = PERMISSIVE**:
  - Unlike Nextcloud (AGPL), OxiCloud is MIT
  - **Allows commercial re-hosting without source disclosure**
  - Could enable closed-source forks / commercial SaaS built on OxiCloud without sharing back
  - Trade-off: MIT = attract commercial contributors; AGPL = protect open ecosystem
- **TRANSPARENT-MAINTENANCE**: active + docs + CI + Docker + Helm + Nix + badges + release-cadence-visible. **49th tool in transparent-maintenance family.**
- **INSTITUTIONAL-STEWARDSHIP**: DioCrafts / AtalayaLabs + community. **42nd tool in institutional-stewardship — sole-maintainer-with-community sub-tier (23rd tool in that class).**
- **ALTERNATIVES WORTH KNOWING:**
  - **Nextcloud** — huge ecosystem; PHP; mature; AGPL
  - **OwnCloud Infinite Scale (oCIS)** — Go-based; enterprise-scale
  - **Seafile** — C + Python; block-level sync; fast for sync; MIT
  - **Filebrowser** — minimal file browser; Go; MIT
  - **Pydio Cells** — Go + React; enterprise-focus
  - **FileRun** — PHP; commercial
  - **Baikal** (batch 98) — CalDAV/CardDAV-only; no files
  - **Radicale** — CalDAV/CardDAV-only; Python
  - **Syncthing** — peer-to-peer file sync (not cloud)
  - **Choose OxiCloud if:** you want Rust + lean + standards-first + self-host + small-team.
  - **Choose Nextcloud if:** you want huge ecosystem + plugins + mature.
  - **Choose Seafile if:** you want fast block-sync + proven for large files.
  - **Choose Baikal/Radicale if:** you only need CalDAV/CardDAV (no files).
- **PROJECT HEALTH**: active + multi-runtime-packaging (Docker/Helm/Nix) + docs + rising-star + clear-niche. Strong rising-star signals.

## Links

- Repo: <https://github.com/DioCrafts/OxiCloud>
- Docs: <https://diocrafts.github.io/OxiCloud/>
- Docker: <https://hub.docker.com/r/diocrafts/oxicloud>
- Nextcloud (alt): <https://nextcloud.com>
- OwnCloud Infinite Scale (alt): <https://owncloud.dev/ocis/>
- Seafile (alt): <https://www.seafile.com>
- Pydio Cells (alt): <https://pydio.com>
- Filebrowser (alt minimal): <https://filebrowser.org>
- Baikal (batch 98): <https://github.com/sabre-io/Baikal>
- Radicale: <https://radicale.org>
- Syncthing: <https://syncthing.net>
