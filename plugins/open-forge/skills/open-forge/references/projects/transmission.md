# Transmission

Fast, easy, and free BitTorrent client with a headless daemon mode and web UI — ideal for self-hosting on servers and routers. Transmission is lightweight, resource-efficient, and integrates well with the *arr stack for automated media management.

**Official site:** https://transmissionbt.com

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Docker (LinuxServer) | `lscr.io/linuxserver/transmission`; recommended |
| Any Linux host | Native daemon (`transmission-daemon`) | Available in most distro repos |
| macOS | Desktop app + daemon | Official macOS app or Homebrew |
| Kubernetes | Helm (community) | Community charts available |

---

## Inputs to Collect

### Phase 1 — Planning
- Download directory path
- RPC (web UI) username and password
- Peer port (default `51413`) — needs to be forwarded on router for optimal seeding
- Whether to use hardlinks/atomic moves (shared volume with *arr apps)

### Phase 2 — Deployment
- PUID / PGID (LinuxServer image)
- Timezone (`TZ`)
- Port mappings: `9091` (web UI), `51413/tcp`, `51413/udp`

---

## Software-Layer Concerns

### Docker Compose (LinuxServer)

```yaml
services:
  transmission:
    image: lscr.io/linuxserver/transmission:latest
    container_name: transmission
    environment:
      PUID: "1000"
      PGID: "1000"
      TZ: UTC
      # Optional: set Web UI password via env
      TRANSMISSION_WEB_HOME: /web  # custom web UI path (e.g., Flood for Transmission)
    volumes:
      - ./config:/config
      - /data/downloads:/downloads
      - /data/watch:/watch  # auto-add .torrent files dropped here
    ports:
      - "9091:9091"     # Web UI
      - "51413:51413"   # Peer port (TCP)
      - "51413:51413/udp"
    restart: unless-stopped
```

### Key Config (`/config/settings.json`)
| Key | Default | Description |
|-----|---------|-------------|
| `rpc-enabled` | `true` | Enable web UI / RPC |
| `rpc-port` | `9091` | Web UI port |
| `rpc-username` | `""` | Web UI username |
| `rpc-password` | `""` | Web UI password (stored hashed after first run) |
| `rpc-whitelist-enabled` | `true` | Restrict RPC to whitelisted IPs |
| `rpc-whitelist` | `"127.0.0.1"` | Comma-separated IPs (use `"*"` to allow all) |
| `download-dir` | `"/downloads"` | Completed downloads path |
| `incomplete-dir` | `""` | In-progress downloads path (enable for efficiency) |
| `peer-port` | `51413` | BitTorrent peer port |
| `speed-limit-up-enabled` | `false` | Enable upload speed cap |
| `ratio-limit-enabled` | `false` | Stop seeding at target ratio |

> ⚠️ **Edit `settings.json` only when the daemon is stopped** — it rewrites the file on shutdown.

### Web UI
- Default: built-in Transmission web UI at `http://<host>:9091`
- Alternatives: [Flood for Transmission](https://github.com/johman10/flood-for-transmission) (modern React UI), [Combustion](https://github.com/Secretmapper/combustion)

### *arr Integration (Sonarr/Radarr)
Add Transmission as a download client in Sonarr/Radarr:
- Host: `transmission` (service name), Port: `9091`
- Use the same `/data` volume root for hardlink support

### CLI Tool
```bash
transmission-remote <host>:9091 --auth <user>:<pass> --list
transmission-remote <host>:9091 --add <magnet-or-nzb-url>
```

---

## Upgrade Procedure

```bash
docker pull lscr.io/linuxserver/transmission:latest
docker compose up -d
```

Config is backward-compatible across minor versions.

---

## Gotchas

- **settings.json race condition**: The daemon overwrites `settings.json` on stop — always stop the daemon before editing config manually, or use the RPC API / web UI.
- **`rpc-whitelist`**: When running in Docker, the container IP changes; set `"rpc-whitelist": "*"` or `"rpc-whitelist-enabled": false` and rely on network-level access control instead.
- **Peer port forwarding**: Port `51413` must be reachable from the internet for good seeding performance. Without it, you'll be "firewalled" and only connect to peers who can initiate connections.
- **Hardlinks**: Use a shared `/data` volume across Transmission and *arr apps to enable hardlinks (no copy on import = instant, no extra disk space).
- **Watch directory**: Files dropped in the `watch` directory are auto-added as torrents — useful for automation but ensure it's not publicly writable.
- **Password hashing**: After first run, the plaintext password in `settings.json` is replaced with a salted hash. Don't be surprised when the config looks different after startup.

---

## References
- GitHub: https://github.com/transmission/transmission
- Docs: https://github.com/transmission/transmission/tree/main/docs
- LinuxServer Docker: https://docs.linuxserver.io/images/docker-transmission/
- *arr wiki: https://wiki.servarr.com/
