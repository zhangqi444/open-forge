# Cert Warden

**What it is:** Centralized ACME certificate management server (formerly LeGo CertHub). Acts as a single ACME client for your infrastructure — fetches and renews certificates from Let's Encrypt, then serves them to consumers via an API secured with per-consumer API keys. Eliminates the need to run Certbot/ACME clients on every host.

**Official site:** https://www.certwarden.com  
**GitHub:** https://github.com/gregtwallace/certwarden  
**Backend source:** https://github.com/gregtwallace/certwarden-backend  
**Frontend source:** https://github.com/gregtwallace/certwarden-frontend  
**Docker image:** `ghcr.io/gregtwallace/certwarden:latest`

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker Compose | Recommended; single container |
| Bare metal | Binary | Pre-built binaries on GitHub releases |

---

## Inputs to Collect

### Phase: Deploy

| Item | Description |
|------|-------------|
| Host port (HTTP) | Server web interface — default `4050` |
| Host port (HTTPS) | Server web interface TLS — default `4055` |
| ACME challenge port | HTTP-01 challenge listener — default `4060` |
| Data directory | `./data` mounted to `/app/data` — persists certs, config, DB |

### Phase: Configure (Web UI)

- ACME account (email + Let's Encrypt endpoint)
- Certificate domains and challenge method (HTTP-01, DNS-01)
- API keys for each certificate consumer

---

## Software-Layer Concerns

- **All state in `./data`** — contains certs, private keys, SQLite DB, config; back up regularly and securely
- **HTTP-01 challenge port (4060)** must be reachable from the internet on port 80 if using HTTP-01 challenge — configure firewall/reverse proxy accordingly
- **Consumer API:** Certificate consumers (servers, apps) call the Cert Warden API with their API key to fetch the current cert and key — no local ACME client needed on each host
- **Ports exposed:**
  - `4050` — HTTP web interface
  - `4055` — HTTPS web interface
  - `4060` — HTTP-01 ACME challenge server
  - `4065` / `4070` — pprof debug servers (HTTP/HTTPS) — restrict in production

---

## Example Docker Compose

```yaml
services:
  certwarden:
    container_name: certwarden
    image: ghcr.io/gregtwallace/certwarden:latest
    restart: unless-stopped
    ports:
      - "4050:4050"   # HTTP web interface
      - "4055:4055"   # HTTPS web interface
      - "4060:4060"   # HTTP-01 challenge
    volumes:
      - ./data:/app/data
```

---

## Upgrade Procedure

1. Pull new image: `docker compose pull`
2. Restart: `docker compose up -d`
3. Check web interface for any migration notices

---

## Gotchas

- **HTTP-01 challenge requires port 80 accessibility** — if your host is behind a NAT/firewall, either port-forward 80 → 4060, or use DNS-01 challenge instead
- **`./data` contains private keys** — restrict filesystem permissions; do not expose this directory
- **pprof debug ports (4065/4070)** should not be exposed publicly — omit from `ports` in production or firewall them
- Cert Warden is the single point of certificate issuance — if it's down, consumers can't renew; ensure high availability or monitor proactively
- Formerly called "LeGo CertHub" — some older documentation may use the old name

---

## Links

- Website: https://www.certwarden.com
- GitHub: https://github.com/gregtwallace/certwarden
- Releases: https://github.com/gregtwallace/certwarden/releases
- Docker image: https://github.com/gregtwallace/certwarden/pkgs/container/certwarden
