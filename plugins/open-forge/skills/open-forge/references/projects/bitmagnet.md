---
name: Bitmagnet
description: "Self-hosted BitTorrent indexer + DHT crawler + content classifier + torrent search engine. Crawls the public DHT network for torrent metadata; builds a searchable local index. GraphQL API + Servarr-stack integration. Go + Postgres. MIT-licensed. Legal-gray territory by design."
---

# Bitmagnet

Bitmagnet is **"your own private-operator BitTorrent search engine"** — it runs a **DHT crawler** that connects to the public BitTorrent Mainline DHT network and passively harvests torrent metadata (hashes, filenames, sizes) into a **local Postgres database** with a web UI + GraphQL API for searching. It also **classifies** harvested torrents (movies, TV, books, software, etc.) and can integrate with **Sonarr / Radarr / Prowlarr** as an "indexer" — giving your arr-stack a torrent search source that you operate yourself instead of relying on public tracker APIs.

**This is legal-gray territory by design.** Bitmagnet does not host content + does not download files; it only catalogs metadata that torrents announce publicly into DHT. Metadata indexing is analogous to how a search engine indexes public websites. But the predominant use of Bitmagnet is searching for + downloading copyrighted material. **Operating Bitmagnet ≠ operating a pirate tracker.** Using it to organize mass piracy = legal liability. **Read your jurisdiction; consult your own counsel if unsure.**

Built + maintained by **bitmagnet-io** (small team). **MIT-licensed**. Go + Postgres; distributed as Docker image.

Use cases: (a) **private search index** for BitTorrent — no reliance on rotating public-tracker URLs (b) **DHT research / analysis** — study the distribution of content on the DHT (c) **Servarr-stack integration** — replace brittle public indexers (d) **censorship-resistant search** — the DHT is not centralized.

Features:

- **DHT crawler** — passively harvests torrent metadata from DHT network
- **Content classification** — movies, TV, books, games, music, software, porn
- **Web UI** — search + browse + filter
- **GraphQL API** — structured access
- **Servarr-stack integration** — exposes as Prowlarr-compatible indexer
- **Observability** — Prometheus metrics + telemetry
- **Reprocess + reclassify** — re-run classifier as it improves
- **Backup + restore + merge** of torrent index databases (community-shared indexes)
- **Optional TMDB API key** — better metadata for movies/TV

- Upstream repo: <https://github.com/bitmagnet-io/bitmagnet>
- Homepage + docs: <https://bitmagnet.io>
- Installation: <https://bitmagnet.io/setup/installation.html>
- Configuration: <https://bitmagnet.io/setup/configuration.html>
- Servarr integration: <https://bitmagnet.io/guides/servarr-integration.html>
- Endpoints: <https://bitmagnet.io/guides/endpoints.html>
- Classifier: <https://bitmagnet.io/guides/classifier.html>
- Full-featured compose (VPN + observability): <https://github.com/bitmagnet-io/bitmagnet/blob/main/docker-compose.yml>
- Discord: <https://discord.gg/6mFNszX8qM>
- OpenCollective: <https://opencollective.com/bitmagnet>

## Architecture in one minute

- **Go** application — multiple workers: `http_server`, `queue_server`, `dht_crawler`
- **PostgreSQL 16** — index database (can be LARGE; millions of rows)
- **Resource**: DHT crawler is network-heavy + Postgres storage-heavy; expect steady bandwidth + GB-to-TB disk over time
- **BitTorrent ports**: `3334/tcp` + `3334/udp` for DHT protocol; must be reachable (port-forward or use VPN with port-forwarding)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Docker Compose     | **Upstream minimal + full examples**                            | **Primary path**                                                                   |
| Go install         | `go install github.com/bitmagnet-io/bitmagnet` — needs external Postgres   | For developers                                                                             |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Postgres             | Postgres 16                                                 | DB           | `shm_size: 1g` recommended; DB grows fast                                                                     |
| `POSTGRES_PASSWORD`  | strong random                                                           | Secret       | DB auth                                                                                    |
| BitTorrent ports     | 3334 TCP+UDP                                                                    | Network      | **Must be reachable** for DHT; port-forward or VPN                                                                                    |
| `TMDB_API_KEY` (opt) | Free TMDB API key                                                                                       | Enrichment   | Better movie/TV classification                                                                                                              |
| VPN container (opt)  | Gluetun / PIA / NordVPN                                                                                                           | Network      | Route traffic through VPN with port-forwarding enabled                                                                                                                      |

## Install via Docker Compose (minimal — from upstream)

```yaml
services:
  bitmagnet:
    image: ghcr.io/bitmagnet-io/bitmagnet:latest     # **pin version**
    container_name: bitmagnet
    ports:
      - "3333:3333"               # web UI + API
      - "3334:3334/tcp"           # BitTorrent
      - "3334:3334/udp"           # BitTorrent
    restart: unless-stopped
    environment:
      - POSTGRES_HOST=postgres
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      # - TMDB_API_KEY=${TMDB_API_KEY}
    volumes:
      - ./config:/root/.config/bitmagnet
    command:
      - worker
      - run
      - --keys=http_server
      - --keys=queue_server
      - --keys=dht_crawler
    depends_on:
      postgres: { condition: service_healthy }

  postgres:
    image: postgres:16-alpine
    container_name: bitmagnet-postgres
    volumes: [./data/postgres:/var/lib/postgresql/data]
    restart: unless-stopped
    environment:
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=bitmagnet
      - PGUSER=postgres
    shm_size: 1g
    healthcheck:
      test: [CMD-SHELL, pg_isready]
      start_period: 20s
      interval: 10s
```

Upstream full example (VPN + observability): <https://github.com/bitmagnet-io/bitmagnet/blob/main/docker-compose.yml>.

## First boot

1. `docker compose up -d`
2. Browse `http://host:3333` → web UI
3. Within ~1 minute DHT crawler should start adding torrents
4. Configure Servarr integration: <https://bitmagnet.io/guides/servarr-integration.html>
5. (opt) TMDB API key for better classification
6. Back up Postgres + config
7. Monitor: size of DB grows steadily (10s of GB in first week)

## Data & config layout

- **Postgres** — the index; **grows unboundedly**
- `/root/.config/bitmagnet/` — config files
- Logs to stdout

## Backup

```sh
pg_dump -Fc -U postgres bitmagnet > bitmagnet-$(date +%F).dump
# Or use community-shared index dumps — see upstream backup-restore-merge guide
```

## Upgrade

1. Releases: <https://github.com/bitmagnet-io/bitmagnet/releases>. Active.
2. `docker compose pull && docker compose up -d`
3. Back up Postgres before major versions.
4. Schema migrations run automatically.

## Gotchas

- **Legal risk: this is where a good lawyer becomes your friend.** Bitmagnet harvests metadata, not content. BUT:
  - **Operating a "torrent search engine" attracts rightsholder attention** even if you only index metadata. Takedown notices, ISP complaints, and in some jurisdictions direct liability. **Running a public bitmagnet instance = large target.**
  - **DHT traffic is observable** by your ISP. If you participate in swarms for infringing content (Bitmagnet itself does not, but close cousin tools will), your IP appears in swarm member lists + gets logged by copyright enforcement.
  - **Public vs private instance**: keep it private + auth-gated + personal use + behind VPN → much lower profile. Expose it publicly → actively risky.
  - **Jurisdiction dependent**: DE/FR/UK/US/AU are particularly aggressive on P2P enforcement. Other jurisdictions vary. Know yours.
  - **This is the same public-service-abuse-magnet / legal-risk family as:**
    - Unbound open-resolver (batch 80) — DNS amplification abuse
    - AnonAddy email-forwarding (79) — spam + phishing
    - MicroBin pastebin (81) — phishing-URL hosting
    - Fider public board (82) — spam
    - 13ft-ladder paywall bypass (83) — TOS violation
    - **Bitmagnet indexer** (this batch) — copyright + contributory-infringement exposure
    - **Sixth tool** in the legal-risk class. Pattern fully mature at 6.
- **Bandwidth + storage cost**: DHT crawler = constant low-level traffic. Postgres DB grows 1-10 GB/week depending on how aggressive the crawler is. Not free to operate.
- **BitTorrent ports must be reachable**: NAT / port-forward / VPN-with-port-forwarding required. Without reachability, the crawler gets much lower yield.
- **VPN with port-forwarding** is the common operational pattern: route bitmagnet traffic through a VPN that supports port-forwarding (Mullvad / AirVPN / ProtonVPN Pro) so your home IP doesn't show up in DHT. Upstream's full compose example demonstrates gluetun-integrated VPN.
- **Classification accuracy varies** — the classifier does heuristic analysis of filenames. Books-vs-software-vs-porn boundaries are fuzzy. TMDB key helps movies/TV. Expect ~90% accuracy.
- **Servarr-stack integration** requires Prowlarr setup. Add Bitmagnet as a custom indexer in Prowlarr → Prowlarr relays to Sonarr/Radarr. Not trivially turnkey but well-documented in upstream guides.
- **Reprocess-and-reclassify** is a useful feature — as the classifier improves, you can re-run it on your historical index to benefit from better categorization. Takes time on large DBs.
- **Backup-restore-merge workflow** lets multiple bitmagnet operators share index dumps, reducing cold-start time. Upstream has a documented format.
- **GraphQL API** is well-structured — good for integrations (write your own UI, export to CSV, cross-reference with other catalogs).
- **Observability built-in**: Prometheus metrics + upstream full-example compose ships an observability stack. Nice OSS hygiene.
- **OpenCollective-funded** — transparency pattern. Small team + sponsors.
- **Project health**: active + MIT + fundraised-transparent + small operator-community. Growing niche.
- **Alternatives worth knowing:**
  - **Jackett** — metasearch-indexer-as-a-proxy to public trackers (doesn't crawl DHT itself)
  - **Prowlarr** — successor to Jackett (Servarr-family); aggregates many indexers
  - **DHT crawlers** (academic / research): magnetico (old, unmaintained), btdig (public search engine)
  - **Public torrent search engines**: TPB, 1337x, etc. — NOT self-hostable; subject to takedown + domain-hopping
  - **Choose Bitmagnet if:** you want a self-operated DHT-based torrent search + Servarr integration + willing to own the legal posture.
  - **Choose Prowlarr if:** you want proxy-to-public-indexers without running a DHT crawler yourself.

## Links

- Repo: <https://github.com/bitmagnet-io/bitmagnet>
- Homepage: <https://bitmagnet.io>
- Installation: <https://bitmagnet.io/setup/installation.html>
- Configuration: <https://bitmagnet.io/setup/configuration.html>
- Servarr integration: <https://bitmagnet.io/guides/servarr-integration.html>
- Classifier: <https://bitmagnet.io/guides/classifier.html>
- Observability: <https://bitmagnet.io/guides/observability-telemetry.html>
- Discord: <https://discord.gg/6mFNszX8qM>
- OpenCollective: <https://opencollective.com/bitmagnet>
- Prowlarr (alt — Servarr indexer manager): <https://github.com/Prowlarr/Prowlarr>
- Jackett (alt, older): <https://github.com/Jackett/Jackett>
- TMDB (metadata source): <https://www.themoviedb.org>
