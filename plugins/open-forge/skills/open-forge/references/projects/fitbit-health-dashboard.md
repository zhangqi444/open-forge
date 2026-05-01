# Fitbit Health Dashboard (fitbit-grafana)

**Script + Docker stack that fetches health data from Fitbit/Google Health API and stores it in InfluxDB for visualization in a Grafana dashboard.**
GitHub: https://github.com/arpanghosh8453/fitbit-grafana

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | InfluxDB 1.11 + Grafana + fetch script |

---

## Inputs to Collect

### OAuth credentials
- `CLIENT_ID` / `CLIENT_SECRET` — from your Google Cloud or Fitbit developer app
- Refresh token — obtained via the OAuth setup flow (run container interactively first)
- `HEALTH_API_PROVIDER` — fitbit (legacy) or google (new default; Fitbit API is being deprecated)
- `DEVICENAME` — your device name (e.g. Charge5)

### Database / config
- `INFLUXDB_VERSION` — 1 (strongly recommended), 2, or 3 (experimental)
- `INFLUXDB_HOST`, `INFLUXDB_PORT` — influxdb (internal service name), 8086
- `INFLUXDB_USERNAME`, `INFLUXDB_PASSWORD`, `INFLUXDB_DATABASE`
- `LOCAL_TIMEZONE` — Automatic or a TZ string
- `LOG_LEVEL` — DEBUG / INFO / WARNING / ERROR / CRITICAL

---

## Software-Layer Concerns

### Setup sequence (InfluxDB 1.11)
1. Create a folder, cd into it
2. Create sub-folders: logs/ and tokens/ — chown both to uid 1000
3. Write compose.yml (see upstream README for full example)
4. First run to capture tokens:
   docker pull thisisarpanghosh/fitbit-fetch-data:latest && docker compose run --rm fitbit-fetch-data
   Enter your refresh token when prompted; Ctrl+C after seeing successful API requests
5. docker compose up -d
6. Open Grafana at localhost:3000; add InfluxDB datasource (address: http://influxdb:8086)
7. Import dashboard JSON from the public-fitbit-projects repo or use import codes:
   - InfluxDB v1: 23088
   - InfluxDB v2: 23090

### Google Health API migration
- Fitbit Web API is being deprecated in favor of Google Health API
- For new setups: follow the Google migration guide at extra/google-migration.md
- Set HEALTH_API_PROVIDER=google and obtain Google OAuth credentials

### Grafana heatmap plugin
Install via env var: GF_PLUGINS_PREINSTALL=marcusolsson-hourly-heatmap-panel
Or post-install: docker exec -it grafana grafana cli plugins install marcusolsson-hourly-heatmap-panel && docker restart grafana

### InfluxDB 3 note
InfluxDB 3 OSS limits queries to 72 hours by default — not suitable for long-term trend visualization. Use InfluxDB 1.11 unless you have a specific reason to upgrade.

---

## Upgrade Procedure

1. docker compose pull
2. docker compose up -d
3. docker compose logs --follow

---

## Gotchas

- Token setup MUST be done interactively before running the full stack
- chown logs/ and tokens/ to uid 1000 — the container runs as that user
- InfluxDB v1.11 is strongly recommended; v2 has limited dashboard parity, v3 has query time limits
- If using InfluxDB 3 admin token: generate with docker exec influxdb influxdb3 create token --admin — store it permanently, it cannot be retrieved again
- The Fitbit API personal app type is required for intraday data (heart rate, steps); standard apps get only summary data

---

## References
- GitHub: https://github.com/arpanghosh8453/fitbit-grafana#readme
- Google migration guide: https://github.com/arpanghosh8453/fitbit-grafana/blob/main/extra/google-migration.md
- InfluxDB schema: https://github.com/arpanghosh8453/fitbit-grafana/blob/main/extra/influxdb_schema.md
