---
name: Endurain
description: "Self-hosted fitness tracking service. Upload activities, analyze, track progress. endurain-project org. Codeberg-primary (GitHub mirror archived). Crowdin i18n. Trademarked name. Live demo. Discord + Mastodon."
---

# Endurain

Endurain is **"Strava / Garmin Connect — but self-hosted + OSS"** — a fitness-tracking service where you upload activities (runs, rides, swims), analyze them, track progress. **Canonical repo moved to Codeberg**; GitHub mirror is archived.

Built + maintained by **endurain-project** org. Codeberg-primary. Crowdin for localization. Trademark policy (**Endurain™** name protection). Live demo at demo.endurain.com. Mastodon + Discord community.

Use cases: (a) **self-hosted Strava** (b) **Garmin-upload alternative** (c) **cycling/running/swimming tracker** (d) **privacy-preserving fitness data** (e) **family/team fitness group** (f) **multi-sport activity tracker** (g) **export your own fitness data** (h) **coaching/athlete platforms (small)**.

Features (per README + demo):

- **Activity upload + analysis**
- **Multi-sport** tracking
- **Self-hosted**
- **Live demo** at demo.endurain.com (creds: admin/admin; resets daily)
- **Crowdin-i18n**
- **Trademarked**

- Upstream repo: <https://codeberg.org/endurain-project/endurain> (**primary — GitHub is archived mirror**)
- GitHub mirror (archived): <https://github.com/endurain-project/endurain>
- Demo: <https://demo.endurain.com> (admin/admin)
- Mastodon: <https://fosstodon.org/@endurain>
- Discord: <https://discord.gg/6VUjUq2uZR>
- Trademark: <https://codeberg.org/endurain-project/endurain/src/branch/master/TRADEMARK.md>

## Architecture in one minute

- FastAPI/similar backend + Vue/React frontend
- PostgreSQL
- Storage for activity files (.fit, .gpx, .tcx)
- **Resource**: moderate
- **Port**: HTTP

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker Compose** | From Codeberg                                                                                                          | **Primary**                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `fitness.example.com`                                       | URL          | TLS                                                                                    |
| PostgreSQL           | Data                                                        | DB           |                                                                                    |
| Storage              | Activity file uploads                                       | Storage      |                                                                                    |
| Admin                | First-boot                                                  | Bootstrap    | Strong                                                                                    |

## Install via Docker Compose

From Codeberg repo — clone with:
```sh
git clone https://codeberg.org/endurain-project/endurain.git
cd endurain
# Review docker-compose.yml
docker compose up -d
```

## First boot

1. Deploy
2. Create admin
3. Upload test activity (.gpx or .fit)
4. Verify parsing, map, stats
5. Configure integrations (Strava-import? Garmin?) if present
6. Put behind TLS
7. Back up DB + activity storage

## Data & config layout

- Postgres — users, activities, stats
- Object-storage / filesystem — .fit/.gpx/.tcx files

## Backup

```sh
pg_dump endurain > endurain-$(date +%F).sql
# Plus activity-file storage
# Contains personal health/location data — **ENCRYPT**
```

## Upgrade

1. Releases: <https://codeberg.org/endurain-project/endurain/releases>
2. Pull from Codeberg (not GitHub!)
3. DB migrations
4. Docker pull + restart

## Gotchas

- **171st HUB-OF-CREDENTIALS CROWN-JEWEL TIER 1 — FITNESS + LOCATION + HEALTH DATA**:
  - Holds: **GPS tracks** (route patterns = home/work/gym locations), heart-rate, pace, biometrics
  - **Physical-security-sensitivity**: GPS history reveals home/work locations + patterns
  - **Health-data sensitivity**: biometrics = PII + potentially HIPAA
  - **171st tool in hub-of-credentials family — Tier 1 CROWN-JEWEL**
  - **NEW CROWN-JEWEL Tier 1 sub-category: "fitness-tracking + GPS-plus-biometric-data"** (1st — Endurain; location-sensitive + health-sensitive combined)
  - **CROWN-JEWEL Tier 1: 59 tools / 53 sub-categories**
  - **Infra-data-sensitivity family: 4 tools** (portracker/ARA/Reitti/Endurain) 🎯 **4-TOOL MILESTONE — 4 distinct data-treasure types** (network/IaC/physical-location/biometric-GPS)
- **GPS-TRACK-PHYSICAL-SECURITY**:
  - Run/ride starts + ends = home/work locations
  - Weekly patterns = stalking-vector
  - **Recipe convention: "GPS-track-physical-security-discipline"** — reinforces Reitti (116)
  - **Recipe convention: "fitness-GPS-home-location-redaction callout"**
  - **NEW recipe convention** (Endurain 1st formally)
- **HIPAA/HEALTH-DATA-SENSITIVITY**:
  - Heart rate + other biometrics = health data
  - US HIPAA + EU GDPR "special category"
  - **Recipe convention: "health-biometric-data-regulatory-classification callout"**
  - **NEW recipe convention** (Endurain 1st formally)
- **CODEBERG-PRIMARY-GITHUB-ARCHIVED**:
  - Canonical source = Codeberg
  - GitHub is explicitly archived
  - **Recipe convention: "Codeberg-primary-GitHub-archived-explicit-direction positive-signal"**
  - **NEW positive-signal convention** (Endurain 1st formally; distinct from ARA's Codeberg-mirror pattern — Endurain MOVED with explicit GitHub-archive)
  - **Codeberg-primary: 2 tools** (ARA-mirror+Endurain-moved) 🎯 **2-TOOL MILESTONE** (subtly distinct flavors)
- **TRADEMARK-POLICY**:
  - Endurain™ is trademarked
  - Forks/rebuilds must comply with TRADEMARK.md
  - **Recipe convention: "trademark-policy-for-OSS-name callout"**
  - **NEW recipe convention** (Endurain 1st formally)
  - **Trademark-protected-name: 1 tool** 🎯 **NEW FAMILY** (Endurain)
- **CROWDIN-I18N**:
  - Crowdin for community-translations
  - **Community-translation-infrastructure: 3 tools** 🎯 **3-TOOL MILESTONE** (+Endurain, continuing pattern)
- **LIVE-DEMO-WITH-PUBLIC-CREDS**:
  - demo.endurain.com; admin/admin; daily reset
  - **Live-demo-with-public-credentials: 3 tools** (Open Archiver+Notifuse+Endurain) 🎯 **3-TOOL MILESTONE**
- **FEDIVERSE-PRESENCE + DISCORD**:
  - Mastodon at fosstodon.org + Discord
  - **Fediverse-plus-X-presence / multi-community: many tools** (continuing)
- **REPO-MIGRATION-EXPLICIT-GUIDANCE**:
  - README shows `git remote set-url` command
  - User-facing migration clarity
  - **Recipe convention: "repo-migration-explicit-git-remote-command positive-signal"**
  - **NEW positive-signal convention** (Endurain 1st formally)
- **INSTITUTIONAL-STEWARDSHIP**: endurain-project org + Codeberg-primary + trademark-policy + Crowdin + demo + Mastodon + Discord + explicit-migration-guidance. **157th tool — self-hosted-fitness-with-trademark-policy sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + releases + demo + multi-channel + Crowdin + explicit-migration. **163rd tool in transparent-maintenance family.**
- **FITNESS-TRACKING-CATEGORY:**
  - **Endurain** — self-hosted; modern; trademarked
  - **Wger** — fitness/workout tracker
  - **GPX-viewer** (various) — simpler
  - **FitTrackee** — Python OSS
  - **Strava/Garmin Connect** — commercial SaaS
- **ALTERNATIVES WORTH KNOWING:**
  - **FitTrackee** — if you want Python + mature OSS
  - **Wger** — if you want strength-training focus
  - **Choose Endurain if:** you want modern + multi-sport + active-community + trademark-policy.
- **PROJECT HEALTH**: active + Codeberg-primary + Crowdin + demo + multi-channel. Strong.

## Links

- Repo (primary): <https://codeberg.org/endurain-project/endurain>
- Demo: <https://demo.endurain.com>
- FitTrackee (alt): <https://github.com/SamR1/FitTrackee>
