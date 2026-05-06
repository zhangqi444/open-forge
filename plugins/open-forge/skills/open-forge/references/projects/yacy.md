---
name: yacy
description: YaCy recipe for open-forge. Decentralised, peer-to-peer search engine you can run as a personal or intranet search portal. Java-based with a built-in web crawler. Source: https://github.com/yacy/yacy_search_server. Website: https://yacy.net.
---

# YaCy

Decentralised, peer-to-peer, open-source search engine. Runs as a local Java application that crawls the web or your intranet, builds a local search index, and optionally participates in a global P2P search network with other YaCy peers. Use cases: privacy-aware personal search, enterprise/intranet search, standalone web crawler. Upstream: <https://github.com/yacy/yacy_search_server>. Website: <https://yacy.net>.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| VPS / bare metal (Linux) | Java 11+ (tarball or deb) | Primary deployment; upstream recommends compiling from source or using release builds |
| VPS / bare metal | Docker | Community Docker images available |
| Raspberry Pi / ARM | Java (native) | Runs on Pi 3B+ or better; reduce RAM allocation |
| Local machine (any OS) | Java (jar) | Works on macOS/Windows too; personal use |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Personal search, intranet search, or join P2P network?" | Affects operation mode in web UI after install |
| port | "Port for YaCy web interface?" | Default: 8090 (HTTP), 8443 (HTTPS) |
| ram | "How much RAM to allocate (MB)?" | Minimum: 600 MB; recommended 1–2 GB for active crawling |
| crawl | "Crawl your own domain(s) or general web?" | Drives initial crawl configuration |
| network | "Join the global YaCy P2P network or run standalone?" | P2P = shares index with community; standalone = private index |

## Software-layer concerns

- Language: Java 11+; ships as a self-contained application with embedded Jetty web server
- Default ports: 8090 (HTTP), 8443 (HTTPS)
- Config dir: DATA/ directory alongside the binary (contains index, configuration, and logs)
- Index storage: flat-file based (Solr-compatible embedded); can be large (10+ GB for broad crawls)
- Admin UI: http://localhost:8090 (all management via browser)
- Default admin password: set on first access; leave blank for no password (local-only use)
- Memory: configured in startYACY.sh (Xmx flag); increase for larger indexes

### Docker (community image)

```yaml
services:
  yacy:
    image: yacy/yacy_search_server:latest
    container_name: yacy
    ports:
      - "8090:8090"
      - "8443:8443"
    volumes:
      - yacy-data:/opt/yacy_search_server/DATA
    environment:
      - YACY_PEER_NAME=mypeer
    restart: unless-stopped

volumes:
  yacy-data:
```

### Native install (Linux)

```bash
# Download latest release
wget https://github.com/yacy/yacy_search_server/releases/latest/download/yacy_v1_*.tar.gz
tar xzf yacy_v1_*.tar.gz
cd yacy_*/

# Start (adjust -Xmx for available RAM)
./startYACY.sh -Xmx1g

# Access web UI
xdg-open http://localhost:8090
```

## Upgrade procedure

1. Stop YaCy: `./stopYACY.sh`
2. Backup the DATA/ directory
3. Download new release, extract alongside old DATA/
4. Copy DATA/ into new installation directory
5. Start new version: `./startYACY.sh`
6. Docker: `docker compose pull && docker compose up -d` (DATA volume is preserved)

## Gotchas

- **Java heap size**: Default is 600 MB. For crawling more than a few thousand pages, increase to 2 GB+ (`-Xmx2g` in startYACY.sh or JAVA_OPTS env var in Docker).
- **Index size grows fast**: Crawling broad domains generates large indexes. Monitor disk space and set crawl depth/page limits in the admin UI.
- **Intranet mode**: To prevent YaCy from sharing your intranet data with the P2P network, set operation mode to "Intranet Search" or "Robinson Mode" (isolated) in the web UI immediately after install.
- **Crawl politeness**: YaCy respects robots.txt and has configurable crawl delays. Don't point it at sites aggressively without adjusting the delay settings.
- **P2P network participation**: The default operation joins the global YaCy network and shares portions of your index. Opt out via the network settings if you want a private index.
- **No authentication by default**: YaCy's admin panel is open on localhost. Always set an admin password before exposing it on a network.

## Links

- Upstream repo: https://github.com/yacy/yacy_search_server
- Website: https://yacy.net
- Download / install: https://yacy.net/download_installation/
- Docker Hub: https://hub.docker.com/r/yacy/yacy_search_server
- Community forum: https://community.searchlab.eu
- Release notes: https://github.com/yacy/yacy_search_server/releases
