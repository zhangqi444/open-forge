# GeoPulse

**Privacy-first self-hosted Google Timeline alternative. Turns GPS data from OwnTracks, Overland, GPSLogger, Home Assistant, and others into a searchable map timeline of stays and trips.**
GitHub: https://github.com/tess1o/geopulse
Docs: https://tess1o.github.io/geopulse/

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Recommended |

---

## Inputs to Collect

### All phases
- Review `.env.example` for security settings before going to production
- GPS source configuration — pick at least one: OwnTracks (HTTP or MQTT), Overland, GPSLogger, Home Assistant, Traccar, Dawarich, Colota
- Immich URL + API key (optional) — to overlay photos on map timeline

---

## Software-Layer Concerns

### Quick install
```bash
mkdir geopulse && cd geopulse
curl -L -o .env https://raw.githubusercontent.com/tess1o/GeoPulse/main/.env.example
curl -L -o docker-compose.yml https://raw.githubusercontent.com/tess1o/GeoPulse/main/docker-compose.yml
docker compose up -d
```
Access at http://localhost:5555

### Ports
- `5555` — web UI

### GPS Sources
- OwnTracks (HTTP push or MQTT broker)
- Overland
- GPSLogger
- Home Assistant
- Traccar
- Dawarich / Colota

### Data import
Supports bulk import from: Google Timeline, GPX, GeoJSON, OwnTracks exports, CSV

### Auth
- Standard username/password
- OIDC/SSO support for enterprise/team deployments

### Features
- Automatic stay and trip detection with configurable sensitivity
- Travel mode classification
- Immich photo integration (photos appear on map timeline)
- Multi-user with roles, invitations, and admin audit logs
- Guest sharing links with optional password and instant revocation
- No telemetry or third-party tracking

### Performance
- Typically under 100MB RAM and 1% CPU in normal usage

---

## Upgrade Procedure

1. docker compose pull
2. docker compose up -d

---

## Gotchas

- License: BSL 1.1 (Business Source License) — review terms before commercial use
- For production: review `.env` security settings (default values are not hardened)
- MQTT support requires additional broker configuration — see Docker Deployment Guide
- Full deployment guide: https://tess1o.github.io/geopulse/docs/getting-started/deployment/docker-compose

---

## References
- Docker Deployment Guide: https://tess1o.github.io/geopulse/docs/getting-started/deployment/docker-compose
- GitHub: https://github.com/tess1o/geopulse#readme
