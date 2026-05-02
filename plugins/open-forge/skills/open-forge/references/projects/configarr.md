# Configarr

**Sync TRaSH Guides custom formats and quality profiles to Sonarr/Radarr automatically.**

- **Official site:** https://configarr.de
- **GitHub:** https://github.com/raydak-labs/configarr
- **License:** MIT

## What It Is

Configarr is an open-source automation tool that keeps Sonarr and Radarr configuration in sync with TRaSH Guides — a community-maintained collection of optimal custom formats and quality profiles for media servers. It runs as a one-shot job (or on a schedule) and applies custom formats, quality profiles, and settings without manual intervention. It is similar to Recyclarr but adds support for additional configuration sources beyond TRaSH Guides.

**Supported \*arr apps:** Radarr v5, Sonarr v4 (official); Whisparr, Readarr, Lidarr (experimental)

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any VPS/VM | Docker (one-shot / cron) | Primary deployment; run on schedule |
| Any VPS/VM | Kubernetes CronJob | Supported |
| Local | `pnpm start` | Dev/test usage |

## Inputs to Collect

### All phases
- Sonarr/Radarr base URLs and API keys
- `config.yml` — defines which profiles/CFs to sync
- `secrets.yml` — stores API keys and sensitive values (referenced via `!secret` tags)

## Software-Layer Concerns

- **Images:**
  - GHCR: `ghcr.io/raydak-labs/configarr:latest`
  - Docker Hub: `configarr/configarr:latest`
- **Config files:** `config.yml` and `secrets.yml` — mount into container at `/app/config/`
- **Config format:** YAML with custom tags:
  - `!secret secretKey` — reads from `secrets.yml`
  - `!env ENV_NAME` — reads from environment variable
  - `!file FILE_NAME` — reads from a file path
- **TRaSH Guides sync:** Pulled at runtime from the official TRaSH Guides repository
- **Custom formats:** Local CFs can be merged on top of TRaSH Guides CFs

### Minimal docker-compose.yml (run as one-shot)
```yaml
services:
  configarr:
    image: ghcr.io/raydak-labs/configarr:latest
    container_name: configarr
    restart: "no"    # run once; use cron or Docker restart for scheduling
    volumes:
      - ./config/config.yml:/app/config/config.yml:ro
      - ./config/secrets.yml:/app/config/secrets.yml:ro
    environment:
      CONFIG_LOCATION: /app/config/config.yml
      SECRETS_LOCATION: /app/config/secrets.yml
      LOG_LEVEL: info
```

### Key environment variables
```
CONFIG_LOCATION=/app/config/config.yml
SECRETS_LOCATION=/app/config/secrets.yml
DRY_RUN=true          # test without applying changes
LOG_LEVEL=info        # debug | info | warn | error
TELEMETRY_ENABLED=false
```

## Upgrade Procedure

1. Pull the new image: `docker compose pull`
2. Review the [CHANGELOG](https://github.com/raydak-labs/configarr/blob/main/CHANGELOG.md) for breaking config changes
3. Update `config.yml` if needed
4. Re-run: `docker compose run --rm configarr`

## Gotchas

- **One-shot by design:** Configarr is not a persistent daemon — run it on a schedule (cron, Kubernetes CronJob, or Docker restart policy) rather than `restart: always`
- **Dry run first:** Always test with `DRY_RUN=true` on a new config before applying to production Sonarr/Radarr
- **Sonarr v4 / Radarr v5 only:** Older versions are not officially supported
- **secrets.yml permissions:** Keep this file out of version control; it contains your \*arr API keys
- **TRaSH Guides sync on every run:** Internet access required at runtime to pull the latest guides from GitHub

## References

- Docs: https://configarr.de/docs
- Feature comparison: https://configarr.de/docs/comparison
- Config template: https://github.com/raydak-labs/configarr/blob/main/config.yml.template
- README: https://github.com/raydak-labs/configarr/blob/main/README.md
