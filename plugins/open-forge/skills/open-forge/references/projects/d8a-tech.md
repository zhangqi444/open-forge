---
name: d8a-tech
description: d8a (Divine Data) recipe for open-forge. Warehouse-native web analytics platform compatible with GA4 and Matomo tracking protocols. Go + Docker, supports BigQuery/ClickHouse/S3/local. Source: https://github.com/d8a-tech/d8a
---

# d8a (Divine Data)

A warehouse-native, open-source web analytics platform. Compatible with GA4 and Matomo tracking protocols — drop in as a backend for existing tracking setups. Flat analytics-ready data model, session calculation on the backend. Supports BigQuery, ClickHouse, S3/MinIO, and local filesystem output. GDPR/HIPAA/FedRAMP-friendly (no fingerprinting, no third-party). MIT licensed, written in Go. Upstream: <https://github.com/d8a-tech/d8a>. Docs: <https://d8a-tech.github.io/d8a/getting-started>. Demo: <https://app.d8a.tech>

## Compatible Combos

| Infra | Runtime | Storage backend | Notes |
|---|---|---|---|
| Any Linux VPS | Docker Compose | Local filesystem (CSV) | Simplest — no external DB |
| Any Linux VPS | Docker Compose | S3 / MinIO | Self-hosted object storage |
| Any Linux VPS | Docker Compose | ClickHouse | Best for large-scale analytics queries |
| Any Linux VPS | Docker Compose | BigQuery | Google Cloud — requires GCP credentials |
| Any Linux VPS | Go binary (native) | Any supported | Build from source |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Storage/warehouse backend?" | local / s3 / clickhouse / bigquery | Drives all storage config |
| "Port to expose?" | Number | Default 8080 |
| "GA4 Measurement ID to accept?" | string | e.g. G-XXXXXXXX — d8a acts as the collection endpoint |

### Phase 2 — Deploy (varies by backend)

| Prompt | Format | Notes |
|---|---|---|
| "S3/MinIO endpoint, bucket, key, secret?" | strings | If using object storage |
| "ClickHouse host + credentials?" | host:port + user/pass | If using ClickHouse |
| "GCP service account JSON?" | path to JSON file | If using BigQuery |
| "Config file path?" | File path | d8a uses a YAML config file |

## Software-Layer Concerns

- **GA4 + Matomo protocol compatibility**: Point your existing gtag.js or Matomo tracking snippet at d8a's endpoint instead of Google/Matomo — no tag changes needed.
- **Native web tracker (beta)**: A drop-in `gtag.js` replacement for new setups.
- **Flat data model**: All events (including custom) stored in dedicated columns — analytics-ready without complex JSON unpacking.
- **Session calculation**: Sessions computed server-side (not client-side hacks) — more accurate than client-only approaches.
- **Config file**: `config.yaml` (or `config.dev.yaml` for development) drives all settings — backend, ports, tracking IDs.
- **~10 second session close delay**: Default session timeout; events must arrive within the window to be attributed to the same session.
- **Parallel with GA4**: Can run alongside GA4 — send events to both for a smooth migration period.

## Deployment

### Docker (Getting started)

See the full getting-started guide at https://d8a-tech.github.io/d8a/getting-started for the current recommended Docker setup. The config is YAML-driven:

```yaml
# config.yaml example (check upstream docs for full reference)
server:
  port: 8080
storage:
  type: local       # or s3, clickhouse, bigquery
  local:
    path: /data/events
```

```yaml
services:
  d8a:
    image: ghcr.io/d8a-tech/d8a:latest
    ports:
      - "8080:8080"
    volumes:
      - ./config.yaml:/app/config.yaml:ro
      - ./data:/data/events
    restart: unless-stopped
```

### Point GA4 tracking to d8a

In your gtag.js setup, override the collection endpoint:

```javascript
gtag('config', 'G-XXXXXXXX', {
  'transport_url': 'https://your-d8a-instance.com',
  'first_party_collection': true
});
```

## Upgrade Procedure

1. Pull new image: `docker compose pull && docker compose up -d`
2. Check release notes at https://github.com/d8a-tech/d8a/releases for config schema changes.
3. Backup data directory before upgrading when using local/S3 storage.

## Gotchas

- **Config file required**: d8a requires a YAML config — there is no default zero-config mode.
- **GA4 Measurement ID must be configured**: d8a validates incoming tracking IDs — configure the IDs you expect to receive.
- **Native tracker is beta**: The dedicated `d8a.js` web tracker is beta as of early 2026 — GA4/Matomo protocol compat is the stable path.
- **No built-in dashboard**: d8a is a collection + storage backend. Visualisation uses Looker Studio (demo link in README), BI tools, or ClickHouse UI — not a self-contained dashboard.
- **Session ~10 second delay**: Processing pipeline waits for session close before writing — events won't appear instantly in storage.

## Links

- Source: https://github.com/d8a-tech/d8a
- Docs / Getting started: https://d8a-tech.github.io/d8a/getting-started
- Demo (Looker Studio): https://lookerstudio.google.com/reporting/0e4102b6-c38b-4f55-aa25-c1fe91d1c1e9
- Cloud: https://app.d8a.tech
- Releases: https://github.com/d8a-tech/d8a/releases
