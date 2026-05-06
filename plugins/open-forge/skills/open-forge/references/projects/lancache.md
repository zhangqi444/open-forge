---
name: lancache
description: LanCache (monolithic) recipe for open-forge. LAN Party game download caching — intercepts and caches Steam, Epic, Battle.net, PlayStation, Xbox, and other game CDN traffic so multiple LAN users download once and share locally. Docker Compose stack with DNS. Source: https://github.com/lancachenet/monolithic
---

# LanCache (Monolithic)

LAN Party game download caching: intercepts game client downloads from Steam, Epic, Battle.net, Xbox, PlayStation, Origin, Ubisoft, and dozens of other game CDNs, caches the content locally, and serves subsequent requests from the cache. One user downloads, everyone else gets LAN speeds. Built as a Docker Compose stack: a DNS container that redirects CDN hostnames to the cache host, and a monolithic Nginx-based cache container that handles both HTTP and HTTPS traffic. Upstream: https://github.com/lancachenet/monolithic. Docs: https://lancache.net.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| Docker Compose (monolithic stack) | Linux | Official and recommended |
| Separate containers (DNS + cache) | Linux | Advanced; same images, manual wiring |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| network | "Cache host LAN IP?" | LANCACHE_IP — IP clients will reach the cache on |
| network | "DNS server bind IP?" | DNS_BIND_IP — usually same as LANCACHE_IP |
| storage | "Cache storage path?" | CACHE_ROOT — must have plenty of free space |
| storage | "Max cache disk size?" | CACHE_DISK_SIZE — e.g. 2000g, 500g |
| dns | "Upstream DNS resolver?" | UPSTREAM_DNS — e.g. 8.8.8.8 |

## Software-layer concerns

### Prerequisites

  # A dedicated cache host on your LAN with:
  # - Docker + Docker Compose installed
  # - Large storage volume for cache (hundreds of GB recommended)
  # - Static LAN IP

### Clone the official docker-compose repo

  git clone https://github.com/lancachenet/docker-compose.git lancache
  cd lancache

### Edit .env

  # Copy the example and edit the required variables:
  cp .env .env.bak   # optional backup

  # Minimum required changes:
  LANCACHE_IP=192.168.1.50       # IP of this cache host
  DNS_BIND_IP=192.168.1.50       # IP for DNS to bind to
  CACHE_ROOT=/data/lancache      # Where to store cached data
  CACHE_DISK_SIZE=2000g          # Max cache size
  UPSTREAM_DNS=8.8.8.8           # Upstream DNS for non-cached queries

### docker-compose.yml (from lancachenet/docker-compose)

  services:
    dns:
      image: lancachenet/lancache-dns:latest
      env_file: .env
      restart: unless-stopped
      ports:
        - ${DNS_BIND_IP}:53:53/udp
        - ${DNS_BIND_IP}:53:53/tcp

    monolithic:
      image: lancachenet/monolithic:latest
      env_file: .env
      restart: unless-stopped
      ports:
        - 80:80/tcp
        - 443:443/tcp
      volumes:
        - ${CACHE_ROOT}/cache:/data/cache
        - ${CACHE_ROOT}/logs:/data/logs

### Start the stack

  docker compose up -d

### Point clients at the LanCache DNS

  # Method 1: Set DNS on your DHCP server to DNS_BIND_IP
  #   → all clients get cache DNS automatically
  #
  # Method 2: Set DNS manually per client to DNS_BIND_IP
  #
  # Method 3: Use uklans/cache-domains configs with your existing DNS
  #   https://github.com/uklans/cache-domains

### Enable autostart (after confirming it works)

  sudo ./enable_autostart.sh

### Storage layout

  ${CACHE_ROOT}/cache/   # Cached game content (can grow large)
  ${CACHE_ROOT}/logs/    # Access and error logs

### Key env vars

  LANCACHE_IP         LAN IP(s) for the cache (space-separated for multiple)
  DNS_BIND_IP         Single IP the DNS container listens on
  UPSTREAM_DNS        Forwarding resolver for non-cached domains
  CACHE_ROOT          Host path for cache data and logs
  CACHE_DISK_SIZE     Upper limit on cached data (e.g. 2000g, 500g)
  CACHE_INDEX_SIZE    Memory for Nginx cache index (default: 500m)
  MIN_FREE_DISK       Minimum free disk to maintain (default: 10g)
  USE_GENERIC_CACHE   true for monolithic (single-IP) mode

### Ports

  53/udp 53/tcp    # DNS (on DNS_BIND_IP)
  80/tcp           # HTTP cache
  443/tcp          # HTTPS cache (TLS termination via SNI proxy in monolithic)

## Supported services (partial list)

  Steam, Epic Games, Battle.net, Origin/EA, Ubisoft, Xbox/Microsoft,
  PlayStation, Riot Games, Rockstar, GOG, Frontier, Wargaming, ArenaNet,
  and many more — see https://github.com/uklans/cache-domains for the full list.

## Upgrade procedure

  cd lancache
  docker compose pull
  docker compose up -d

## Gotchas

- **Large storage required**: Games are big. 1–2 TB is realistic for a well-used LAN party. Set `CACHE_DISK_SIZE` to what you can afford and `MIN_FREE_DISK` to keep your OS disk healthy.
- **Static IP on cache host**: The LAN IP of the cache host must be stable. If it changes, DNS redirects break. Use a DHCP reservation or static config.
- **DNS bind IP = one IP**: `DNS_BIND_IP` must be a single IP. If you have multiple LAN IPs, pick one; `LANCACHE_IP` can be space-separated for multiple addresses.
- **Clients must use LanCache DNS**: The caching only works if clients resolve CDN hostnames via the LanCache DNS. Verify with `nslookup steamcontent.com <DNS_BIND_IP>` — should return `LANCACHE_IP`.
- **HTTPS works via SNI proxy**: Monolithic handles HTTPS by SNI proxying; it presents its own certificate. Game launchers generally accept this for CDN traffic.
- **Not for production internet routing**: LanCache is for LAN Party / home lab use. It intercepts CDN DNS records and should not be run as a public DNS resolver.
- **Logs can also grow large**: Cache logs go to `${CACHE_ROOT}/logs/`. Add log rotation or monitor the directory.

## References

- Upstream GitHub (monolithic): https://github.com/lancachenet/monolithic
- Docker Compose repo: https://github.com/lancachenet/docker-compose
- Documentation: https://lancache.net
- Supported CDN domains: https://github.com/uklans/cache-domains
