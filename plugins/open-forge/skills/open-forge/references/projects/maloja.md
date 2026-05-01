---
name: Maloja
description: "Simple self-hosted music scrobble database for personal listening statistics. Associated-artists + multi-artist tracks + custom images + proxy scrobble + standard-compliant API. Python. PyPI + Docker. krateng/maloja."
---

# Maloja

Maloja is **"Last.fm / ListenBrainz — but self-hosted + simple + no-social-gimmicks"** — a self-hosted music-scrobble database for personal listening statistics. **Associated artists** (collaborations, side projects), **multi-artist track decomposition**, **custom images**, **proxy scrobbling** (forward to other services), **standard-compliant API** (works with Last.fm-compat apps), **manual scrobbling** for vinyl/non-digital listening.

Built + maintained by **krateng**. Python. PyPI + Docker Hub + GitHub releases. Example live instance at maloja.krateng.ch.

Use cases: (a) **personal Last.fm replacement** (b) **self-hosted listening stats** (c) **vinyl-listening manual log** (d) **collaboration-aware artist stats** (e) **proxy-scrobble to multiple services** (f) **privacy-preserving music history** (g) **Navidrome + Maloja + Jellyfin scrobble-pipeline** (h) **listening-habit archive over years**.

Features (per README):

- **Self-hosted** — data ownership
- **Associated artists** — collaborations + subunits tracked
- **Multi-artist tracks** — each artist competes in charts
- **Custom images** — user-uploadable artist art
- **Proxy scrobble** — forward to Last.fm / etc.
- **Standard-compliant API** — Last.fm-compat
- **Manual scrobbling** — for vinyl / analog
- **Keep it simple** — no social / radio / recommendations

- Upstream repo: <https://github.com/krateng/maloja>
- PyPI: <https://pypi.org/project/malojaserver/>
- Docker Hub: <https://hub.docker.com/r/krateng/maloja>
- Example instance: <https://maloja.krateng.ch>

## Architecture in one minute

- **Python** (PyPI + Docker)
- Local DB
- Scrobble ingest API (Last.fm-compat)
- **Resource**: very low
- **Port**: HTTP

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | `krateng/maloja`                                                                                                       | **Primary**                                                                                   |
| **PyPI**           | `pip install malojaserver`                                                                                             | Alt                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `music-stats.example.com`                                   | URL          | TLS                                                                                    |
| API key              | For scrobble clients                                        | Secret       | Configure scrobblers                                                                                    |
| Proxy scrobble       | Last.fm creds (optional)                                    | Secret       | If forwarding                                                                                    |

## Install via Docker

Per README:
```yaml
services:
  maloja:
    image: krateng/maloja:latest        # **pin**
    ports: ["42010:42010"]
    volumes:
      - ./maloja-data:/mljdata
    restart: unless-stopped
```

## First boot

1. Start
2. Generate + save API key
3. Configure music clients (Navidrome / Funkwhale / Plex with scrobble plugin / mobile apps) to scrobble to Maloja
4. (Optional) enable proxy-scrobble to Last.fm
5. Let data accumulate
6. Explore charts + custom-image uploads
7. Put behind TLS
8. Back up `/mljdata`

## Data & config layout

- `/mljdata/` — DB + custom images + config

## Backup

```sh
sudo tar czf maloja-$(date +%F).tgz maloja-data/
# Contents: YEARS of listening history — valuable personal-historical data
# **ENCRYPT**
```

## Upgrade

1. Releases: <https://github.com/krateng/maloja/releases>
2. Docker pull + restart or `pip install -U`
3. Schema migrations auto

## Gotchas

- **196th HUB-OF-CREDENTIALS Tier 3 — LISTENING-HISTORY-DECADE-ARCHIVE**:
  - Holds: year-over-year listening-history (behavioral PII — mood patterns via music, life-events via play spikes)
  - Proxy-scrobble creds if enabled (Last.fm tokens)
  - API keys for client scrobblers
  - **196th tool in hub-of-credentials family — Tier 3**
- **LISTENING-HISTORY-BEHAVIORAL-PII**:
  - Music choices ~ mood + life-events
  - Long-term aggregate = longitudinal PII
  - **Recipe convention: "listening-history-PII-retention-discipline"** — reinforces Swing Music (124)
- **PROXY-SCROBBLE-CREDENTIAL-MANAGEMENT**:
  - If forwarding to Last.fm etc., those tokens live in Maloja
  - **Recipe convention: "proxy-scrobble-upstream-credential-discipline callout"**
  - **NEW recipe convention** (Maloja 1st formally)
- **STANDARD-COMPLIANT-API**:
  - Last.fm API compat means broad client ecosystem
  - **Recipe convention: "standard-protocol-broad-client-ecosystem positive-signal"** — reinforces Wolf (125), Movim (120)
- **MANUAL-SCROBBLE-FEATURE**:
  - Vinyl + elevator music
  - Acknowledging real-world analog listening
  - **Recipe convention: "analog-manual-event-entry-option positive-signal"**
  - **NEW positive-signal convention** (Maloja 1st formally)
- **KEEP-IT-SIMPLE-PHILOSOPHY**:
  - Explicit anti-bloat design philosophy
  - **Recipe convention: "explicit-product-philosophy-design-choice"** — reinforces Beaver Habit (127), TimeTagger (128)
  - **Explicit-product-philosophy-design-choice: 3 tools** 🎯 **3-TOOL MILESTONE** (Beaver Habit + TimeTagger + Maloja)
- **TRIPLE-DISTRIBUTION (GitHub + PyPI + Docker)**:
  - Three channels
  - **Recipe convention: "triple-distribution-GitHub-PyPI-Docker positive-signal"**
  - **NEW positive-signal convention** (Maloja 1st formally)
- **OWN-INSTANCE-AS-EXAMPLE**:
  - Author runs maloja.krateng.ch openly
  - **Recipe convention: "author-runs-public-instance-as-reference positive-signal"**
  - **NEW positive-signal convention** (Maloja 1st formally — good "eats own dog food" signal)
- **ASSOCIATED-ARTISTS-TOPOLOGY**:
  - Unique data-model (collaborations)
  - **Recipe convention: "graph-topology-custom-data-model neutral-signal"**
  - **NEW neutral-signal convention** (Maloja 1st formally)
- **INSTITUTIONAL-STEWARDSHIP**: krateng sole-dev + triple-distribution + example-instance + docs + active-dev. **182nd tool — sole-dev-data-archiver-tool sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + triple-distribution + example-instance + releases. **188th tool in transparent-maintenance family.**
- **SCROBBLE-TOOL-CATEGORY:**
  - **Maloja** — simple; associated-artists; multi-artist; self-hosted
  - **ListenBrainz** — MusicBrainz foundation; open-data
  - **Last.fm** — commercial; dominant
  - **OpenScrobbler** — scrobble-forwarder-only
- **ALTERNATIVES WORTH KNOWING:**
  - **ListenBrainz** — if you want open-data + contribution
  - **Last.fm** — if you want commercial + social
  - **Choose Maloja if:** you want self-hosted + simple + no-gimmicks.
- **PROJECT HEALTH**: active + mature + triple-distro + example-instance. Strong.

## Links

- Repo: <https://github.com/krateng/maloja>
- Example: <https://maloja.krateng.ch>
- ListenBrainz (alt): <https://github.com/metabrainz/listenbrainz-server>
