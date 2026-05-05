# NZBHydra2

Meta search application for NZB indexers — a unified front-end that aggregates results from multiple Usenet indexer APIs (raw and Newznab/Torznab). Integrates directly with download clients like SABnzbd, NZBGet, Sonarr, and Radarr.

**Official site:** https://github.com/theotherp/nzbhydra2

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Docker Compose (LSIO) | Recommended; persistent config volume |
| Any Linux host | JAR / Java | Requires Java 17+; run as systemd service |
| Any platform | Docker (standalone) | Use `lscr.io/linuxserver/nzbhydra2` |

---

## Inputs to Collect

### Phase 1 — Planning
- Indexer API keys and URLs (Newznab/Torznab compatible)
- Download client type and API key (SABnzbd, NZBGet, etc.)
- Desired port (default `5076`)

### Phase 2 — Deployment
- Config data directory (bind-mount to `/config`)
- Optional NZB download directory (`/downloads`)
- `PUID` / `PGID` for file ownership

---

## Software-Layer Concerns

### Docker Compose

```yaml
services:
  nzbhydra2:
    image: lscr.io/linuxserver/nzbhydra2:latest
    container_name: nzbhydra2
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
    volumes:
      - /path/to/nzbhydra2/data:/config
      - /path/to/downloads:/downloads  # optional
    ports:
      - 5076:5076
    restart: unless-stopped
```

### Key Config (via Web UI at `http://<host>:5076`)
- **Indexers** — add Newznab/Torznab indexer URLs + API keys
- **Download clients** — configure SABnzbd/NZBGet connection (host, port, API key)
- **API key** — NZBHydra2 exposes its own Newznab-compatible API; configure Sonarr/Radarr to use `http://<host>:5076`

### Config Paths
| Path | Purpose |
|------|---------|
| `/config` | Application config, database (H2), logs |
| `/downloads` | Optional NZB file output directory |

### Environment Variables
| Variable | Default | Description |
|----------|---------|-------------|
| `PUID` | `1000` | User ID for file ownership |
| `PGID` | `1000` | Group ID for file ownership |
| `TZ` | `Etc/UTC` | Container timezone |

---

## Upgrade Procedure

```bash
docker compose pull nzbhydra2
docker compose up -d nzbhydra2
```

NZBHydra2 performs database migrations automatically on startup. Config and data in `/config` are preserved across upgrades.

---

## Gotchas

- **Java-based app** — larger memory footprint than comparable Go/Python apps; expect ~200-400 MB RAM.
- **H2 database** — stored in `/config`; not compatible with external Postgres. Back up the full `/config` directory.
- **API forwarding** — Sonarr/Radarr should point to NZBHydra2's Newznab endpoint (`http://<host>:5076/<api-path>/api`) not directly to indexers.
- **VPN usage** — if indexers require a specific IP, run NZBHydra2 behind a VPN container (e.g., `gluetun`).
- **LSIO tag `dev`** — tracks nzbhydra2 prereleases; only use in non-production setups.
- The original NZBHydra (v1) is abandoned; NZBHydra2 is the active successor.

---

## References
- GitHub: https://github.com/theotherp/nzbhydra2
- LSIO Docker image: https://docs.linuxserver.io/images/docker-nzbhydra2/
- Upstream docs/wiki: https://github.com/theotherp/nzbhydra2/wiki
