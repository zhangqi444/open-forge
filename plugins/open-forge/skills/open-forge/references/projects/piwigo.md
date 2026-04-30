---
name: Piwigo
description: "Full-featured open-source photo gallery application for organisations, teams, and individuals. 20+ year history. PHP + MySQL/MariaDB. GPL-2.0. Has a commercial hosted tier at piwigo.com. Strong international localization."
---

# Piwigo

Piwigo is **"the photo gallery that predates Flickr and outlived it"** — a PHP web application for managing + publishing photo galleries, active since 2002. Used by photo clubs, museums, universities, families, hobbyist photographers, tourism boards — anywhere a structured browsable photo archive matters. Piwigo's commercial arm **piwigo.com** funds upstream development (same-author commercial-SaaS model).

Built + maintained by the **Piwigo team** (Pierrick Le Gall + community; French FOSS project ecosystem). **GPL-2.0**. Strong i18n (~60+ languages). Long-run release cadence; currently Piwigo 14+ in 2024+.

Use cases: (a) **family photo archive** with private + public albums (b) **photo club / association** public gallery with upload permissions per member (c) **museum / archive digital collection** with metadata-rich descriptions (d) **wedding / event** photo distribution (e) **professional portfolio** for photographers (f) **replace Flickr / SmugMug** self-hosted.

Features:

- **Albums + sub-albums** — deeply nested categorization
- **Tags + keyword search**
- **EXIF / IPTC metadata** preservation + search
- **Permissions**: private / public; per-user / per-group
- **Multiple users** with role granularity
- **Upload via web / FTP / batch**
- **Plugins + themes** — rich ecosystem, actively maintained
- **Mobile apps** (iOS, Android) via piwigo.com-tied official apps OR community clients
- **RSS feeds** for new photos
- **Multi-size thumbnails** (configurable)
- **Comments + ratings + favorites** (optional)
- **Slideshow mode**
- **i18n**: ~60+ translations
- **GeoTag support** via plugins
- **Export / import** — portable across Piwigo installs

- Upstream repo: <https://github.com/Piwigo/Piwigo>
- Homepage: <https://piwigo.org>
- Hosted SaaS: <https://piwigo.com>
- Docs / Guides: <https://piwigo.org/guides>
- Install guide: <https://piwigo.org/guides/install>
- NetInstall script: <https://piwigo.org/download/dlcounter.php?code=netinstall>
- Latest release: <https://piwigo.org/download/dlcounter.php?code=latest>
- Forums: <https://piwigo.org/forum>
- Plugins: <https://piwigo.org/ext>

## Architecture in one minute

- **PHP 7.4+** (8.x recommended)
- **MySQL 5+ / MariaDB** — metadata (albums, photos, users, tags, comments)
- **ImageMagick (preferred) or PHP GD** — thumbnailing
- **Apache / nginx + PHP-FPM**
- **Resource**: light-moderate — 256-512MB RAM; disk dominated by photos; DB modest
- **Port 80/443**

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| NetInstall         | **PHP script runs on YOUR server → downloads + installs Piwigo** | **Upstream-primary** — guided install                                              |
| Manual tarball     | Download + unzip + configure                                              | Traditional LAMP                                                                           |
| Docker             | Community images: `linuxserver/piwigo`, `lscr.io/linuxserver/piwigo`                   | LSIO-maintained                                                                            |
| Shared hosting     | Works on any PHP/MySQL shared host                                                      | Historic strength                                                                                      |
| piwigo.com (SaaS)  | Upstream commercial-hosted alternative                                                          | For non-self-host users                                                                                |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `photos.example.com`                                        | URL          | TLS required                                                                                    |
| DB                   | MySQL/MariaDB                                                  | DB           | UTF-8mb4                                                                                    |
| Admin user + password | At installer wizard                                                | Bootstrap    | **Strong password**                                                                                    |
| Photo storage path   | `/var/www/piwigo/upload` or `_data/` directory                                            | Storage      | LARGE — plan disk                                                                                                      |
| SMTP (opt)           | For notifications                                                                                | Optional     | Password-reset, comments                                                                                                              |

## Install via Docker (linuxserver.io)

```yaml
services:
  piwigo-db:
    image: mariadb:11
    restart: unless-stopped
    environment:
      MARIADB_DATABASE: piwigo
      MARIADB_USER: piwigo
      MARIADB_PASSWORD: ${DB_PASSWORD}
      MARIADB_ROOT_PASSWORD: ${DB_ROOT_PASSWORD}
    volumes:
      - ./piwigo-db:/var/lib/mysql

  piwigo:
    image: lscr.io/linuxserver/piwigo:latest   # **pin version** in prod
    restart: unless-stopped
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=UTC
    volumes:
      - ./piwigo-config:/config
      - ./piwigo-gallery:/gallery
    ports: ["8080:80"]
    depends_on: [piwigo-db]
```

## First boot

1. Browse `http://host:8080` → installer wizard
2. Configure DB connection
3. Create admin user
4. Upload first photos via web UI or FTP
5. Create albums + configure permissions
6. Install essential plugins (e.g., language pack, EXIF viewer)
7. Configure watermark + copyright defaults if commercial use
8. Put behind TLS reverse proxy
9. Back up DB + photos

## Data & config layout

- `_data/` — cache + some config (in traditional install); `/config` in Docker
- `galleries/` or `_data/i/` — photo storage
- **DB** — all album / photo metadata / user / tag / comment records
- Thumbnail cache (regeneratable)

## Backup

```sh
# DB
docker compose exec piwigo-db mariadb-dump -upiwigo -p${DB_PASSWORD} piwigo > piwigo-$(date +%F).sql

# Config + galleries (photos)
sudo tar czf piwigo-data-$(date +%F).tgz piwigo-config/ piwigo-gallery/
```

Photos are the LARGE part — consider photo-specific offsite backup strategy (S3 Glacier, external HDDs, etc.).

## Upgrade

1. Releases: <https://piwigo.org/download>.
2. Via admin UI: **auto-updater** works for many upgrades.
3. Or replace files manually, let DB migrations run on next login.
4. Plugins + themes: update AFTER core upgrade.
5. Back up FIRST for major versions.

## Gotchas

- **20+-year-old PHP codebase**: mature + battle-tested + some legacy patterns. Piwigo has modernized over the years but expect some old-school PHP conventions in plugin dev. Core app = solid + reliable.
- **Plugin security** (same as Shaarli batch 87, WordPress-class concern): plugins run as PHP code in your server. **Install ONLY from official Piwigo plugin repository + trusted community sources.** Malicious plugin = full server compromise.
- **EXIF privacy**: photo metadata contains GPS coordinates + camera info + sometimes author-identifiable data. Piwigo displays EXIF by default. **Decide your privacy stance + configure** (strip EXIF for public photos, or display it for photography-enthusiast audiences). This is a privacy decision, not a bug.
- **Photo-specific legal risks**:
  - **Copyright** — publishing photos you don't own = infringement risk
  - **Model releases** — publishing identifiable people requires releases in many jurisdictions for commercial use
  - **GDPR** — photos of EU individuals are personal data; have a lawful basis + privacy policy if public
  - **"Right to be forgotten"** — delete-on-request workflow required for EU-user photos
  - **Not a Piwigo-specific problem** — applies to all photo-hosting tools
- **Disk space planning**: photos are LARGE. A family gallery easily grows to 100GB+; a photo club to TB. Plan disk + backup strategy BEFORE importing 20 years of photos.
- **NetInstall security**: NetInstall downloads + executes upstream code on your server. **Always use HTTPS** + verify the installer checksum if available. Same discipline as `curl | bash` (reviewed before running) — `AzuraCast` batch 87.
- **Permission model**: Piwigo's per-album permissions are rich but complex. **Test your privacy config with a secondary test-user account before trusting it with sensitive photos.** "I thought this album was private" is how photo-hosting PR incidents start.
- **Upload permissions**: allowing public uploads = spam + NSFW risk vector. Lock uploads to authenticated users unless your threat model accepts moderation burden.
- **Thumbnailing can be slow** on weak hardware for large uploads. Batch-upload + background regenerate thumbnails overnight if needed.
- **ImageMagick > GD** for quality + format support. GD lacks many formats + has poorer color fidelity.
- **Multi-site SSO**: not built-in; community plugins for LDAP/OAuth exist with varying maturity. Test before committing.
- **Commercial-tier at piwigo.com**: upstream sells hosted Piwigo — same **commercial-tier-funds-upstream** pattern as Rotki (batch 87), Chartbrew (86), AzuraCast (87), many others. Transparent + sustainable. Taxonomy entry: **hosted-SaaS-of-the-open-source-product**.
- **Hub-of-credentials tier = LIGHT**: user passwords + SMTP creds + maybe OAuth-app creds if set. Not extreme; not trivial. **13th tool in hub-of-credentials family, LIGHT variant.**
- **i18n strength** is a quiet asset — if your gallery's audience is non-English-primary, Piwigo's 60+ languages matter.
- **Mobile apps**: official Piwigo apps exist (iOS + Android) + community clients. Upload-from-phone works.
- **Project health**: Pierrick Le Gall long-running + commercial funding via piwigo.com + active community + GPL-2.0 + French FOSS ecosystem. Bus-factor-adjacent-to-1 but commercial-funded. Stable.
- **Alternatives worth knowing:**
  - **Immich** — modern Go-based (actually TypeScript + backend) photo-backup-first alternative; mobile-app-centric; rapidly growing
  - **PhotoPrism** — Go + AI tagging; modern UI; freemium commercial tier
  - **Memories** (batch 88, next recipe) — Nextcloud app; requires Nextcloud
  - **LibrePhotos** — Django + AI; self-hosted Google-Photos-alternative
  - **Chevereto** (commercial+OSS) — image-hosting-focused
  - **Choose Piwigo if:** you want mature + rich-metadata + multi-user permissions + plugins + long-term-support + i18n.
  - **Choose Immich if:** you want modern mobile-upload-first workflow + AI features + active development.
  - **Choose PhotoPrism if:** you want AI-tagging + modern UI + freemium acceptable.

## Links

- Repo: <https://github.com/Piwigo/Piwigo>
- Homepage: <https://piwigo.org>
- SaaS: <https://piwigo.com>
- Guides: <https://piwigo.org/guides>
- Install: <https://piwigo.org/guides/install>
- Plugins/Extensions: <https://piwigo.org/ext>
- Forums: <https://piwigo.org/forum>
- Immich (alt): <https://immich.app>
- PhotoPrism (alt): <https://www.photoprism.app>
- LibrePhotos (alt): <https://github.com/LibrePhotos/librephotos>
- LSIO Docker image: <https://docs.linuxserver.io/images/docker-piwigo>
