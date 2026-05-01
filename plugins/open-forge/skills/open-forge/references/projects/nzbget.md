# NZBGet

**Efficient, high-performance Usenet downloader written in C++ — downloads NZB files from Usenet newsgroups with low resource usage. Runs on virtually any device including NAS, routers, and ARM boards.**
Official site: https://nzbget.com
GitHub: https://github.com/nzbgetcom/nzbget

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Linux (x86/x64, ARM 32/64, MIPS, RISC-V) | Docker Compose | Recommended |
| Linux | Native binary / DEB/RPM | From releases page |
| macOS (Intel / Apple Silicon) | Native binary / Homebrew | |
| Windows | Installer / Winget / Chocolatey | |
| Synology NAS | SynoCommunity package | DSM 6.x / 7.x |
| ASUSTOR NAS | App Central | ADM 4.3+ |
| QNAP NAS | SHERPA package manager | QTS 4.1.0+ |
| TrueNAS SCALE | App catalog | amd64 |
| FreeBSD | Binary | 13.0+ x86_64 |
| Android | Manual | Android 5.0+ aarch64 |

---

## Inputs to Collect

### Required
- `TZ` — timezone
- `PUID` / `PGID` — file permission user/group
- Usenet server credentials (added in UI after first run)

### Optional
- `NZBGET_USER` / `NZBGET_PASS` — web UI credentials (defaults: `nzbget` / `tegbzn6789` — **change these**)

---

## Software-Layer Concerns

### Docker Compose
```yaml
services:
  nzbget:
    image: nzbgetcom/nzbget:latest
    container_name: nzbget
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/London
      - NZBGET_USER=your_username
      - NZBGET_PASS=your_secure_password
    volumes:
      - ./config:/config
      - ./downloads:/downloads
    ports:
      - 6789:6789
    restart: unless-stopped
```

### Ports
- `6789` — web UI

### Image tags
- `latest` — stable releases (main branch)
- `testing` — development builds (develop branch)
- `debug` — debug-enabled development builds
- `v*` (e.g. `v22.0`) — version-pinned releases

### Key features
- High performance, low resource usage (C++)
- Runs on almost any platform and architecture
- Extensible via V2 extensions API
- Web UI for management and monitoring

---

## Upgrade Procedure

1. docker compose pull
2. docker compose up -d

For upgrades from v21 or older, see: https://github.com/nzbgetcom/nzbget/discussions/100#discussioncomment-8080102

---

## Gotchas

- **Change default credentials** — default `NZBGET_USER=nzbget` / `NZBGET_PASS=tegbzn6789` are publicly known
- Usenet server credentials are configured inside the app after first run
- Migrating from older Docker images: https://github.com/nzbgetcom/nzbget/issues/84#issuecomment-1884846500

---

## References
- Official site: https://nzbget.com
- Docker docs: https://github.com/nzbgetcom/nzbget/blob/develop/docker/README.md
- How to use: https://github.com/nzbgetcom/nzbget/blob/develop/docs/HOW_TO_USE.md
- GitHub: https://github.com/nzbgetcom/nzbget#readme
