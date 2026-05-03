# DumbWhoIs

> Stupidly simple web UI for WHOIS, IP geolocation, and ASN lookups — auto-detects query type, no API keys required, no authentication, free external APIs with automatic fallback.

**URL:** https://github.com/DumbWareio/DumbWhoIs
**Source:** https://github.com/DumbWareio/DumbWhoIs
**License:** Not specified in README (check repository root)

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any   | Docker  | Official image: `dumbwareio/dumbwhois:latest` |
| Any   | Node.js | `npm install && npm start` (Node.js required) |

## Inputs to Collect

### Provision phase
- Desired public port (default `3000`)

### Deploy phase
- `DUMBWHOIS_PORT` — external listen port (default `3000`)
- Optional: `SITE_TITLE` — custom title shown in the UI (default `DumbWhois`)
- Optional: `ALLOWED_ORIGINS` — CORS allowed origins; comma-separated URLs; default `*` (allow all)

## Software-layer Concerns

### Docker Compose
```yaml
services:
  dumbwhois:
    image: dumbwareio/dumbwhois:latest
    container_name: dumbwhois
    restart: unless-stopped
    ports:
      - ${DUMBWHOIS_PORT:-3000}:3000
    environment:
      - SITE_TITLE=${DUMBWHOIS_SITE_TITLE:-DumbWhois}
      # - ALLOWED_ORIGINS=https://subdomain.domain.tld,http://internalip:port
```

### Config / env vars
- `DUMBWHOIS_PORT`: host port to expose (default `3000`)
- `SITE_TITLE`: UI title text (default `DumbWhois`)
- `ALLOWED_ORIGINS`: comma-separated CORS allowed origins; defaults to `*` (permissive); restrict for production

### Data dirs
- No persistent data; stateless — no volumes required

## Upgrade Procedure
```bash
docker compose pull
docker compose up -d
```

## Gotchas
- **External API rate limits** — ipapi.co is capped at 1,000 requests/day (free tier); ip-api.com allows 45 req/min. The app automatically falls back through ipapi.co → ip-api.com → ipwho.is.
- **No authentication** — there is no login screen; add auth at the reverse proxy layer if exposure control is needed.
- **CORS is open by default** — set `ALLOWED_ORIGINS` explicitly if deploying behind a proxy or embedding in other pages.
- **Direct WHOIS protocol** — uses native WHOIS TCP queries (port 43); ensure outbound port 43 is not blocked by your firewall or cloud provider.
- **PWA-capable** — can be installed as a PWA on mobile; served from port 3000 by default.
- Query type is auto-detected: domain → WHOIS, IP address → IP geolocation, `AS<num>` → ASN lookup.
- URL parameter: `?lookup=<query>` allows direct linking and automation.

## Links
- [README](https://github.com/DumbWareio/DumbWhoIs/blob/main/README.md)
- [Docker Hub — dumbwareio/dumbwhois](https://hub.docker.com/r/dumbwareio/dumbwhois)
