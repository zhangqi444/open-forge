# wol

**Wake-on-LAN tool with CLI and web interface — send WOL magic packets to wake up machines on your network by name or MAC address, with real-time status monitoring.**
GitHub: https://github.com/Trugamr/wol

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Must use host networking for WOL packets to reach LAN |
| Any Linux / macOS / Windows | Binary | Pre-built releases on GitHub |
| Any Linux | Go install | `go install github.com/trugamr/wol@latest` |

---

## Inputs to Collect

### Required
- MAC addresses of machines to wake
- (Optional) IP addresses — for status/ping monitoring

---

## Software-Layer Concerns

### Docker Compose (host networking required)
```yaml
services:
  wol:
    image: ghcr.io/trugamr/wol:latest
    command: serve
    network_mode: "host"
    volumes:
      - ./config.yaml:/etc/wol/config.yaml
    restart: unless-stopped
```

Or via environment variable instead of config file:
```yaml
    environment:
      WOL_CONFIG: |
        machines:
          - name: desktop
            mac: "00:11:22:33:44:55"
            ip: "192.168.1.100"
        server:
          listen: ":7777"
```

### config.yaml
```yaml
machines:
  - name: desktop
    mac: "00:11:22:33:44:55"
    ip: "192.168.1.100"    # optional, for status checking
  - name: server
    mac: "AA:BB:CC:DD:EE:FF"
    ip: "server.local"

server:
  listen: ":7777"           # defaults to :7777

ping:
  privileged: false         # set true if ping requires elevated perms
```

Config file search order: `./config.yaml` → `~/.wol/config.yaml` → `/etc/wol/config.yaml`

### Ports
- `7777` — web UI (default; configurable)

### CLI commands
```bash
wol list                        # list configured machines
wol send --name desktop         # wake by name
wol send --mac "00:11:22:33:44:55"  # wake by MAC
wol serve                       # start web UI
```

---

## Upgrade Procedure

- Docker: docker compose pull && docker compose up -d
- Binary: download new release from GitHub releases

---

## Gotchas

- **Host networking is required** — bridge networking blocks WOL broadcast packets from reaching the LAN
- Ping status monitoring in Docker may fail due to permissions; fix with: `sysctl -w net.ipv4.ping_group_range="0 2147483647"` on the host (or set `ping.privileged: true` in config)
- Reverse proxy example (with basic auth + HTTPS) in `examples/reverse-proxy.yml` in the repo

---

## References
- GitHub: https://github.com/Trugamr/wol#readme
