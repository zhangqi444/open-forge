# Meshping

**What it is:** A network monitoring tool that continuously pings multiple targets and visualizes response times as histograms (not averages). Runs traceroute to map network topology, detects routing loops, performs Path MTU discovery per hop, shows AS info, and can peer with other Meshping instances for distributed monitoring. Includes Prometheus scrape endpoint.

**Official URL:** https://github.com/Svedrin/meshping
**Docker Hub:** `svedrin/meshping`
**License:** GPLv2
**Stack:** Python; multi-arch Docker

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS / bare metal | Docker Compose | Recommended; includes Watchtower for auto-updates |
| Homelab / Raspberry Pi | Docker Compose | Lightweight; good for edge monitoring |
| Portainer | Stack (docker-compose.yaml) | Drop-in deploy via Portainer Stack |
| Multiple nodes | Peered instances | Deploy multiple Meshping nodes and peer them |

---

## Inputs to Collect

### Pre-deployment
- List of targets to ping (hostnames or IPs) — added via web UI after deploy; no restart needed
- `MESHPING_HISTOGRAM_DAYS` — days of histogram history to retain (default: `3`)

### Runtime
- Add/remove targets on the fly through the web UI — no restart required
- Optional: configure peering with other Meshping instances for distributed monitoring

---

## Software-Layer Concerns

**Docker Compose quick start:**
```bash
mkdir meshping && cd meshping
wget https://raw.githubusercontent.com/Svedrin/meshping/master/examples/docker-compose.yaml
docker compose up --detach
```

Access at `http://<your-ip>:9922`.

The bundled `docker-compose.yaml` includes a Watchtower sidecar for automatic updates.

**Default port:** `9922`

**Key environment variables:**
- `MESHPING_HISTOGRAM_DAYS` — number of days to include in latency heatmaps (default: `3`)

**Prometheus metrics:** Scrape at `http://<host>:9922/metrics` — includes per-target latency histograms, packet loss, and hop data.

**Peering (wide-distribution):** Configure multiple Meshping instances to peer with each other so they all ping the same targets. Useful for checking connectivity from different network locations simultaneously.

**Upgrade procedure:** Watchtower handles automatic updates when using the bundled compose file. Manual: `docker compose pull && docker compose up -d`.

---

## Gotchas

- **Histograms, not averages** — by design; shows the full distribution of latencies, revealing bimodal patterns and occasional spikes that averages hide
- **Requires raw socket / NET_ADMIN capability** — the container needs elevated network permissions to send ICMP ping packets; runs with `--cap-add NET_ADMIN` or equivalent
- **Traceroute is active** — Meshping sends traceroute probes; some networks/firewalls may rate-limit or block these
- **Path MTU discovery is per-hop** — useful for finding where jumbo frames get fragmented, but can generate significant probe traffic on large target lists
- **Routing loop detection** — Meshping detects and displays loops visually; a useful diagnostic but means it intentionally follows loops briefly before stopping
- **No authentication by default** — expose on LAN only or add a reverse proxy with auth for internet-facing deployments

---

## Links
- GitHub: https://github.com/Svedrin/meshping
- Docker Hub: https://hub.docker.com/r/svedrin/meshping
- Example compose: https://github.com/Svedrin/meshping/blob/master/examples/docker-compose.yaml
