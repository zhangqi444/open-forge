---
name: d8a-tech
description: d8a (Divine Data) recipe for open-forge. Open-source warehouse-native analytics platform compatible with GA4 and Matomo tracking protocols. Go, Docker, ClickHouse/BigQuery/CSV. MIT. Based on upstream at https://github.com/d8a-tech/d8a and docs at https://docs.d8a.tech.
---

# d8a (Divine Data)

Open-source, warehouse-native clickstream analytics platform. Drop-in compatible with GA4 and Matomo tracking protocols — point your existing `gtag.js` setup at your own d8a endpoint and data goes straight to your private database instead of Google. Also ships a native web tracker. Data is stored in a flat, analytics-ready schema ideal for BI tools. Designed for privacy-sensitive use cases (HIPAA, FedRAMP, GDPR). Built in Go. MIT. Upstream: https://github.com/d8a-tech/d8a. Docs: https://docs.d8a.tech.

## Compatible install methods

| Method | When to use |
|---|---|
| Docker Compose + ClickHouse | Standard production setup; most features |
| Docker Compose + Files (CSV/S3) | Lightweight; no separate DB required |
| Local binary | Development or minimal-dependency installs |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| warehouse | "Warehouse driver?" | clickhouse / bigquery / files | ClickHouse recommended for production |
| warehouse | "ClickHouse password?" | String | Set in both ClickHouse and d8a config |
| network | "Port to expose d8a on?" | Number (default 8080) | Proxy behind nginx/Caddy for HTTPS + your domain |
| tracking | "GA4 Measurement ID (tid) to intercept?" | GA4 ID (e.g. G-XXXX) | Used when intercepting existing gtag.js traffic |
| protocol | "Tracking protocol?" | ga4 / matomo / d8a | ga4 for GA4-compatible; d8a for native tracker |

## Software-layer concerns

| Concern | Detail |
|---|---|
| Language | Go |
| Warehouse | ClickHouse (recommended), BigQuery, or Files (CSV to S3/GCS/local) |
| Port | 8080 (default; proxy behind nginx/Caddy for HTTPS) |
| Session handling | Sessions calculated server-side; timeout configurable |
| GA4 compatibility | Intercepts GA4 `g/collect` endpoint; transparent to existing trackers |
| Matomo compatibility | Implements Matomo tracking protocol |
| Native tracker | Drop-in `gtag.js` replacement for full d8a-native tracking |
| Image | `ghcr.io/d8a-tech/d8a:latest` |

## Install: Docker Compose + ClickHouse (recommended)

Source: https://docs.d8a.tech/getting-started

**Step 1 — config.yaml:**

```yaml
sessions:
  timeout: 30m   # Increase from 10s (dev default) for production
warehouse:
  driver: clickhouse
  clickhouse:
    host: clickhouse
    port: "9000"
    database: d8a
    username: default
    password: "CHANGEME_STRONG_PASSWORD"
protocol: ga4  # or: matomo, d8a
```

**Step 2 — docker-compose.yml:**

```yaml
services:
  clickhouse:
    image: clickhouse/clickhouse-server:latest
    restart: unless-stopped
    ports:
      - "8123:8123"
      - "9000:9000"
    volumes:
      - clickhouse-data:/var/lib/clickhouse
    environment:
      - CLICKHOUSE_DB=d8a
      - CLICKHOUSE_USER=default
      - CLICKHOUSE_PASSWORD=CHANGEME_STRONG_PASSWORD
    networks:
      - d8a-network

  d8a:
    image: ghcr.io/d8a-tech/d8a:latest
    restart: unless-stopped
    ports:
      - "8080:8080"
    volumes:
      - ./config.yaml:/config.yaml:ro
      - d8a-data:/storage
    command: server --config /config.yaml
    networks:
      - d8a-network
    depends_on:
      - clickhouse

networks:
  d8a-network:

volumes:
  d8a-data:
  clickhouse-data:
```

```bash
docker compose up -d
docker compose logs -f
```

Verify with a test event:
```bash
curl "http://localhost:8080/g/collect?v=2&tid=14&dl=https%3A%2F%2Ffoo.bar&en=page_view&cid=ag9" -X POST
```
Wait ~30 seconds (session timeout) for the event to be written to ClickHouse.

## Install: Docker Compose + Files (CSV, no DB)

For lightweight installs. Write CSV files to local filesystem or S3/GCS.

```yaml
# config.yaml
storage:
  bolt_directory: ./state/bolt
  queue_directory: ./state/queue
  spool_enabled: true
  spool_directory: ./state/spool
sessions:
  timeout: 30m
warehouse:
  driver: files
  files:
    format: csv
    storage: filesystem
    max_segment_age: 5m
    filesystem:
      path: ./csv-out
protocol: ga4
```

## Tracking setup

After d8a is running, configure your website to send events to it. Three options:

**Option A — Intercept existing GA4 traffic** (no site changes):  
Configure your proxy (nginx/Caddy) to forward `/g/collect` requests to d8a instead of Google Analytics. See https://docs.d8a.tech/sources/google-analytics-4.

**Option B — Update gtag.js transport URL:**  
In your existing `gtag.js` snippet, add a `transport_url` pointing to your d8a instance.

**Option C — Native d8a tracker:**  
Replace `gtag.js` with d8a's native tracker. Set `protocol: d8a` in config and use the `/d/c` endpoint.

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Check https://github.com/d8a-tech/d8a/releases for release notes.

## Gotchas

- Session timeout tuning: Default config uses `10s` for development convenience. For production, set `sessions.timeout: 30m` (or your preferred session window) before going live — short timeouts create many partial sessions.
- ClickHouse not optional for full features: The files driver is simpler but lacks query capability. For dashboards and BI, use ClickHouse.
- HTTPS required for production: GA4 and most browsers only send tracking requests over HTTPS. Use nginx/Caddy in front of d8a with a valid TLS cert.
- GA4 measurement ID: When intercepting GA4 traffic, the `tid` field in requests is your GA4 Measurement ID. d8a uses it to route events — you don't need to change your existing tracking code.
- Looker Studio dashboard: For BigQuery warehouse, d8a provides an official Looker Studio dashboard template. See upstream docs for the link.
- Cloud option available: https://app.d8a.tech offers a free hosted tier if you want to evaluate before self-hosting.
- ClickHouse password consistency: The password in `config.yaml` and the ClickHouse `CLICKHOUSE_PASSWORD` env var must match exactly.

## Links

- Source: https://github.com/d8a-tech/d8a
- Documentation: https://docs.d8a.tech/
- Getting started: https://docs.d8a.tech/getting-started
- Database schema: https://docs.d8a.tech/articles/database-schema
- Releases: https://github.com/d8a-tech/d8a/releases
- Cloud: https://app.d8a.tech
