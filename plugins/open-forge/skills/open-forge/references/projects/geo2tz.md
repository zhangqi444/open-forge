# Geo2tz

**Timezone lookup microservice from GPS coordinates** — privacy-friendly self-hosted REST API that returns the IANA timezone name for any latitude/longitude pair. No coordinates are sent to third parties. Single Docker container, stateless, production-ready.

**Official site:** https://github.com/noandrea/geo2tz
**Source:** https://github.com/noandrea/geo2tz
**License:** MIT

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any VPS / bare metal | Docker | Single container; no external dependencies |
| Any VPS / bare metal | Go binary | Build from source |

---

## Inputs to Collect

### Phase 1 — Planning
- Port to expose (default: 2004)
- Whether to enable token-based auth (`GEO2TZ_WEB_AUTH_TOKEN_VALUE`)

### Phase 2 — Deploy
- Auth token value (optional but recommended for public-facing instances)

---

## Software-Layer Concerns

- **Stack:** Go; timezone boundary data from [evansiroky/timezone-boundary-builder](https://github.com/evansiroky/timezone-boundary-builder) bundled in the image
- **Stateless:** No database or persistent storage needed; timezone data is embedded
- **API:** Single endpoint `GET /tz/{latitude}/{longitude}` returning JSON with IANA timezone name
- **Auth:** Optional bearer token via `GEO2TZ_WEB_AUTH_TOKEN_VALUE` env var; returns HTTP 401 if token missing/wrong
- **Default port:** 2004

---

## Deployment

```bash
# Unauthenticated (internal use only)
docker run -d --restart unless-stopped \
  -p 2004:2004 \
  ghcr.io/noandrea/geo2tz:latest

# With token auth (recommended for public exposure)
docker run -d --restart unless-stopped \
  -p 2004:2004 \
  -e GEO2TZ_WEB_AUTH_TOKEN_VALUE=your-secret-token \
  ghcr.io/noandrea/geo2tz:latest
```

Example query:
```bash
curl -s http://localhost:2004/tz/51.477811/0 | jq
# Returns: { "coords": { "lat": 51.47781, "lon": 0 }, "tz": "Europe/London" }
```

---

## Upgrade Procedure

```bash
docker pull ghcr.io/noandrea/geo2tz:latest
docker stop geo2tz && docker rm geo2tz
# Re-run with same docker run command
```

Or with Docker Compose:
```bash
docker compose pull && docker compose up -d
```

---

## Gotchas

- **No auth by default** — if exposed publicly without `GEO2TZ_WEB_AUTH_TOKEN_VALUE`, anyone can query it
- **Timezone data is embedded** — no external data source to configure; data updates come with new image releases
- **Coordinate validation:** Latitude must be -90 to +90, longitude -180 to +180; out-of-range returns HTTP 400
- **Low activity repo** — project is considered feature-complete and stable; infrequent commits are intentional

---

## Links

- Upstream README: https://github.com/noandrea/geo2tz#readme
- Timezone boundary data source: https://github.com/evansiroky/timezone-boundary-builder
