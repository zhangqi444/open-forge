# Nextcloud Tables

> Nextcloud app for creating custom structured data tables with configurable columns — a lightweight, self-hosted alternative to Airtable or Notion databases, built into your Nextcloud instance.

**URL:** https://apps.nextcloud.com/apps/tables
**Source:** https://github.com/nextcloud/tables
**License:** AGPL-3.0-or-later

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any   | Nextcloud app (via App Store) | Requires a running Nextcloud instance; install from the built-in app store |
| Any   | Build from source | Requires Node.js and Composer |

> This is a **Nextcloud app**, not a standalone service. You must have Nextcloud already deployed.

## Inputs to Collect

### Provision phase
- An existing, operational Nextcloud instance (any supported version)
- Admin access to the Nextcloud app store or file system

### Deploy phase
- No additional environment variables required beyond your existing Nextcloud configuration

## Software-layer Concerns

### Installation via Nextcloud App Store (recommended)
1. Log in to Nextcloud as admin
2. Go to **Apps** → search for "Tables"
3. Click **Download and enable**

### Installation from release tarball
```bash
# Download latest release from:
# https://github.com/nextcloud-releases/tables/releases
# Extract into your Nextcloud apps directory
tar -xzf tables-*.tar.gz -C /path/to/nextcloud/apps/
# Enable via occ or admin UI
php occ app:enable tables
```

### Build from source
```bash
git clone https://github.com/nextcloud/tables
cd tables
composer install --no-dev
npm ci
npm run build   # production build
```
Then copy the `tables/` directory into your Nextcloud `apps/` folder and enable it.

### Config / env vars
- No Tables-specific env vars; inherits all Nextcloud configuration (database, Redis, etc.)

### Data dirs
- Table data is stored in the Nextcloud database (same DB as the rest of Nextcloud)
- No separate data directory required

## Upgrade Procedure
Update via the Nextcloud App Store (Admin → Updates) or replace the app directory with a new release tarball and run:
```bash
php occ upgrade
```

## Gotchas
- **Requires Nextcloud** — Tables is not a standalone app; it cannot be run independently.
- **Version compatibility** — ensure the Tables app version is compatible with your Nextcloud major version before upgrading.
- Build from source requires both Node.js and Composer; the App Store method requires neither.
- All administration and API documentation is in the [project wiki](https://github.com/nextcloud/tables/wiki).

## Links
- [README](https://github.com/nextcloud/tables/blob/main/README.md)
- [Nextcloud App Store listing](https://apps.nextcloud.com/apps/tables)
- [Project wiki (admin, API, developer docs)](https://github.com/nextcloud/tables/wiki)
- [Release downloads](https://github.com/nextcloud-releases/tables/releases)
