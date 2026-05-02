# Rangarr

**What it is:** A lightweight orchestration service that automates and staggers media searches across multiple *arr instances (Radarr, Sonarr, Lidarr). Prevents "thundering herd" issues by spacing out search requests, distributing load across instances and indexers, and respecting API limits.

**Official URL:** https://github.com/JudoChinX/rangarr
**Docker Hub:** `judochinx/rangarr`
**License:** MIT
**Stack:** Python 3.13+ (no database, no persistence layer); multi-arch (amd64/arm64)

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS / bare metal | Docker Compose | Recommended; sidecar to *arr stack |
| Any Linux VPS / bare metal | Docker run | Single container |
| Homelab | Docker Compose | Pairs well with existing *arr compose stack |

---

## Inputs to Collect

### Pre-deployment
- `config.yaml` — API keys and hostnames for each *arr instance (copy from `config.example.yaml`)
- `RADARR_API_KEY`, `SONARR_API_KEY`, `LIDARR_API_KEY` — from each *arr's Settings → General
- `RADARR_URL`, `SONARR_URL`, `LIDARR_URL` — use container hostnames in Docker Compose networks

### Runtime
- `interval` — search cycle frequency in seconds (default: `3600` = hourly)
- `missing_batch_size` / `upgrade_batch_size` — items per cycle (0=disabled, -1=unlimited, N=limit)
- `active_hours` — restrict searches to time window (e.g. `"22:00-06:00"` for overnight only)
- `include_tags` / `exclude_tags` — filter items by *arr tags

---

## Software-Layer Concerns

**Config:** `config.yaml` with `${ENV_VAR}` expansion for secrets. Can also skip the file and use environment variables only.

**No database:** Intentionally stateless — no SQLite, no persistence layer. All state comes from the *arr APIs.

**Docker Compose quick start:**
```bash
curl -O https://raw.githubusercontent.com/JudoChinX/rangarr/main/config.example.yaml
curl -O https://raw.githubusercontent.com/JudoChinX/rangarr/main/compose.example.yaml
mv config.example.yaml config.yaml
mv compose.example.yaml compose.yaml
chmod 644 config.yaml  # Required: container runs as UID 65532 (nonroot)
# Edit config.yaml with your *arr API keys and URLs
docker compose up -d
```

**Docker run:**
```bash
docker run -d \
  --name rangarr \
  --restart unless-stopped \
  -v ./config.yaml:/app/config/config.yaml:ro \
  judochinx/rangarr:latest
```

**File permissions:** Container runs as UID 65532 (nonroot). `config.yaml` must be world-readable (`chmod 644`).

**Upgrade procedure:**
1. `docker compose pull`
2. `docker compose up -d`

---

## Gotchas

- **`dry_run: true` first** — always start with dry run to verify config before triggering real searches
- **Docker networking:** Use container hostnames (e.g. `http://radarr:7878`) not `localhost` when Rangarr and *arr apps share a Docker network
- **Startup retries:** Rangarr retries connection 3 times with 10s delay — accounts for Docker Compose race conditions during stack startup
- **Custom format score awareness:** Finds Radarr/Sonarr items below their CF score target — items that `Cutoff Unmet` endpoint silently omits
- **Season pack support (Sonarr):** Groups searches by season with fallback to per-episode for still-airing seasons
- **No web UI** — config-only; check logs for activity: `docker compose logs -f rangarr`
- Privacy-focused by design — no telemetry, no external connections beyond configured *arr instances

---

## Links
- GitHub: https://github.com/JudoChinX/rangarr
- Docker Hub: https://hub.docker.com/r/judochinx/rangarr
- User Guide: https://github.com/JudoChinX/rangarr/blob/main/docs/user-guide.md
- Security model: https://github.com/JudoChinX/rangarr/blob/main/SECURITY.md
- Companion project Killarr: https://github.com/JudoChinX/killarr
