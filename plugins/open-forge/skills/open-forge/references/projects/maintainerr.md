---
name: Maintainerr
description: "Monitor + remove unwatched Plex/Jellyfin media. Rules based on Plex/Jellyfin/Seerr/Radarr/Sonarr/Tautulli. 'Leaving soon' collection. maintainerr org. Discord. OpenCollective. Material-for-MkDocs docs."
---

# Maintainerr

Maintainerr is **"the janitor for your Plex/Jellyfin server — rules-based auto-removal of unwatched media"** — monitors your media server and removes media that matches your rules (never watched, too old, etc.). Pulls rules from Plex, **Jellyfin**, Seerr, Radarr, Sonarr, Tautulli. Shows a "Leaving soon" collection on the media server before deletion.

Built + maintained by **maintainerr** org. Discord community. OpenCollective funded. Material-for-MkDocs documentation. Active releases. Docker Hub.

Use cases: (a) **auto-remove unwatched media** (b) **disk-space reclamation** (c) **rule-based media-rotation** (d) **"leaving soon" user-facing collection** (e) **Plex + Jellyfin dual-server** with rule-migration (f) **user-request-and-abandon cleanup** (Seerr integration) (g) **home server hygiene automation** (h) **shared server policy enforcement**.

Features (per README):

- **Rules** from Plex/Jellyfin/Seerr/Radarr/Sonarr/Tautulli
- **Switchable between Plex + Jellyfin** with auto-rule migration
- **Manual add/exclude** overrides
- **"Leaving soon" collection** on media server
- **Preview deletion** before execution

- Upstream repo: <https://github.com/Maintainerr/Maintainerr>
- Docs: <https://docs.maintainerr.info>
- OpenCollective: <https://opencollective.com/maintainerr>
- Discord: <https://discord.gg/WP4ZW2QYwk>

## Architecture in one minute

- Node.js + TypeScript (apps/ui + apps/api typical)
- SQL database
- Docker-first
- **Resource**: moderate
- **Port**: HTTP

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | `maintainerr/maintainerr`                                       | **Primary**                                                                        |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Media server         | Plex or Jellyfin                                            | Integration  | Pick one or both                                                                                    |
| Plex token           | API                                                         | Secret       |                                                                                    |
| Jellyfin API key     | API                                                         | Secret       |                                                                                    |
| Sonarr/Radarr keys   | Metadata lookup                                             | Integration  | Optional per-rule                                                                                    |
| Tautulli             | Watch-stats                                                 | Integration  | Optional                                                                                    |
| Seerr                | Request info                                                | Integration  | Optional                                                                                    |

## Install via Docker

```yaml
services:
  maintainerr:
    image: maintainerr/maintainerr:latest        # **pin**
    ports: ["6246:6246"]
    volumes:
      - ./maintainerr-data:/opt/data
    restart: unless-stopped
```

## First boot

1. Start; browse UI
2. Configure media server (Plex/Jellyfin token)
3. Configure optional Sonarr/Radarr/Tautulli/Seerr
4. Create first rule (preview before enable)
5. Test deletion-preview flow
6. Enable rule
7. Monitor "Leaving soon" collection
8. Back up `/opt/data`

## Data & config layout

- `/opt/data/` — SQLite + configs

## Backup

```sh
sudo tar czf maintainerr-$(date +%F).tgz maintainerr-data/
# Contains Plex/Jellyfin/Sonarr/Radarr/Tautulli API keys — **ENCRYPT**
```

## Upgrade

1. Releases: <https://github.com/Maintainerr/Maintainerr/releases>
2. Read release notes (rule-schema changes!)
3. Docker pull + restart

## Gotchas

- **170th HUB-OF-CREDENTIALS CROWN-JEWEL TIER 1 — MEDIA-STACK-DESTRUCTIVE-ACTIONS**:
  - Holds: Plex/Jellyfin tokens + Sonarr/Radarr/Tautulli/Seerr API keys
  - **Destructive privilege**: can DELETE media from media server based on rules
  - Misconfigured rule = mass-deletion
  - **170th tool in hub-of-credentials family — Tier 1 CROWN-JEWEL**
  - **170-TOOL HUB-OF-CREDENTIALS MILESTONE at Maintainerr**
  - **NEW CROWN-JEWEL Tier 1 sub-category: "automated-media-deletion-rules-engine"** (1st — Maintainerr; destructive-privilege-specific)
  - **CROWN-JEWEL Tier 1: 58 tools / 52 sub-categories**
- **DESTRUCTIVE-ACTION-RULE-REVIEW**:
  - Rules delete files
  - Preview-before-enable is critical
  - **Recipe convention: "destructive-action-preview-before-enable-discipline callout"**
  - **NEW recipe convention** (Maintainerr 1st formally; HIGH-severity)
- **RULE-MIGRATION-BETWEEN-MEDIA-SERVERS**:
  - Switch Plex↔Jellyfin with auto-rule-migration
  - **Recipe convention: "multi-media-server-rule-migration positive-signal"**
  - **NEW positive-signal convention** (Maintainerr 1st formally)
- **LEAVING-SOON-COLLECTION UX**:
  - User-visible "leaving soon" collection
  - Users can watch before it's deleted
  - **Recipe convention: "user-facing-deletion-preview-collection positive-signal"**
  - **NEW positive-signal convention** (Maintainerr 1st formally)
- **MEDIA-STACK-CREDENTIAL-AGGREGATOR**:
  - **Media-stack-credential-aggregator: 4 tools** (Tunarr+Profilarr+Recyclarr+Maintainerr) 🎯 **4-TOOL MILESTONE**
- **OPENCOLLECTIVE-FUNDED**:
  - **Open-Collective-transparent-finances: 6 tools** (+Maintainerr) 🎯 **6-TOOL MILESTONE**
- **MATERIAL-FOR-MKDOCS**:
  - Material-for-MkDocs docs site
  - Common modern docs stack
  - **Recipe convention: "Material-for-MkDocs-docs-framework neutral-signal"**
  - **NEW neutral-signal convention** (Maintainerr 1st formally)
- **DISCORD-COMMUNITY**: active
- **BADGE-HEAVY-README (9+ badges)**:
  - Docker + Discord + GitHub stars + commits + issues + license + OpenCollective
  - **Recipe convention: "badge-heavy-README-signal-density neutral-signal"**
  - **NEW neutral-signal convention** (Maintainerr 1st formally)
- **INSTITUTIONAL-STEWARDSHIP**: Maintainerr org + Discord + OpenCollective + Material-for-MkDocs docs + active + badge-heavy. **156th tool — community-funded-media-stack-OSS sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + Discord + OpenCollective + docs + badges + releases + commit-activity-badge. **162nd tool in transparent-maintenance family.**
- **MEDIA-CLEANUP-CATEGORY:**
  - **Maintainerr** — rule-based; multi-service-aware
  - **Custom scripts** — many manually-written
  - **Doplarr / Tautulli-notifier** — different angle (notifications)
  - **Kometa (PMM)** — Plex/Jellyfin meta-management
- **ALTERNATIVES WORTH KNOWING:**
  - **Kometa** — if you want Plex metadata management too
  - **Custom Tautulli scripts** — if you want DIY
  - **Choose Maintainerr if:** you want rule-engine UX + preview-before-delete + multi-source rules.
- **PROJECT HEALTH**: active + community-funded + docs + Discord + badge-heavy. Strong.

## Links

- Repo: <https://github.com/Maintainerr/Maintainerr>
- Docs: <https://docs.maintainerr.info>
- OpenCollective: <https://opencollective.com/maintainerr>
- Kometa (alt): <https://github.com/Kometa-Team/Kometa>
