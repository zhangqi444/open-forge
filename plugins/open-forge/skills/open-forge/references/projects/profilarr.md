---
name: Profilarr
description: "Build, test, and deploy Sonarr/Radarr quality-profiles + custom-formats across instances via API. GitOps for *arr configs. AGPL-3.0. Dictionarry-Hub org. Discord + website. V2 closed-beta; V1 production-stable."
---

# Profilarr

Profilarr is **"GitOps for your *arr custom-formats + quality-profiles"** — build, test, deploy configurations across your media stack. Hours-of-tweaking custom-formats → central repo → sync to all Sonarr/Radarr instances via their APIs. Prevents config-drift.

## ⚠️ VERSION NOTE

Per README: **"V2 is not yet ready for production use. It is currently in closed beta."** For production, use **Profilarr V1** branch. This is another **honest-dual-branch-during-rewrite** pattern — V1 is production, V2 is closed-beta (Discord-invite only).

**Honest-maintainer-declaration: 6 tools** 🎯 **6-TOOL MILESTONE**:
- Scriberr honest-life-pause (109)
- Astuto honest-discontinuation (113)
- Jellystat honest-rewrite-pause (114)
- Stump honest-WIP-pre-1.0 (115)
- Reiverr honest-active-rewrite (116)
- **Profilarr honest-closed-beta-V2 + V1-production (116 — 6th flavor)**

Built + maintained by **Dictionarry-Hub** org. Website <dictionarry.dev>. License: **AGPL-3.0**. Active CI; Discord; release cadence.

Use cases: (a) **sync custom-formats across 5 Sonarr instances** (b) **GitOps for media-stack config** (c) **test custom-format changes before deploying** (d) **fleet-of-arrs management** (e) **public community-format-sharing via Dictionarry** (f) **config-as-code for media** (g) **multi-family arr-stack management** (h) **arr-config-drift prevention**.

Features (per README):

- **Build + test + deploy** custom-formats + profiles
- **Radarr + Sonarr API** integration
- **Import + export + sync**
- **Prevents config-drift** between instances

- Upstream repo: <https://github.com/Dictionarry-Hub/profilarr>
- V1 branch: <https://github.com/Dictionarry-Hub/profilarr/tree/v1>
- Website: <https://dictionarry.dev>
- Discord: <https://discord.gg/2A89tXZMgA>

## Architecture in one minute

- **SvelteKit** frontend (based on src/lib/client path)
- **Python** backend likely
- **Config file** driven
- **API client** to Sonarr/Radarr
- **Resource**: very-low
- **Port**: web UI

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **V1 is production; V2 beta**                                   | **Primary**                                                                        |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | Internal-only preferred                                     | URL          |                                                                                    |
| Sonarr URL + API key(s) | Per-instance                                             | **CRITICAL** | Admin write-access                                                                                    |
| Radarr URL + API key(s) | Per-instance                                             | **CRITICAL** | Admin write-access                                                                                    |
| Git repo (opt)       | For config-storage                                          | Config       |                                                                                    |

## Install via Docker

For V1 (production):
```yaml
services:
  profilarr:
    image: ghcr.io/dictionarry-hub/profilarr:v1        # **pin V1 for prod**
    volumes:
      - ./profilarr-config:/config
    ports: ["6868:6868"]
    restart: unless-stopped
```

## First boot

1. Start V1 for production
2. Configure Sonarr/Radarr API endpoints + keys
3. Import existing custom-formats
4. Version-control in Git (optional but recommended)
5. Test changes on staging Sonarr before pushing to production
6. Join Discord for V2 beta-test if interested

## Data & config layout

- `/config/` — profiles, formats, API config
- Optional Git-backed config repo

## Backup

```sh
sudo tar czf profilarr-config-$(date +%F).tgz profilarr-config/
# Contains Sonarr + Radarr API keys with write-access — **ENCRYPT**
```

## Upgrade

1. Releases: <https://github.com/Dictionarry-Hub/profilarr/releases>
2. **V1 vs V2** — stay on V1 tag for prod
3. Docker pull + restart

## Gotchas

- **135th HUB-OF-CREDENTIALS CROWN-JEWEL TIER 1 — *ARR-CONFIG-WRITE-ACCESS**:
  - Admin API keys for N Sonarr + Radarr instances
  - **WRITE authority on config** — bad push = all profiles broken
  - **135th tool in hub-of-credentials family — Tier 1 CROWN-JEWEL**
  - **Media-stack-credential-aggregator family**: 2 tools (Cleanuparr delete-authority + Profilarr config-write-authority) 🎯 **2-TOOL MILESTONE**
  - **CROWN-JEWEL Tier 1: 39 tools / 36 sub-categories**
- **CONFIG-WRITE-AUTHORITY-DISCIPLINE**:
  - Bad push to N instances = fleet-wide outage
  - Use Git + PR review
  - **Recipe convention: "fleet-write-config-needs-PR-discipline callout"**
  - **NEW recipe convention** (Profilarr 1st formally)
- **V1 PRODUCTION + V2 CLOSED-BETA**:
  - Production users have a clear choice (V1)
  - V2 is explicitly closed-beta (Discord invite)
  - **6th flavor of honest-declaration: closed-beta + production-V1-parallel**
  - **Honest-declaration taxonomy now 6-dimensional**
- **CLOSED-BETA-IS-INVITE-ONLY**:
  - Discord gate for V2 test
  - Controlled-exposure model
  - **Recipe convention: "closed-beta-via-Discord-invite neutral-signal"**
  - **NEW neutral-signal convention** (Profilarr 1st formally)
- **GITOPS-FOR-ARR-STACK = EXCELLENT PATTERN**:
  - Config-as-code for media
  - **Recipe convention: "GitOps-for-media-stack positive-signal"**
  - **NEW positive-signal convention** (Profilarr 1st formally)
- **COMMUNITY-FORMAT-SHARING VIA DICTIONARRY.DEV**:
  - Curated community custom-formats
  - Good = leverage community knowledge
  - Risk = blind-imports might DOS your library
  - **Recipe convention: "community-curated-configs-review-before-import callout"**
  - **NEW recipe convention** (Profilarr 1st formally)
- **AGPL-3.0 LICENSE**:
  - Strong copyleft including for network-use
  - **Recipe convention: "AGPL-network-service-copyleft"** — relevant for hosted-SaaS
- **PROJECT-CENTRIC-GITHUB-ORG**:
  - Dictionarry-Hub org; website; Discord
  - **Project-centric-GitHub-org: 2 tools** (Cleanuparr + Dictionarry-Hub/Profilarr) 🎯 **2-TOOL MILESTONE**
- **INSTITUTIONAL-STEWARDSHIP**: Dictionarry-Hub org + website + Discord + AGPL + V1-production + V2-beta + CI. **121st tool — org-with-website-and-dual-branch sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + CI + website + Discord + dual-branch + release-cadence + V2-closed-beta-acknowledged. **127th tool in transparent-maintenance family.**
- **ARR-CONFIG-MGMT-CATEGORY (niche):**
  - **Profilarr** — THE tool for this
  - **TRaSH Guides** — static-docs; manual-apply
  - **Recyclarr** — Python sync-tool; CLI-only
  - **Notifiarr** — notifications + profile-sharing
- **ALTERNATIVES WORTH KNOWING:**
  - **Recyclarr** — if you prefer CLI + Python + smaller-footprint
  - **TRaSH Guides manual** — if you want no-tool + hand-managed
  - **Choose Profilarr if:** you want GUI + test-before-deploy + GitOps.
- **PROJECT HEALTH**: V1-stable + V2-active-beta + Discord + website + CI + AGPL. Strong.

## Links

- Repo: <https://github.com/Dictionarry-Hub/profilarr>
- Website: <https://dictionarry.dev>
- Discord: <https://discord.gg/2A89tXZMgA>
- Recyclarr (alt): <https://github.com/recyclarr/recyclarr>
- TRaSH Guides: <https://trash-guides.info>
