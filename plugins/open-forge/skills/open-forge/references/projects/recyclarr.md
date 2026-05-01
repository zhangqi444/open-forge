---
name: Recyclarr
description: "CLI that auto-syncs TRaSH Guides recommendations into Sonarr + Radarr. Quality profiles, custom formats, quality definitions. .NET / C#. recyclarr org. Discord. Qodana quality. Apache-2 likely."
---

# Recyclarr

Recyclarr is **"TRaSH-Guides-as-Code — sync community-curated media settings into Sonarr/Radarr automatically"** — a command-line app that synchronizes recommended settings from the **TRaSH Guides** to Sonarr/Radarr (v4+). Keeps quality profiles, custom formats, quality definitions, naming formats, propers/repacks current without manual dashboard work.

Built + maintained by **recyclarr** org. Discord TRaSH-Guides community. Qodana quality. GitHub-Actions CI. Versioned Docker releases (major-tag convention).

Use cases: (a) **auto-sync TRaSH-Guides settings** (b) **multi-Sonarr/Radarr config discipline** (c) **fleet-media-server config drift prevention** (d) **CI/CD for media stack** (e) **GitOps-for-media** config (f) **hands-off quality-profile updates** (g) **community-curated settings adoption** (h) **Sonarr-v4+ / Radarr-v4+ automation**.

Features (per README):

- **Syncs from TRaSH Guides**
- **Quality Profiles** (qualities + groups)
- **Custom Formats** (with scores)
- **Quality Definitions** (file sizes)
- **Media Naming Formats**
- **Media Management** (propers/repacks)
- **Sonarr v4+ / Radarr v4+ supported**

- Upstream repo: <https://github.com/recyclarr/recyclarr>
- Website: <https://recyclarr.dev>
- Docs: <https://recyclarr.dev/wiki/>
- Discord: TRaSH-Guides-community

## Architecture in one minute

- **.NET / C#** CLI
- YAML config
- **One-shot**: run + exit (cron or CI)
- Docker image published
- **Resource**: minimal (one-shot)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | Cron or one-shot                                                                                                       | **Primary**                                                                                   |
| **Native .NET**    | Binary                                                                                                                 | Alt                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Sonarr URL+API-key   | `http://sonarr:8989`                                        | Config       |                                                                                    |
| Radarr URL+API-key   | `http://radarr:7878`                                        | Config       |                                                                                    |
| YAML config          | recyclarr.yml                                               | Config       | From docs                                                                                    |
| Schedule             | Cron                                                        | Ops          | Weekly typical                                                                                    |

## Install via Docker

**⚠️ IMPORTANT: `latest` tag NO LONGER published. Use major-version tag (`8`, `9`, etc.)**

```yaml
services:
  recyclarr:
    image: recyclarr/recyclarr:8        # **major-version tag**
    volumes:
      - ./recyclarr-config:/config
    environment:
      - TZ=Europe/Berlin
    # Run once and exit; re-run via cron or schedule
```

Cron wrapper (host crontab):
```
0 3 * * 0 docker run --rm -v /srv/recyclarr:/config recyclarr/recyclarr:8 sync
```

## First boot

1. Create `/config/recyclarr.yml` from docs examples
2. Add Sonarr/Radarr instances with API keys
3. Pick quality-profile templates + custom-formats
4. Run manually: `docker run --rm -v ./config:/config recyclarr/recyclarr:8 sync`
5. Review Sonarr/Radarr for imported changes
6. Schedule weekly run via cron/systemd-timer

## Data & config layout

- `/config/recyclarr.yml` — your YAML config
- `/config/cache/` — TRaSH-Guides cache

## Backup

```sh
sudo tar czf recyclarr-$(date +%F).tgz recyclarr-config/
# Contains Sonarr/Radarr API keys — **ENCRYPT**
```

## Upgrade

1. Releases: <https://github.com/recyclarr/recyclarr/releases>
2. **Major-version tag ≠ latest**. Track major-version tags.
3. Read release notes; Sonarr/Radarr version-compatibility matters

## Gotchas

- **165th HUB-OF-CREDENTIALS Tier 3 — SONARR/RADARR API-KEYS**:
  - Holds: API keys for all your Sonarr/Radarr instances
  - Sonarr/Radarr keys can reconfigure your media-grabber stack
  - **165th tool in hub-of-credentials family — Tier 3**
  - **Media-stack-credential-aggregator: 3 tools** (Tunarr+Profilarr+Recyclarr) 🎯 **3-TOOL MILESTONE**
  - **Recipe convention: "media-stack-credential-aggregator"** — reinforces Profilarr/Tunarr pattern
- **LATEST-TAG-NO-LONGER-PUBLISHED WARNING**:
  - README explicitly says `latest` is no longer published
  - Major-version tag required
  - **Explicit-no-latest-tag-warning: 1 tool** 🎯 **NEW FAMILY** (Recyclarr; 1st formally; major positive-signal for responsible image-publishing)
  - **Recipe convention: "explicit-no-latest-tag-maintainer-warning positive-signal"**
  - **NEW positive-signal convention** (Recyclarr 1st formally)
- **COMMUNITY-CURATED-CONFIG-IMPORT**:
  - Importing TRaSH-Guides = trusting the community
  - **Recipe convention: "community-curated-configs-review-before-import"** — reinforces Profilarr (116)
- **FLEET-WRITE-CONFIG-DISCIPLINE**:
  - Auto-writes to Sonarr/Radarr; review changes
  - **Recipe convention: "fleet-write-config-needs-PR-discipline"** — reinforces Profilarr (116)
- **ONE-SHOT-CRON-PATTERN**:
  - Not a daemon; cron/schedule-driven
  - **One-shot-cron-tool: 1 tool** 🎯 **NEW FAMILY** (Recyclarr; distinct pattern from always-on tools)
  - **Recipe convention: "one-shot-batch-cron-execution-pattern neutral-signal"**
  - **NEW neutral-signal convention** (Recyclarr 1st formally)
- **QODANA-QUALITY-TRACKING**:
  - JetBrains Qodana code-quality
  - **Recipe convention: "Qodana-quality-gate positive-signal"**
  - **NEW positive-signal convention** (Recyclarr 1st formally)
- **DISCORD-TRASH-GUIDES-ECOSYSTEM**:
  - Shared Discord with TRaSH-Guides
  - Ecosystem-connectedness
  - **Recipe convention: "shared-ecosystem-community-channel positive-signal"**
  - **NEW positive-signal convention** (Recyclarr 1st formally)
- **GITOPS-FOR-MEDIA-STACK**:
  - YAML-config in version-control
  - **Recipe convention: "GitOps-for-media-stack"** — reinforces Profilarr (116)
- **INSTITUTIONAL-STEWARDSHIP**: recyclarr org + website + docs + Discord + Qodana + explicit-no-latest-tag + versioned-releases. **151st tool — responsible-image-publishing-exemplar sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + CI + Qodana + docs + Discord + major-tag-discipline. **157th tool in transparent-maintenance family.**
- **MEDIA-STACK-CONFIG-CATEGORY:**
  - **Recyclarr** — TRaSH-Guides sync; CLI
  - **Profilarr** — profile-sync across Sonarr/Radarr (b116)
  - **Notifiarr** — Discord notifications for Starr-apps
  - **Starr-arr-stack** — various
- **ALTERNATIVES WORTH KNOWING:**
  - **Profilarr** — if you want GUI + profile-sync
  - **Choose Recyclarr if:** you want CLI + GitOps + TRaSH-Guides focus.
- **PROJECT HEALTH**: active + explicit-publishing-discipline + Qodana + Discord. Very strong responsible-OSS exemplar.

## Links

- Repo: <https://github.com/recyclarr/recyclarr>
- Docs: <https://recyclarr.dev/wiki/>
- TRaSH Guides: <https://trash-guides.info>
- Profilarr (alt): <https://github.com/Dictionarry-Hub/profilarr>
