---
name: MediaManager
description: "Modern successor to the fragmented *arr stack — unified TV/movie library management. OAuth/OIDC, TVDB+TMDB, Docker-first. Sole-maintainer by maxdorninger with active sponsorship. License: MIT/similar permissive (verify). Rising star in homelab media-management space."
---

# MediaManager

MediaManager is **"the unified replacement for the *arr stack"** — Sonarr + Radarr + Bazarr + Prowlarr + Readarr etc. rolled into one simple interface. Manage, discover, and automate your TV and movie collection in a single place. OAuth/OIDC SSO out of the box (rare in *arr-style tools). TVDB + TMDB integration. Docker-first deployment. Growing fast; sponsor-backed; sole-maintainer-with-community pattern.

Built + maintained by **Maximilian Dorninger (maxdorninger)** + sponsors + contributors. License: check repo (readme badges suggest permissive; verify LICENSE file). Active; GitHub Sponsors + Buy-Me-a-Coffee funding; documentation site + Docker Hub releases.

Use cases: (a) **replace the *arr stack** with unified interface — less context-switching between Sonarr/Radarr/Bazarr/Prowlarr (b) **simpler onboarding** for new homelab media users who find *arr overwhelming (c) **OAuth/OIDC integration** — rare luxury in media-management tooling (d) **modern Docker deployment** — one compose file vs 5+ separate *arrs (e) **TVDB + TMDB metadata** — integrated from start (f) **growing ecosystem** — new + responsive maintainer.

Features (from upstream README):

- **OAuth/OIDC support** (single-sign-on)
- **TVDB and TMDB** metadata
- **Docker-first** deployment
- **Unified TV + movies** in one interface
- Active development + sponsors + community

- Upstream repo: <https://github.com/maxdorninger/MediaManager>
- Docs: <https://maxdorninger.github.io/MediaManager/>
- GitHub Sponsors: <https://github.com/sponsors/maxdorninger>
- BuyMeACoffee: <https://buymeacoffee.com/maxdorninger>
- Releases: <https://github.com/maxdorninger/MediaManager/releases>

## Architecture in one minute

- **Docker**-deployed (compose.yaml + config.toml)
- Stack specifics in upstream docs (check for backend language, DB)
- **Resource**: moderate — similar to running *arr stack; 500MB-1GB RAM
- **Port**: per config.toml

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker compose** | **Upstream-provided `docker-compose.yaml` + `config.toml`**     | **Primary + only documented path**                                                  |
| Bare-metal         | Not clearly documented                                                    | DIY; read source                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| `config.toml`        | Main MediaManager config                                    | **CRITICAL** | **Edit per docs**                                                                                    |
| Media library paths  | `/mnt/media/tv`, `/mnt/media/movies`                        | Storage      | Bind-mount appropriately                                                                                    |
| TVDB + TMDB API keys | Free signups                                                | Auth         | For metadata                                                                                    |
| OAuth/OIDC config    | (optional) Authentik/Keycloak/Google                                                                           | SSO          | Built-in                                                                                    |
| Download client      | NZBGet, SABnzbd, qBittorrent, Transmission, etc.                                                                                           | Integration  | For automation                                                                                                            |
| Indexers             | Jackett / Prowlarr / newznab direct                                                                                              | Integration  | Typical indexer stack                                                                                                                            |

## Install via Docker (upstream quick-start)

```sh
wget -O docker-compose.yaml https://github.com/maxdorninger/MediaManager/releases/latest/download/docker-compose.yaml
mkdir config
wget -O ./config/config.toml https://github.com/maxdorninger/MediaManager/releases/latest/download/config.example.toml
# Edit config.toml per docs
docker compose up -d
```

**Pin to specific release rather than `latest/`** in production — replace `/releases/latest/download/` with `/releases/download/vX.Y.Z/`.

## First boot

1. Follow upstream quick-start; edit `config.toml`
2. Start; browse web UI
3. Create admin account (or OIDC log in)
4. Add TVDB + TMDB keys
5. Add download clients
6. Add indexers
7. Add media library paths
8. Add first show/movie; verify end-to-end workflow
9. Put behind TLS reverse proxy (OIDC-compat)
10. Back up config + DB

## Data & config layout

- `./config/` — config.toml + DB + local state
- Media paths — bind-mounted from host storage

## Backup

```sh
sudo tar czf mediamanager-config-$(date +%F).tgz config/
```

## Upgrade

1. Releases: <https://github.com/maxdorninger/MediaManager/releases>. Active + newer project.
2. Docker: pull + restart.
3. **Pre-1.0 velocity likely** — read release notes for config-schema changes.
4. Back up config before major version bumps.

## Gotchas

- **"SUCCESSOR TO FRAGMENTED *ARR STACK" is a BOLD CLAIM** — the *arr stack is mature, well-documented, battle-tested over 7+ years, with enormous plugin/integration ecosystem. MediaManager is **newer + less-proven**. Positives:
  - **Unified UX** — one tool to learn
  - **OIDC built-in** — easier enterprise/family auth
  - **Modern codebase + maintainer** — fewer legacy-compromise
  - Negatives:
  - **Newer = fewer features + less battle-tested**
  - **Smaller ecosystem** — fewer scripts/integrations
  - **Sole-maintainer-sustainability-risk** — if Max burns out, project may stall
  - **Feature parity with Sonarr/Radarr/Prowlarr? Verify current state** — don't assume feature-complete
- **RECIPE CONVENTION: "New-unified-replacement-for-mature-stack" framing** (MediaManager → *arr stack): similar pattern reconciled before with Kaneo 93 vs Jira/Trello. Recipe convention: acknowledge mature-incumbent + be honest about maturity-gap. Applicable to: MediaManager (→*arr), Kaneo (→Jira), Wanderer (→AllTrails, batch 91), and many "modern replacement" tools.
- **OIDC BUILT-IN = SIGNIFICANT DIFFERENTIATOR**: *arr stack has historically had weak/no native SSO (reverse-proxy header auth hacks). MediaManager's native OIDC is a real upgrade. Integrates with Authentik, Keycloak, Google, etc.
- **HUB-OF-CREDENTIALS TIER 2**: MediaManager stores:
  - Download client API keys (Sonarr/Radarr/etc. already do this)
  - Indexer credentials + API keys
  - TVDB/TMDB API keys
  - OIDC client secrets
  - User accounts (if not OIDC-only)
  - **49th tool in hub-of-credentials family — Tier 2.**
- **NETWORK-SERVICE-LEGAL-RISK = *ARR-PIRACY-TOOLING SUB-FAMILY INHERITANCE**: MediaManager is architecturally identical to *arr stack in its relationship with piracy tooling:
  - Integrates with usenet + torrent indexers
  - Automates downloads from private trackers + usenet providers
  - DMCA / copyright-infringement liability patterns apply identically
  - **16th tool in network-service-legal-risk family** joining Readarr 93 (*arr-piracy-tooling sub-family). **Legal-profile inherits from *arr stack.**
- **SONARR/RADARR CONFIG MIGRATION PATHWAY** — worth checking if MediaManager offers importers from Sonarr/Radarr DBs. If yes: easy transition; if no: manual re-entry of hundreds of shows/movies. **Recipe-worthy checklist: "migration-from-incumbent" status.**
- **SOLE-MAINTAINER with sponsor support + community**: Max Dorninger + GitHub Sponsors + BMC + visible sponsor wall. **16th tool in sole-maintainer-with-community class.** Multiple sponsor-funding sources but no commercial-Cloud tier (yet). Sustainability model = donations + sponsorship.
- **DIFFERENT FROM SOLE-MAINTAINER-WITH-COMMERCIAL-CLOUD-FUNDING**: MediaManager has donor/sponsor support but NOT a commercial Cloud tier (like LinkAce 95, Kaneo 93, Ryot 95 have). **Sub-tier variance**: donation-only vs Cloud-commercialized. **Pattern: "sole-maintainer-with-visible-sponsor-support"** — healthier than sole-maintainer-with-no-backing; less-sustainable than commercial-Cloud-funding. Could name **4th sub-tier of institutional-stewardship: "sole-maintainer-with-visible-sponsor-support"**.
- **TRANSPARENT-MAINTENANCE**: active + docs site + releases + sponsor wall + acknowledgement of contributors. **31st tool in transparent-maintenance family.**
- **INSTITUTIONAL-STEWARDSHIP**: Max as sole-maintainer with visible sponsor-support. **26th tool** — new sub-tier: **sole-maintainer-with-visible-sponsor-support** (distinct from Cloud-tier and pure-donation).
- **LICENSE CHECK MANDATORY**: the README doesn't clearly state license; users should verify `LICENSE` file before commercial/enterprise use. **Recipe convention: when license is not stated in README, flag "LICENSE file verification required".**
- **MUTABILITY OF CONFIG-TOML FORMAT**: new project; config schema may evolve. Pin versions; read release notes.
- **METADATA CACHE CAN GROW**: TVDB + TMDB caches + artwork downloads. Monitor disk usage.
- **ALTERNATIVES WORTH KNOWING:**
  - **Sonarr / Radarr / Prowlarr / Bazarr / Readarr-retired 93** — mature *arr stack
  - **Jellyfin / Emby + built-in metadata agents** — media-server-with-integrated-management (different scope)
  - **Plex with plugins** — legacy plugin ecosystem
  - **Kometa 95** — metadata-layer-on-top-of-Plex-Jellyfin (different niche: artwork/collections)
  - **Radarr-fork-variants** — more *arr-family
  - **tinyMediaManager (tMM)** — metadata-scraping-tool (GUI app, not library-manager)
  - **Choose MediaManager if:** you want NEW+UNIFIED+OIDC + are OK with early-stage + sole-maintainer-sustainability-risk.
  - **Choose *arr stack if:** you want MATURE+BATTLE-TESTED + accept fragmented-UX + strong community.
  - **Choose Kometa if:** you want metadata-layer-supplement (complementary, not replacement).
- **PROJECT HEALTH**: active + sponsor-backed + docs-site + rising-star. Sustainability trajectory depends on maintainer continuation + community growth.

## Links

- Repo: <https://github.com/maxdorninger/MediaManager>
- Docs: <https://maxdorninger.github.io/MediaManager/>
- Sponsors: <https://github.com/sponsors/maxdorninger>
- Sonarr (alt, mature): <https://sonarr.tv>
- Radarr (alt, mature): <https://radarr.video>
- Prowlarr (alt, indexer-manager): <https://prowlarr.com>
- Bazarr (alt, subtitles): <https://www.bazarr.media>
- Kometa (complement): <https://kometa.wiki>
- TVDB: <https://thetvdb.com>
- TMDB: <https://www.themoviedb.org>
