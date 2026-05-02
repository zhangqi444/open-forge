# Nextcloud Social

**ActivityPub / Fediverse integration for Nextcloud**
Official site: https://github.com/nextcloud/social

Nextcloud Social is a Nextcloud app (not a standalone service) that adds ActivityPub federation to an existing Nextcloud instance. Users can follow Mastodon, Pleroma, and other ActivityPub accounts and post from within Nextcloud. Currently in beta.

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Existing Nextcloud instance | Nextcloud app store | Install via Apps panel — no separate container needed |
| Nextcloud Docker (nextcloud:latest) | docker-compose (Nextcloud stack) | Enable via occ or admin UI after container setup |

> ⚠️ This is **not** a standalone Docker app. It requires a running Nextcloud installation.

## Inputs to Collect

### Phase: Pre-deployment
- Working Nextcloud instance (any supported version)
- Publicly reachable domain with HTTPS (required for ActivityPub federation)

### Phase: App configuration
- Enable via Nextcloud admin → Apps → Social
- Configure via admin panel Settings → Social

## Software-Layer Concerns

**Installation methods:**
1. **App store (recommended):** Admin → Apps → search "Social" → Enable
2. **Manual:** Clone repo into Nextcloud's `apps/` directory, run `make dev-setup && make build-js`, enable via admin UI or `occ`
3. **occ CLI:** `php occ app:enable social`

**Requirements:**
- MySQL/MariaDB with 4-byte UTF-8 support (for emoji) — see [Nextcloud emoji guide](https://docs.nextcloud.com/server/stable/admin_manual/configuration_database/mysql_4byte_support.html)
- Public HTTPS URL (federation won't work behind NAT without proper routing)
- Background jobs configured (cron or Webcron)

**Reset / domain change:**
```
php occ social:reset
```
Use this before changing the domain — social data is domain-bound.

## Upgrade Procedure

1. Via admin UI: Apps → Updates → update Social app
2. Via occ: `php occ app:update social`
3. After major Nextcloud upgrades, check Social app compatibility in the app store

## Gotchas

- **Beta quality** — expect rough edges; not recommended for production-critical use
- **Domain is permanent** — once Social is configured, changing the domain requires a full reset (`occ social:reset`) which deletes all social data
- **Emoji requires MySQL config** — PostgreSQL users may have issues; follow the 4-byte UTF-8 guide
- **HTTPS mandatory** — ActivityPub federation requires a valid public HTTPS URL; local-only installs won't federate
- **No Docker image** — this is a Nextcloud plugin, not a standalone container; use the Nextcloud Docker stack

## References
- Upstream README: https://github.com/nextcloud/social/blob/HEAD/README.md
- Nextcloud app store: https://apps.nextcloud.com/apps/social
