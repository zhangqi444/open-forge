# Scraparr

Scraparr is a Prometheus exporter for the *arr suite (Sonarr, Radarr, Lidarr, Readarr, Prowlarr, Bazarr, etc.). It exposes detailed metrics that can be scraped by Prometheus to monitor and visualize the health and performance of your *arr applications.

- **Official site / docs:** https://github.com/thecfu/scraparr
- **Docker image:** `ghcr.io/thecfu/scraparr` (also: `thegameprofi/scraparr` on Docker Hub)
- **License:** Open-source

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Docker host | Docker Compose | Single container, lightweight Python exporter |
| Kubernetes | Helm | Community-maintained chart via imgios/scraparr |

---

## Inputs to Collect

### Deploy Phase
| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `SONARR_URL` | No | — | Sonarr base URL (e.g. `http://sonarr:8989`) |
| `SONARR_API_KEY` | No | — | Sonarr API key |
| `RADARR_URL` | No | — | Radarr base URL |
| `RADARR_API_KEY` | No | — | Radarr API key |
| `PROWLARR_URL` | No | — | Prowlarr base URL |
| `PROWLARR_API_KEY` | No | — | Prowlarr API key |
| `BAZARR_URL` | No | — | Bazarr base URL |
| `BAZARR_API_KEY` | No | — | Bazarr API key |
| `GENERAL_ADDRESS` | No | `0.0.0.0` | Bind address |
| `GENERAL_PORT` | No | `7100` | Metrics server port |
| `GENERAL_PATH` | No | `/metrics` | Prometheus scrape path |
| `AUTH_USERNAME` | No | — | Optional basic auth username |
| `AUTH_PASSWORD` | No | — | Optional basic auth password |
| `AUTH_TOKEN` | No | — | Optional bearer token |

Configure *arr services via `config.yaml` (mounted into container) or environment variables.
See `sample.env` for all supported vars including per-service ALIAS, API_VERSION, INTERVAL, and DETAILED settings.

---

## Software-Layer Concerns

### Config
- Primary config: `config.yaml` mounted at `/app/src/scraparr/config/config.yaml`
- Alternatively, configure fully via environment variables (see `sample.env`)
- Supports multiple instances of each *arr app via YAML config

### Data Directories
- No persistent data directory required — stateless exporter
- Metrics generated on-the-fly at scrape time

### Ports
- `7100` — Prometheus metrics endpoint (configurable)

### Networking
- Must be on same Docker network as *arr services (or use external URLs)
- Prometheus must be configured to scrape `http://<scraparr-host>:7100/metrics`

---

## Minimal docker-compose.yml

```yaml
services:
  scraparr:
    image: ghcr.io/thecfu/scraparr
    container_name: scraparr
    ports:
      - "7100:7100"
    volumes:
      - ./config.yaml:/app/src/scraparr/config/config.yaml
    restart: unless-stopped
```

Or with env vars only (no config.yaml):
```yaml
services:
  scraparr:
    image: ghcr.io/thecfu/scraparr
    container_name: scraparr
    ports:
      - "7100:7100"
    environment:
      SONARR_URL: http://sonarr:8989
      SONARR_API_KEY: your_sonarr_api_key
      RADARR_URL: http://radarr:7878
      RADARR_API_KEY: your_radarr_api_key
    restart: unless-stopped
```

---

## Upgrade Procedure

```bash
docker compose pull scraparr
docker compose up -d scraparr
```

No database migrations required — stateless service.

---

## Gotchas

- **Config vs env vars:** Both methods work; config.yaml allows more advanced per-service settings (aliases, API versions, intervals)
- **API versions:** Default is v3 for most *arr apps; set explicitly if you hit issues
- **Network access:** Scraparr must be able to reach your *arr services — use Docker networks or host networking
- **v1 users:** Config format changed from v1 — see the v1 branch README
- **`main` tag:** Use `:main` image tag to get new features before stable release
- **Kubernetes:** Community Helm chart available at https://github.com/imgios/scraparr

---

## References
- README & docs: https://github.com/thecfu/scraparr
- sample.env: https://raw.githubusercontent.com/thecfu/scraparr/HEAD/sample.env
