---
name: Cleanuparr
description: "Automated cleanup tool for *arr stack (Sonarr/Radarr/Lidarr/Readarr/Whisparr/qBittorrent). Strike system; malware-blocker; stalled/slow-download removal; cross-seed awareness. C#/.NET. Cleanuparr org. Discord + GitAds sponsor."
---

# Cleanuparr

Cleanuparr is **"the janitor for your *arr-stack — kills malicious/stuck downloads so Sonarr/Radarr don't get poisoned"** — an automated cleanup tool for *arrs (Sonarr/Radarr/Lidarr/Readarr/Whisparr v2+v3) and download clients (qBittorrent). **Strike system** for bad downloads. Removes malware (like `*.lnk`, `*.zipx`) that sneak in. Cleans stalled/low-speed/metadata-stuck downloads. Proactive search for missing + quality-upgrade + custom-format-score. Seeding-time policy enforcement. Orphaned-file cleanup. **Community malware-pattern sharing**.

Built + maintained by **Cleanuparr org**. License: check LICENSE. Active; Discord; GitAds sponsorship; tested-in-CI badge.

Use cases: (a) **block malware in download-clients** — the 2024 Sonarr-virus incidents (b) **auto-retry stalled downloads** (c) **quality-upgrade-sweep** — pending cutoffs (d) **orphaned-file cleanup** — cross-seed-aware (e) **enforce seeding-time policy** (f) **strike-system for repeat-offenders** (g) **automated-arr-maintenance** — "set and forget" (h) **hoarder-library hygiene** — thousands of downloads.

Features (per README):

- **Strike system** (mark bad; remove after threshold)
- **Remove downloads failing to import**
- **Remove stalled / metadata-stuck**
- **Remove slow downloads**
- **Malware blocker** (community patterns)
- **Auto-trigger search after removal**
- **Proactive missing-items search**
- **Cutoff Unmet** (quality upgrade search)
- **Custom-format score upgrades**
- **Seeding-time enforcement**
- **Orphaned/no-hardlinks cleanup** (cross-seed aware)
- **Strike/removal notifications**
- **Ignore lists** (hash, category, tags, trackers)

Supported arr applications: Sonarr, Radarr, Lidarr, Readarr, Whisparr v2, Whisparr v3. Download clients: qBittorrent (known).

- Upstream repo: <https://github.com/Cleanuparr/Cleanuparr>
- Screenshots: <https://cleanuparr.github.io/Cleanuparr/docs/screenshots>
- Discord: <https://discord.gg/SCtMCgtsc4>

## Architecture in one minute

- **C# / .NET** service
- **Config file driven**
- **Connects to**: Sonarr API + Radarr API + qBittorrent API
- **Resource**: low — 100-250MB RAM
- **Runs**: on-schedule (cron-like)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **`ghcr.io/cleanuparr/cleanuparr`**                             | **Primary**                                                                        |
| **Native .NET**    | Self-contained                                                                                                         | Alt                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| **Sonarr URL + API key** | Per-instance                                            | **CRITICAL** | **Admin write-access**                                                                                    |
| **Radarr URL + API key** | Per-instance                                            | **CRITICAL** | **Admin write-access**                                                                                    |
| **qBittorrent URL + creds** | If using                                             | **CRITICAL** | **Admin**                                                                                    |
| Malware pattern list | Community-shared                                            | Config       |                                                                                    |
| Strike thresholds    | How many strikes = remove                                   | Config       |                                                                                    |
| Ignore list          | Hashes/tags/trackers to skip                                | Config       |                                                                                    |
| Notification URL     | Apprise/Discord/etc                                         | Notifications|                                                                                    |

## Install via Docker

```yaml
services:
  cleanuparr:
    image: ghcr.io/cleanuparr/cleanuparr:latest        # **pin version**
    volumes:
      - ./cleanuparr-config:/config
    environment:
      TZ: UTC
    restart: unless-stopped
```

Config is file-driven; mount `/config` and edit `appsettings.json`.

## First boot

1. Start; generate initial `appsettings.json`
2. Fill Sonarr + Radarr + qBittorrent API details
3. Define strike-thresholds conservatively (high first-run)
4. Run in **dry-run** mode if supported; review logs
5. Enable malware-blocker
6. Tune thresholds based on actual churn
7. Back up `/config`

## Data & config layout

- `/config/appsettings.json` — all config + API keys

## Backup

```sh
sudo tar czf cleanuparr-config-$(date +%F).tgz cleanuparr-config/
# ENCRYPT — contains arr + qBittorrent API keys
```

## Upgrade

1. Releases: <https://github.com/Cleanuparr/Cleanuparr/releases>. Active.
2. Docker pull + restart
3. Read release notes — behavior-changes in strikes/malware policies

## Gotchas

- **128th HUB-OF-CREDENTIALS CROWN-JEWEL TIER 1 — *ARR-CREDENTIAL-AGGREGATOR + DESTROYER**:
  - Holds admin API keys for 5+ arr instances + qBittorrent
  - Has **DELETE authority** on each — can destroy libraries if misconfigured
  - **128th tool in hub-of-credentials family — Tier 1 CROWN-JEWEL**
  - **NEW CROWN-JEWEL Tier 1 sub-category: "media-stack-credential-aggregator + destroyer-class"** (1st — Cleanuparr; distinct from Tunarr 114 which is a consumer)
  - **CROWN-JEWEL Tier 1: 37 tools / 34 sub-categories**
- **DESTRUCTIVE-AUTOMATION RISK**:
  - Bad strike-config = legitimate downloads flagged + removed + re-searched = infinite-loop
  - **Recipe convention: "destructive-automation-config-discipline callout"** — start conservative
  - **NEW recipe convention** (Cleanuparr 1st formally)
- **MALWARE-BLOCKER COMMUNITY-SOURCED**:
  - Patterns shared by community
  - Malicious pattern-submission = false-positive DoS
  - **Recipe convention: "community-sourced-threat-intel-integrity-risk callout"**
  - **NEW recipe convention** (Cleanuparr 1st formally)
  - **Positive-signal**: community intel faster than vendor
  - **Recipe convention: "community-threat-intel positive-signal"**
  - **NEW positive-signal convention** (Cleanuparr 1st formally)
- **CROSS-SEED AWARENESS**:
  - Integration with cross-seed.org
  - Aware of multi-tracker-seeding setups
  - **Recipe convention: "cross-seed-integration positive-signal"**
  - **NEW positive-signal convention** (Cleanuparr 1st formally)
- **REDDIT-ROOTED PROJECT ORIGIN**:
  - README links to reddit posts that catalyzed creation
  - **Recipe convention: "community-pain-point-origin positive-signal"** — responsive to community
  - **NEW positive-signal convention** (Cleanuparr 1st formally)
- **GITADS SPONSORSHIP**:
  - README-embedded ad for revenue
  - Transparent
  - **Recipe convention: "GitAds-README-sponsored neutral-signal"**
  - **NEW neutral-signal convention** (Cleanuparr 1st formally)
- **REPOSITORY-NAME-MATCHES-ORG-NAME**:
  - `Cleanuparr/Cleanuparr` pattern = project-centric org
  - **Recipe convention: "project-centric-GitHub-org positive-signal"**
  - **NEW positive-signal convention** (Cleanuparr 1st formally)
- **TEST-IN-CI BADGE**:
  - Tested workflows
  - **Recipe convention: "CI-tests-badge positive-signal"** — standard
- **INSTITUTIONAL-STEWARDSHIP**: Cleanuparr org + Discord + community-intel + GitAds-sponsored + CI-tested. **114th tool — community-org-with-ad-sponsorship sub-tier** (NEW soft-tier).
- **TRANSPARENT-MAINTENANCE**: active + Discord + CI + GitAds + community-intel + screenshots + releases. **120th tool 🎯 120-TOOL MILESTONE in transparent-maintenance family**.
- **ARR-MAINTENANCE-CATEGORY (niche):**
  - **Cleanuparr** — C#/.NET; destructive-side
  - **Autobrr** — announce-channel automation; different scope
  - **Sonarr/Radarr built-in** (limited cleanup)
  - **scripts** (community-contributed)
- **ALTERNATIVES WORTH KNOWING:**
  - **Autobrr** — if you want announce-automation (different scope)
  - **Manual cleanup** — if you don't want destructive-automation
  - **Choose Cleanuparr if:** you want automated + strike-based + malware-blocking arr maintenance.
- **PROJECT HEALTH**: active + Discord + CI + sponsored + community-driven. Strong.

## Links

- Repo: <https://github.com/Cleanuparr/Cleanuparr>
- Discord: <https://discord.gg/SCtMCgtsc4>
- cross-seed: <https://www.cross-seed.org>
- Autobrr (adjacent): <https://github.com/autobrr/autobrr>
