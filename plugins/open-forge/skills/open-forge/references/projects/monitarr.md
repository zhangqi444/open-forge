# Monitarr

> Minimal download queue viewer for Sonarr and Radarr — lets other users check download progress of their media requests without giving them access to the full Sonarr/Radarr UI. No authentication. Next.js frontend + Docker deployment.

**Official URL:** https://github.com/nickshanks347/monitarr

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker | Single container; recommended |
| Any Linux VPS/VM | Docker Compose | Provided compose file |
| Any Linux | Node.js (manual) | `yarn build && yarn start` |

**Requires:** Sonarr and/or Radarr

---

## Inputs to Collect

### Phase: Pre-Deploy
| Input | Description | Example |
|-------|-------------|---------|
| `SONARR_URL` | Sonarr base URL | `http://sonarr:8989` |
| `SONARR_API_KEY` | Sonarr API key | from Sonarr → Settings → General |
| `RADARR_URL` | Radarr base URL | `http://radarr:7878` |
| `RADARR_API_KEY` | Radarr API key | from Radarr → Settings → General |
| `BASE_PATH` | Optional subfolder path (e.g. `/monitarr`) | `` (empty = root) |

---

## Software-Layer Concerns

### Docker Compose
```yaml
services:
  monitarr:
    image: ghcr.io/nickshanks347/monitarr:latest
    container_name: monitarr
    ports:
      - "3000:3000"
    environment:
      - SONARR_URL=http://sonarr:8989
      - SONARR_API_KEY=YOUR_SONARR_KEY
      - RADARR_URL=http://radarr:7878
      - RADARR_API_KEY=YOUR_RADARR_KEY
      - BASE_PATH=/monitarr   # optional subfolder
    restart: unless-stopped
```

### BASE_PATH for Reverse Proxies
Set `BASE_PATH=/monitarr` to serve at `yourdomain.com/monitarr` instead of a subdomain. Leave empty for root path hosting.

### Ports
- Default: `3000`

### Manual Install
```bash
git clone https://github.com/nickshanks347/monitarr
cd monitarr
cp .env.example .env
# Edit .env with your Sonarr/Radarr URLs and API keys
yarn install
yarn build
yarn start
```

---

## Upgrade Procedure

1. Pull latest: `docker pull ghcr.io/nickshanks347/monitarr:latest`
2. Stop: `docker compose down`
3. Start: `docker compose up -d`

---

## Gotchas

- **No authentication** — anyone who can reach the URL sees all download queues; run only on an internal network or behind a VPN/auth proxy
- **Read-only view** — there is no way to manage downloads from Monitarr; it's purely a status page
- **Download speed inaccuracy** — the README explicitly notes the speed calculation logic is inaccurate; treat speed estimates as approximate
- **Sonarr/Radarr must be reachable** — the server-side container calls the Sonarr/Radarr APIs; ensure proper networking (Docker network or host access)
- **Minimal project** — self-described as a simple tool; not actively feature-developed; expect minimal maintenance

---

## Links
- GitHub: https://github.com/nickshanks347/monitarr
