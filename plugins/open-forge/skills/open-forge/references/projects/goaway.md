# GoAway

**Lightweight DNS sinkhole for network-level ad, tracker, and malicious domain blocking — web dashboard, real-time statistics, low resource footprint. Inspired by Pi-hole.**
Docs: https://pommee.github.io/goaway
GitHub: https://github.com/pommee/goaway

> ⚠️ Version 0.x.x — subject to breaking changes between releases.

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Linux (amd64/arm64/386) | Docker | Full support |
| macOS / Windows | Docker | Beta support |

---

## Inputs to Collect

### Required
- DNS port (53) accessible on the host
- Network devices configured to use GoAway's IP as DNS server

---

## Software-Layer Concerns

### Docker run
```bash
docker run -d \
  -p 53:53/udp \
  -p 53:53/tcp \
  -p 8080:8080 \
  pommee/goaway
```

### Docker Compose
```yaml
services:
  goaway:
    image: pommee/goaway
    ports:
      - "53:53/udp"
      - "53:53/tcp"
      - "8080:8080"
    restart: unless-stopped
```

Full configuration reference: https://pommee.github.io/goaway

### Ports
- `53` UDP/TCP — DNS
- `8080` — web admin dashboard

### Resource usage
- Memory: typically < 50 MB RAM
- CPU: minimal

---

## Upgrade Procedure

1. docker compose pull
2. docker compose up -d

---

## Gotchas

- Binding port 53 requires elevated privileges on Linux — run with appropriate capabilities or as root
- Point client devices (or router DNS) to GoAway's host IP to start blocking
- Test with: `nslookup google.com <goaway-ip>` or `dig @<goaway-ip> google.com`
- If dashboard is unreachable, check port 8080 is not blocked by firewall

---

## References
- Documentation: https://pommee.github.io/goaway
- GitHub: https://github.com/pommee/goaway#readme
