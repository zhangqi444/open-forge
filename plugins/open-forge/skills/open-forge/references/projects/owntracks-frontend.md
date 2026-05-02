# OwnTracks Frontend

**What it is:** Advanced Vue.js web interface for the OwnTracks location recorder. Displays live/last-known locations with accuracy circles, location history (data points, line, or heatmap), date/time range filtering, user/device filtering, and distance calculations. A feature-rich companion to the OwnTracks Recorder's built-in basic web pages.

**GitHub:** https://github.com/owntracks/frontend  
**Docker Hub:** `owntracks/frontend`

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker Compose | Recommended; single nginx container |
| Any Linux | Static files | Build with npm, serve from any webserver |

---

## Prerequisites

- A running **OwnTracks Recorder** instance (https://github.com/owntracks/recorder)
- OwnTracks mobile app publishing location data to the recorder

---

## Inputs to Collect

### Phase: Deploy

| Variable | Description | Default |
|----------|-------------|---------|
| `SERVER_HOST` | Hostname/IP of the OwnTracks Recorder | Same host as frontend |
| `SERVER_PORT` | Port of the OwnTracks Recorder API | `8083` |
| `LISTEN_PORT` | Port for the nginx server inside the container | `80` |

### Phase: Optional (advanced config)

Mount a custom `config.js` file to `/usr/share/nginx/html/config/config.js` for additional options:
- Map tile provider
- Start location/zoom
- Ignored users/devices
- Custom feature toggles

See [`docs/config.md`](https://github.com/owntracks/frontend/blob/main/docs/config.md) for all available options.

---

## Software-Layer Concerns

- **Single nginx container** — serves the compiled Vue.js SPA; proxies API calls to the OwnTracks Recorder
- **No database** — reads all data from the OwnTracks Recorder API
- **Works without config** if the OwnTracks API is reachable at the same host/root
- **Custom config** is optional but allows deep customization of the map, filters, and display

---

## Example Docker Compose

```yaml
services:
  owntracks-frontend:
    image: owntracks/frontend
    ports:
      - "80:80"
    volumes:
      - ./config.js:/usr/share/nginx/html/config/config.js  # optional
    environment:
      - SERVER_HOST=otrecorder
      - SERVER_PORT=8083
    restart: unless-stopped
```

---

## Upgrade Procedure

1. Pull new image: `docker compose pull`
2. Restart: `docker compose up -d`
3. No persistent state — config file mount carries forward

---

## Gotchas

- **Requires a running OwnTracks Recorder** — this is a frontend only; it does not store or collect location data itself
- `SERVER_HOST` must be reachable from the nginx container — use the Docker service name if running on the same Compose stack
- Without a custom `config.js`, the frontend assumes the API is at the same origin — works naturally when both are behind the same reverse proxy
- Mobile OwnTracks apps must be configured to publish to your recorder's MQTT or HTTP endpoint separately

---

## Links

- GitHub: https://github.com/owntracks/frontend
- Docker Hub: https://hub.docker.com/r/owntracks/frontend
- Config docs: https://github.com/owntracks/frontend/blob/main/docs/config.md
- OwnTracks Recorder: https://github.com/owntracks/recorder
