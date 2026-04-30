---
name: Kometa
description: "Python script for automated Plex/Jellyfin/Emby metadata management. Customizes artwork, titles, summaries, collections, overlays. Connects TMDb/Trakt/IMDb/MDBList. Paired with Sonarr/Radarr. MIT. Fork of PMM (renamed 2024). Active + large community."
---

# Kometa

Kometa is **"the script that makes your Plex / Jellyfin / Emby library look professional"** — an automation tool that gives you complete control over your media libraries' metadata, collections, and overlays. Connects to TMDb, Trakt, IMDb, MDBList + more to create one-of-a-kind curated collections (e.g., "Oscar Winners", "Trending Now", "Marvel Chronological") and artistic overlays (4K badges, rating badges, streaming-service logos, custom artwork). Pairs with Sonarr/Radarr to automate library growth. **Metadata stored outside your media server** — survives media-server DB loss and is portable between servers.

Built + maintained by **Kometa team** (meisnate12 + community). Previously known as **Plex Meta Manager (PMM)**; renamed to **Kometa** in April 2024 when scope broadened beyond Plex. **License: MIT**. Active; enormous community (Discord, Reddit, Wiki, Weblate translations); active development.

Use cases: (a) **Plex / Jellyfin / Emby power-user curation** — make your library look like a commercial streaming service (b) **Dynamic collections** — "this week's trending" + "movies leaving streaming soon" + thousands more (c) **4K/HDR/audio codec overlays** on poster artwork (d) **Sonarr/Radarr automation** — search for missing items in curated collections (e) **Multi-server sync** — same metadata across two Plex instances (f) **Recover from Plex-DB-loss** — replay Kometa → reapply collections/artwork (g) **Community-configs leverage** — thousands of pre-made configurations to import.

Features (from upstream README):

- **Library metadata customization** — artwork, titles, summaries
- **Collections** — dynamic + static, powerful filters
- **Overlays** — resolution, audio codec, streaming-service badges
- **Third-party integrations** — TMDb, Trakt, IMDb, MDBList, Letterboxd, MyAnimeList, AniDB, MusicBrainz, etc.
- **Sonarr + Radarr integration** — search for missing items
- **Kometa Defaults** — curated pre-made collections/overlays
- **Community Configs repo** — user-submitted configs for reuse
- **Translation support** via Weblate (many languages)
- **Docker + Python** runtime
- **Discord + Reddit + Wiki** community

- Upstream repo: <https://github.com/Kometa-Team/Kometa>
- Homepage / Wiki: <https://kometa.wiki>
- Docker Hub: <https://hub.docker.com/r/kometateam/kometa>
- Discord: <https://kometa.wiki/en/latest/discord/>
- Reddit: <https://reddit.com/r/kometa>
- Community Configs: <https://github.com/Kometa-Team/Community-Configs>
- Translations: <https://translations.kometa.wiki>
- Feature requests: <https://features.kometa.wiki>
- GitHub Sponsors: <https://github.com/sponsors/meisnate12>

## Architecture in one minute

- **Python script** — not a daemon; runs on schedule (cron/systemd timer/Docker with sleep)
- **Connects to**: Plex/Jellyfin/Emby APIs, TMDb API, Trakt API, IMDb, MDBList, etc.
- **Config file**: YAML — declares your libraries, collections, overlays, defaults
- **Resource**: moderate during runs — 500MB-2GB RAM depending on library size; heavy network I/O during metadata fetch

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **`kometateam/kometa:latest`**                                  | **Typical homelab path**                                                           |
| Python venv        | `pip install` then cron/systemd                                           | Bare-metal option                                                                                   |
| Unraid template    | Community Apps                                                                                    | Common homelab              |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Plex URL + token     | `http://plex:32400`, token                                  | **CRITICAL** | **Plex token = admin-level access**                                                                                    |
| TMDb API key         | Free at themoviedb.org                                      | Auth         | Required for most functionality                                                                                    |
| Trakt OAuth          | Optional but enables personalization                        | Auth         | User-level Trakt account                                                                                    |
| MDBList / IMDb       | API keys / scraping config                                                                           | Auth         | For specific list types                                                                                    |
| Sonarr/Radarr URL + key | Integration for missing-search                                                                                   | Integration  | Optional but powerful                                                                                                            |
| `config.yml`         | YAML with all Kometa configuration                                                                                      | **CRITICAL** | **The whole behavior is in here**                                                                                                                            |

## Install via Docker

```yaml
services:
  kometa:
    image: kometateam/kometa:latest    # **pin version** in prod
    container_name: kometa
    restart: unless-stopped
    environment:
      - TZ=UTC
      - KOMETA_RUN=true
      - KOMETA_RUN_ARGS=--run
    volumes:
      - ./kometa-config:/config   # config.yml + assets live here
```

## First boot

1. Copy `config.yml.template` to `config.yml`; fill in Plex URL + token + TMDb key
2. Define your libraries (Movies, TV, etc.)
3. Import Kometa Defaults for starter collections
4. Run manually first time: `docker exec kometa python kometa.py --run`
5. Inspect logs; fix config errors
6. Let it run full cycle; verify collections + overlays in Plex
7. Schedule (daily / weekly) via cron + `docker exec`
8. Explore Community Configs for more ideas

## Data & config layout

- `config.yml` — the BIG config file (hundreds-to-thousands of lines for power users)
- `assets/` — local artwork assets (if using custom images)
- `logs/` — execution logs (can get large over time)
- `meta/` — per-run metadata cache

## Backup

```sh
# Everything Kometa needs is in /config. DON'T BACK UP LOGS (huge).
sudo tar czf kometa-config-$(date +%F).tgz \
  --exclude='kometa-config/logs' \
  kometa-config/
```

## Upgrade

1. Releases: <https://github.com/Kometa-Team/Kometa/releases>. Very active; multiple-per-week.
2. Docker: pull + rerun.
3. **Config syntax evolves** — read release notes for breaking changes.
4. Keep backup of config.yml before major upgrades.
5. Kometa has `develop` + `nightly` branches for those who want bleeding edge.

## Gotchas

- **"SCRIPT NOT DAEMON" MENTAL MODEL**: Kometa is NOT a running service — it's a batch job that runs, modifies your library, and exits. Schedule it. Don't expect it to "watch" in real-time (though there are real-time patterns via webhooks + triggers).
- **PMM → KOMETA RENAME (2024)**: old docs/tutorials/forum posts reference "Plex Meta Manager" or "PMM". Same tool; new name. **Rebrand-preservation pattern** — 2nd tool with this framing (after GetCandy → Lunar batch 92). Watch for old docs + aliases.
- **PLEX TOKEN = ADMIN-LEVEL-ACCESS**: Kometa's config stores your Plex token which has FULL admin access to your Plex server. **44th tool in hub-of-credentials family — Tier 2** (because Kometa is a script; not a running web-attack-surface itself; but config file has crown-jewel creds).
- **TMDb / Trakt / MDBList API KEYS + OAuth**: additional creds in config.yml. Low-sensitivity individually but accumulate.
- **CONFIG.YML FILE PERMS**: 0600 + owned by Kometa user. Don't commit to public git (plex tokens leak = server compromise).
- **RATE LIMITS ON EXTERNAL APIS**:
  - **TMDb**: generous free-tier; rarely hit
  - **Trakt**: can be hit during full-library-initial-run
  - **MDBList**: rate-limited
  - **Kometa caches aggressively** to minimize API calls; respect it
- **RUN TIME**: for large libraries (10k+ movies/shows), a full Kometa run can take HOURS. Plan for this + don't run simultaneously with Plex library-scan.
- **ARTWORK OVERWRITES**: Kometa can OVERWRITE your existing Plex artwork. If you've manually curated posters, read Kometa docs carefully about what overrides what. **Wrong config can mass-replace your handmade collections.** Back up Plex DB before first serious Kometa run.
- **METADATA-STORED-OUTSIDE = SURVIVAL SIGNAL**: if your Plex DB dies, Kometa can rebuild your curation by re-running. **Recovery-from-media-DB-loss** as positive feature. Recipe convention: note this resilience framing.
- **DEV + NIGHTLY BRANCHES = BLEEDING EDGE AVAILABLE**: for power users. Stable is well-tested; `develop` for early access; `nightly` for pre-release. Standard branch hierarchy.
- **COMMUNITY CONFIGS REPO = ECOSYSTEM ASSET**: reinforces SWAG proxy-confs (batch 90), Homarr integrations (89), DVB shoutrrr (92), WUD notification-channels (92). **5th tool with ecosystem-asset-of-integration-library framing.**
- **LARGE COMMUNITY = DISCORD SUPPORT BACKBONE**: Kometa's Discord is very active; getting help is real. Positive community-signal.
- **MULTI-SERVER METADATA SYNC**: Kometa can manage multiple Plex servers — useful for "family + me" dual-server setups.
- **JELLYFIN + EMBY SUPPORT**: Kometa supports Jellyfin + Emby APIs beyond Plex (post-rename scope-broadening). Verify feature-parity — some features are Plex-first. For non-Plex use-case, check current docs.
- **WEBLATE TRANSLATIONS**: many-language support + community-driven translation. Positive international care signal.
- **MIT LICENSE**: permissive; commercial-reuse-friendly; no copyleft obligations.
- **SOLE-MAINTAINER → small-team + community model**: meisnate12 + contributors + large Discord. **Between sole-maintainer-with-community and emerging small-team.** **13th tool in sole-maintainer-with-community class** or **emerging-small-team**.
- **GITHUB SPONSORS funding**: ongoing sponsor-based support. **14th tool in pure-donation/community** (GitHub Sponsors via meisnate12).
- **TRANSPARENT-MAINTENANCE**: MIT + very-active-releases + large-community + Weblate + Feature-request-tracker + Wiki + extensive docs + version-badges. **24th tool in transparent-maintenance family.**
- **INSTITUTIONAL-STEWARDSHIP**: Kometa Team (not a legal entity but active team). **20th tool in institutional-stewardship family — transitional-from-sole-maintainer-to-team sub-tier** (emerging pattern; 1st explicit).
- **PLEX LEGAL-NUANCE**: Kometa is metadata-enhancement for media libraries. Plex itself is commercial + Kometa-users typically have legally-obtained media. **Neutral tool; legal-nuance lies with the underlying library**.
- **ALTERNATIVES WORTH KNOWING:**
  - **Tautulli** — Plex monitoring + stats (complementary, not alternative)
  - **Overseerr / Jellyseerr** — media-request systems (complementary)
  - **Recyclarr** — Radarr/Sonarr profile-tuning
  - **Profilarr** — similar
  - **Bazarr** — subtitle management
  - **MDBList** — curated list service (input to Kometa)
  - **Choose Kometa if:** you want POWERFUL + mature + PMM-descended + large-community + Plex-first-but-broader.
  - **There isn't really a direct alternative** at Kometa's power + community level. For simpler needs, just use Plex's built-in collection/artwork features.
- **PROJECT HEALTH**: very active + large community + Weblate + Wiki + Sponsors + MIT. Strong signals.

## Links

- Repo: <https://github.com/Kometa-Team/Kometa>
- Wiki: <https://kometa.wiki>
- Docker: <https://hub.docker.com/r/kometateam/kometa>
- Discord: <https://kometa.wiki/en/latest/discord/>
- Community Configs: <https://github.com/Kometa-Team/Community-Configs>
- Sponsors: <https://github.com/sponsors/meisnate12>
- Plex: <https://plex.tv>
- Jellyfin: <https://jellyfin.org>
- Emby: <https://emby.media>
- TMDb: <https://www.themoviedb.org>
- Trakt: <https://trakt.tv>
- MDBList: <https://mdblist.com>
- Overseerr (complement): <https://overseerr.dev>
- Jellyseerr (complement): <https://github.com/fallenbagel/jellyseerr>
- Tautulli (complement): <https://tautulli.com>
