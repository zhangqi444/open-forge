---
name: Lychee
description: "Open-source self-hosted photo management — upload, organize, share photos via native-feeling web UI. Albums, tags, search, map view, public/private sharing. Laravel (PHP). MIT. Supporter Edition adds advanced features."
---

# Lychee

Lychee is **"a stunning and user-friendly photo-management system"** — a self-hosted web app for uploading + organizing + sharing photos. Fast; beautiful UI; installs in a few minutes on any PHP host. Runs from a Raspberry Pi to a VPS.

Built + maintained by **LycheeOrg** (community organization; not a corporate entity). MIT-licensed core. **Supporter Edition (SE)** is a paid commercial variant with additional features; funds upstream development. **Core is fully capable** — SE is for power users.

**v7 upgrade notice**: Version 7.0 introduces significant Docker image changes. Upgrading from v6 requires reading the upgrade guide. Don't blindly bump tags.

Features (core):

- **Upload** single photos or entire folders
- **Albums + sub-albums** (nesting)
- **Tags + search + filters**
- **Public / private / password-protected albums**
- **Share links** with optional password + expiry
- **EXIF + IPTC metadata** extraction
- **Map view** — photos with GPS coordinates on a map
- **Responsive UI** — mobile-friendly
- **Multiple import methods**: web upload, dropbox, URL import, S3, FTP sync
- **Self-hosted** — your photos stay on your server
- **Storage**: local filesystem or S3-compatible
- **Thumbnails + medium/large sized variants** — auto-generated

Supporter Edition (paid) adds: advanced photo editing, batch operations, more sharing options, additional themes, AI-assisted features per upstream.

- Upstream repo: <https://github.com/LycheeOrg/Lychee>
- Homepage: <https://lycheeorg.dev>
- Docs: <https://lycheeorg.dev/docs/>
- Releases: <https://github.com/LycheeOrg/Lychee/releases>
- Get SE: <https://lycheeorg.dev/get-supporter-edition>
- Upgrade guide: <https://lycheeorg.dev/docs/upgrade.html>
- GHCR: `ghcr.io/lycheeorg/lychee`
- Discord: in docs
- Sponsor: <https://github.com/sponsors/LycheeOrg>
- OpenSSF Scorecard: <https://securityscorecards.dev/viewer/?uri=github.com/LycheeOrg/Lychee>
- CII Best Practices: <https://bestpractices.coreinfrastructure.org/projects/2855>

## Architecture in one minute

- **Laravel (PHP 8.4+)** backend + Vue-based frontend
- **DB**: MySQL / MariaDB / Postgres / SQLite
- **Storage**: local filesystem OR S3-compatible
- **Queue worker**: separate process for background jobs (thumbnails, uploads)
- **Resource**: modest — 300-500MB RAM for core; queue worker adds ~100MB; scales with library

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Docker             | **`ghcr.io/lycheeorg/lychee`** + MySQL + worker container      | **Upstream-recommended**; v7 changed image layout                                  |
| Docker Compose     | Official `docker-compose.minimal.yaml`                                     | Bundled DB + worker                                                                        |
| Shared hosting     | Yes — upload to PHP host                                                               | Rare for feature-rich tool (cousin of FreeScout / Easy!Appointments pattern)                                                                   |
| Bare-metal         | Standard Laravel deploy                                                                                     | Composer + Artisan                                                                                                    |
| Kubernetes         | Standard Docker deploy                                                                                                                 | Works                                                                                                                                                                |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `photos.example.com`                                            | URL          | TLS required                                                                                     |
| `APP_URL`            | same as above                                                           | Config       | Laravel-standard — tells app its own URL                                                                                  |
| `APP_KEY`            | `base64:$(openssl rand -base64 32)`                                                          | Secret       | **Immutable once set** — rotating breaks encrypted DB fields                                                     |
| DB                   | MySQL 8.0 / MariaDB / PG / SQLite                                                       | DB           | MySQL upstream default                                                                                              |
| Storage              | local or S3                                                                                 | Storage      | Large libraries → S3 makes sense                                                                                              |
| Admin user           | first-run via installer                                                                                         | Bootstrap    |                                                                                                                 |
| Queue worker         | `php artisan queue:work` as systemd/supervisor                                                                                        | Background   | **Required** — thumbnail generation + uploads queue here                                                                                                 |

## Install via Docker Compose (quick)

```sh
curl -O https://raw.githubusercontent.com/LycheeOrg/Lychee/master/docker-compose.minimal.yaml
docker compose -f docker-compose.minimal.yaml up -d
```

Or fuller:

```yaml
services:
  lychee:
    image: ghcr.io/lycheeorg/lychee:7                # **pin major version** — v7 breaking
    ports: ["8000:8000"]
    volumes:
      - ./lychee/uploads:/app/public/uploads
      - ./lychee/logs:/app/storage/logs
      - ./lychee/tmp:/app/storage/tmp
    environment:
      APP_URL: https://photos.example.com
      APP_KEY: ${APP_KEY}
      DB_CONNECTION: mysql
      DB_HOST: lychee_db
      DB_DATABASE: lychee
      DB_USERNAME: lychee
      DB_PASSWORD: ${DB_PASSWORD}
    depends_on: [lychee_db]
  lychee_db:
    image: mariadb:11
    environment:
      MARIADB_DATABASE: lychee
      MARIADB_USER: lychee
      MARIADB_PASSWORD: ${DB_PASSWORD}
      MARIADB_RANDOM_ROOT_PASSWORD: "true"
    volumes: [db_data:/var/lib/mysql]

volumes:
  db_data:
```

See upstream docker-compose.yaml for separate worker container pattern.

## First boot

1. Generate `APP_KEY`: `echo "base64:$(openssl rand -base64 32)"`
2. Deploy with `APP_KEY` set
3. Browse → installer creates admin user
4. Upload a test photo → verify thumbnail generation (queue worker must be running)
5. Create albums + test sharing (public, private, password-protected)
6. Configure external storage if using S3
7. Put behind TLS
8. Back up DB + uploads volume
9. (opt) Sign up for SE if you want advanced features

## Data & config layout

- **DB** — photo metadata, users, albums, shares, tags
- **`uploads/`** — originals + thumbnails + medium/large variants
- **`.env`** — config including APP_KEY + DB creds
- **`storage/logs/`** — Laravel logs

## Backup

```sh
# DB
mysqldump -u lychee -p lychee | gzip > lychee-db-$(date +%F).sql.gz
# Files — uploads volume is where photos live
sudo tar czf lychee-uploads-$(date +%F).tgz lychee/uploads/
# Also: .env (APP_KEY!)
```

## Upgrade

1. **READ v7 UPGRADE GUIDE before going v6→v7**: <https://lycheeorg.dev/docs/upgrade.html#upgrading-lychee-docker-installations-from-v6-to-v7>. Docker image layout changed.
2. Minor version bumps: `docker pull + compose up` — migrations auto-run.
3. **Back up DB + uploads FIRST.**
4. Read changelogs on GitHub releases.
5. Keep queue worker + main app on matching versions.

## Gotchas

- **v6 → v7 is a structural Docker change** — image paths, volume layout, env vars may have shifted. Upstream explicitly flags this. DO NOT blindly update a `:latest` tag; pin major and read upgrade guide.
- **Queue worker MUST be running** — thumbnail generation + upload processing happens in background jobs. Without it, uploads appear to succeed but thumbnails never generate. Use Docker's separate worker container pattern OR systemd `php artisan queue:work`. Same "Queue-worker-NOT-optional" pattern as FreeScout (batch 82).
- **APP_KEY immutability (Laravel class)** — set once, NEVER rotate. Rotating invalidates encrypted DB fields (including stored credentials). Same pattern as FreeScout, Statamic, Fider, Black Candy. **Seventh tool referencing immutability-of-secrets family.**
- **Public-by-default caution**: lychee can expose albums publicly via URLs. Default your uploads to **private**; selectively make albums public. For family photos, be intentional about "public unlisted link" vs "actually public-listed album".
- **Photo-privacy-in-backups** — just like Papra document backups: photos contain PII + faces + GPS coordinates + family-timeline data. Encrypt backups + store off-site securely. Classic family-timeline class from batches 79-82.
- **GPS metadata in EXIF** — photos of your home have your home's GPS. When sharing, Lychee offers options to strip EXIF before rendering public URLs — CONFIGURE THIS. Otherwise every photo you share leaks your location.
- **Thumbnail storage cost**: Lychee generates multiple sizes (thumb, small, medium, original). Disk footprint = roughly 1.3-1.5x original library. Budget accordingly.
- **Large libraries (50K+ photos)** — ensure DB indexes + tuning. PostgreSQL may scale better than SQLite at that size.
- **S3 storage cost trap**: large libraries + S3 = monthly storage bill + egress cost for viewing. Local filesystem often cheaper for archival + frequently-viewed libraries. Do the math before choosing S3.
- **HEIC / HEIF support**: iOS default format. Lychee can handle but needs ImageMagick/libheif compiled into the PHP image. Docker image usually includes this; custom installs may need work.
- **Video support**: Lychee supports video uploads + thumbnails, but is NOT a video-optimized tool like PhotoPrism or Immich. Large video libraries → use dedicated tools.
- **Facial recognition / AI**: core Lychee doesn't do facial recognition. **Immich** + **PhotoPrism** do. SE may add some — verify current features.
- **Mobile apps**: no official native apps (check). Web UI is mobile-friendly. For phone-upload-auto-sync use PhotoSync or Syncthing + watched folder; for dedicated mobile-first photo apps use Immich.
- **Supporter Edition is MIT-compatible OSS? Or commercial license?** Per upstream, SE is a paid variant with additional features. Clarify: buying SE = buying license + support; core Lychee MIT stays free. Commercial-tier-funds-upstream pattern continues.
- **Code-quality signals**: CII Best Practices + OpenSSF Scorecard badges = upstream takes code quality + security posture seriously. Rare positive signal worth calling out.
- **License**: **MIT** (core).
- **Project health**: LycheeOrg community + SE revenue + sponsor donations + OSS foundation signals. Healthy.
- **Alternatives worth knowing:**
  - **Immich** — modern Go/Node photo server; mobile apps with auto-upload; facial recognition; very active
  - **PhotoPrism** — Go; AI + facial recognition; very mature
  - **Piwigo** — PHP; classic; large feature set
  - **Photoview** — Go; simple + fast
  - **Chevereto** — commercial PHP image host
  - **LibrePhotos** — Python + face recognition
  - **Damselfly** — .NET; fast indexing
  - **Nextcloud Photos** — if Nextcloud is already deployed
  - **Choose Lychee if:** PHP stack + elegant UI + MIT + moderate feature needs + SE path for more.
  - **Choose Immich if:** want mobile auto-upload + facial recognition + Google-Photos feel.
  - **Choose PhotoPrism if:** AI + mature.
  - **Choose Piwigo if:** want maximum PHP compat + plugin ecosystem.

## Links

- Repo: <https://github.com/LycheeOrg/Lychee>
- Homepage: <https://lycheeorg.dev>
- Docs: <https://lycheeorg.dev/docs/>
- Supporter Edition: <https://lycheeorg.dev/get-supporter-edition>
- Upgrade guide: <https://lycheeorg.dev/docs/upgrade.html>
- Releases: <https://github.com/LycheeOrg/Lychee/releases>
- GHCR: <https://github.com/LycheeOrg/Lychee/pkgs/container/lychee>
- Sponsor: <https://github.com/sponsors/LycheeOrg>
- OpenSSF Scorecard: <https://securityscorecards.dev/viewer/?uri=github.com/LycheeOrg/Lychee>
- Immich (alt): <https://immich.app>
- PhotoPrism (alt): <https://www.photoprism.app>
- Piwigo (alt): <https://piwigo.org>
- Photoview (alt): <https://github.com/photoview/photoview>
