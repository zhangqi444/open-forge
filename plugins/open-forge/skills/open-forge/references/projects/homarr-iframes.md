# Homarr iFrames

> API service that connects to self-hosted apps (Vikunja, Linkwarden, and more) and exposes their data as embeddable iFrames — drop live widgets from your apps into any dashboard, not just Homarr. Go-based single container, no database.

**Official URL:** https://github.com/diogovalentte/homarr-iframes

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker | Single container; no database |
| Any Linux VPS/VM | Docker Compose | Recommended for env var management |
| Any Linux | Go binary | Build from source |

---

## Inputs to Collect

### Phase: Pre-Deploy
| Input | Description | Example |
|-------|-------------|---------|
| `PORT` | Listening port (optional) | `8080` |
| Source env vars | Per-source app URLs and API tokens | see `.env.example` and Swagger docs |

Each source (Vikunja, Linkwarden, etc.) has its own set of env vars (URL + API key/token). See `.env.example` in the repo and the Swagger docs at `/v1/swagger/index.html` for the full list.

---

## Software-Layer Concerns

### Docker Run
```bash
docker run \
  --name homarr-iframes \
  -p 8080:8080 \
  -e VIKUNJA_URL=http://vikunja:3456 \
  -e VIKUNJA_API_TOKEN=your-token \
  ghcr.io/diogovalentte/homarr-iframes:latest
```

### Docker Compose
```bash
# 1. Create .env from .env.example in the repo
cp .env.example .env
# 2. Edit .env with your source app URLs and tokens
# 3. Start
docker compose up -d
```

### Embedding in Homarr
1. Enter edit mode → Add item → iFrame widget
2. Set URL to:
   ```
   http://YOUR_API_HOST:8080/v1/iframe/<source>?<params>
   ```
   Example: `http://192.168.1.15:8080/v1/iframe/linkwarden?collectionId=1&limit=3&theme=dark`

### Embedding in Other Dashboards
Any dashboard that supports iFrame embeds works — Homepage, Heimdall, Dashy, etc.

### API Documentation
Swagger UI at: `http://YOUR_HOST:8080/v1/swagger/index.html`

### Ports
- Default: `8080` (configurable via `PORT`)
- Important: the iFrame is loaded directly by the browser, so your browser must be able to reach this API

### Protocol Matching
- If your dashboard is on HTTPS, this API must also be on HTTPS — browsers block mixed HTTP/HTTPS iFrames
- Proxy with Caddy/Nginx for TLS

---

## Upgrade Procedure

1. Pull latest: `docker pull ghcr.io/diogovalentte/homarr-iframes:latest`
2. Stop: `docker compose down`
3. Start: `docker compose up -d`

---

## Gotchas

- **No authentication** — anyone who can reach the API URL can read all your source data; put an auth layer (Authelia, Authentik, or network restriction) in front of it
- **Browser must reach the API directly** — the dashboard server does not proxy iFrame requests; the client browser fetches it; firewall/VPN rules must allow browser → API access
- **HTTP/HTTPS protocol must match** — mixing HTTP API behind an HTTPS dashboard causes browsers to block the iFrame with a mixed-content error
- **Per-source env vars** — each source app requires its own URL + token env vars; check `.env.example` and Swagger docs for the exact variable names per source

---

## Links
- GitHub: https://github.com/diogovalentte/homarr-iframes
- Sources list: https://github.com/diogovalentte/homarr-iframes/blob/main/docs/SOURCES.md
- Swagger docs: `http://YOUR_HOST:8080/v1/swagger/index.html`
