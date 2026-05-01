# Decypharr

**Media gateway for Debrid services and Usenet — mocks qBittorrent and SABnzbd APIs so \*arr apps (Sonarr, Radarr, Lidarr) can use Debrid providers and direct Usenet streaming without a separate download client.**
Docs: https://docs.decypharr.com
GitHub: https://github.com/sirrobot01/decypharr

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Requires `/dev/fuse` and `SYS_ADMIN` capability |

---

## Inputs to Collect

### Required
- Debrid provider API key (Real-Debrid, Torbox, Debrid-Link, or All-Debrid)
- Mount paths for media (shared with \*arr apps)
- `config.json` in the config volume

---

## Software-Layer Concerns

### Docker Compose
```yaml
services:
  decypharr:
    image: cy01/blackhole:latest
    container_name: decypharr
    ports:
      - "8282:8282"
    volumes:
      - /mnt/:/mnt:rshared
      - ./configs/:/app    # config.json must be in this directory
    restart: unless-stopped
    devices:
      - /dev/fuse:/dev/fuse:rwm
    cap_add:
      - SYS_ADMIN
    security_opt:
      - apparmor:unconfined
```

### Ports
- `8282` — web UI / mock API endpoint

### Supported Debrid providers
- Real-Debrid
- Torbox
- Debrid-Link
- All-Debrid

### How it works
- Exposes a mock qBittorrent API and mock SABnzbd API
- \*arr apps send downloads to Decypharr instead of a real download client
- Decypharr resolves links through Debrid (instant cloud cache) or streams Usenet via NNTP
- Media appears at the configured mount path

---

## Upgrade Procedure

1. docker compose pull
2. docker compose up -d

---

## Gotchas

- Requires `SYS_ADMIN` capability and `/dev/fuse` device — needed for FUSE mounting of Debrid links
- `apparmor:unconfined` required on systems with AppArmor enabled
- `config.json` must exist in the mapped config directory before starting
- Full config reference: https://docs.decypharr.com

---

## References
- Documentation: https://docs.decypharr.com
- GitHub: https://github.com/sirrobot01/decypharr#readme
