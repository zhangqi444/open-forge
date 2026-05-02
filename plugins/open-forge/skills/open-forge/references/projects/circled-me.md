# Circled.me

> Self-hosted photo/video backup and sharing server with chat, audio/video calls, face detection, and album sharing — designed for private family and community use.

**URL:** https://circled.me
**Source:** https://github.com/circled-me/server
**License:** Not specified in README (check repository root)

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any   | Docker  | Official image on Docker Hub: `gubble/circled-server:latest` |
| Any   | Binary  | Build from source with Go 1.21+: `CGO_ENABLED=1 go build` |

## Inputs to Collect

### Provision phase
- Domain / public URL or local IP:port

### Deploy phase
- `SQLITE_FILE` — path to SQLite database file (default engine)
- `BIND_ADDRESS` — IP and port to bind (e.g. `0.0.0.0:8080`); incompatible with `TLS_DOMAINS`
- `DEFAULT_BUCKET_DIR` — directory used as default photo/video storage bucket
- Optional: `MYSQL_DSN` — MySQL connection string (takes precedence over SQLite if set)
- Optional: `TLS_DOMAINS` — comma-separated domains for automatic Let's Encrypt TLS
- Optional: `PUSH_SERVER` — push notification relay URL (defaults to `https://push.circled.me`)
- Optional: `TURN_SERVER_IP` / `TURN_SERVER_PORT` — for self-hosted TURN (WebRTC calls)
- Optional: `GAODE_API_KEY` — for reverse geocoding in China (replaces OpenStreetMap)

## Software-layer Concerns

### Docker Compose
```yaml
version: '2'
services:
  circled-server:
    image: gubble/circled-server:latest
    restart: always
    ports:
      - "8080:8080"
    environment:
      SQLITE_FILE: "/mnt/data1/circled.db"
      BIND_ADDRESS: "0.0.0.0:8080"
      DEFAULT_BUCKET_DIR: "/mnt/data1"
      DEFAULT_ASSET_PATH_PATTERN: "<year>/<month>/<id>"
    volumes:
      - ./circled-data:/mnt/data1
```

### Config / env vars
- `SQLITE_FILE`: path inside container for SQLite DB; created if missing
- `MYSQL_DSN`: MySQL DSN; if set, MySQL is used instead of SQLite
- `BIND_ADDRESS`: listen address (use this behind a reverse proxy)
- `TLS_DOMAINS`: comma-separated domains for auto-TLS via Let's Encrypt (incompatible with `BIND_ADDRESS`)
- `DEBUG_MODE`: defaults to `yes`
- `DEFAULT_BUCKET_DIR`: default local storage path for photos/videos
- `DEFAULT_ASSET_PATH_PATTERN`: subdirectory structure for stored assets (default `<year>/<month>/<id>`)
- `PUSH_SERVER`: push notification server URL (default `https://push.circled.me`)
- `FACE_DETECT`: enable/disable face detection (default `yes`)
- `FACE_DETECT_CNN`: CNN vs HOG for face detection (default `no`; CNN is slower but more accurate)
- `FACE_MAX_DISTANCE_SQ`: face similarity threshold (default `0.11`)
- `TURN_SERVER_IP`: public IP for built-in TURN server; leave empty to disable
- `TURN_SERVER_PORT`: TURN UDP port (default `3478`)
- `TURN_TRAFFIC_MIN_PORT` / `TURN_TRAFFIC_MAX_PORT`: relay UDP port range (default `49152-65535`)
- `GAODE_API_KEY`: Gaode/Amap API key for China-friendly reverse geocoding

### Data dirs
- `/mnt/data1` (or value of `DEFAULT_BUCKET_DIR`) — photos, videos, and SQLite database

## Upgrade Procedure
```bash
docker compose pull
docker compose up -d
```
Back up the `DEFAULT_BUCKET_DIR` (including the SQLite file) before upgrading.

## Gotchas
- **Project is in active development** — breaking changes may be introduced; always back up before upgrading.
- **Not a sole backup solution** — the README explicitly warns: "Do not use this as your main/only backup solution."
- **Mobile app required** — there is no web UI for browsing; the circled.me iOS/Android app is the only client interface.
- TURN port range `49152-65535` must be open on the public IP for self-hosted WebRTC; consider restricting the range.
- The default push server (`push.circled.me`) is an external dependency for push notifications.
- S3-compatible buckets can be configured per-user as an alternative to local storage.

## Links
- [README](https://github.com/circled-me/server/blob/main/README.md)
- [Docker Hub — gubble/circled-server](https://hub.docker.com/r/gubble/circled-server)
- [Mobile app source](https://github.com/circled-me/app)
