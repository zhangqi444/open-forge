# Nutify

**Web-based UPS monitoring and management platform built on Network UPS Tools (NUT) — real-time status, historical telemetry, interactive charts, alerts, scheduled reports, and multi-UPS fleet support.**
GitHub: https://github.com/DartSteven/Nutify
Discord: https://discord.gg/ry82VdKK

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| x86_64 | Docker | dartsteven/nutify:latest-amd64 |
| Apple Silicon (ARM64) | Docker | dartsteven/nutify:latest-mac-arm64 |
| Raspberry Pi 4 (32-bit OS) | Docker | dartsteven/nutify:latest-raspberrypi4-armv7 |
| Raspberry Pi 4/5 (64-bit OS) | Docker | dartsteven/nutify:latest-raspberrypi5-arm64 |

---

## Inputs to Collect

### Required
- `SECRET_KEY` — session/encryption key (change from default)
- UPS connection details — USB device path or network NUT server host/port/username/password
- Monitoring profile — Single or Multi-UPS

---

## Software-Layer Concerns

### Docker Compose
```yaml
services:
  nut:
    image: dartsteven/nutify:latest-amd64   # change tag for your arch
    container_name: Nutify
    privileged: true
    cap_add:
      - SYS_ADMIN
      - SYS_RAWIO
      - MKNOD
    environment:
      - SECRET_KEY=change-this-secret-key
      - UDEV=1
      - SSL_ENABLED=false
    ports:
      - 3493:3493   # NUT daemon
      - 5050:5050   # Nutify web UI
    volumes:
      - ./Nutify/logs:/app/nutify/logs
      - ./Nutify/instance:/app/nutify/instance
      - ./Nutify/ssl:/app/ssl
      - ./Nutify/etc/nut:/etc/nut
      - /dev:/dev:rw
      - /run/udev:/run/udev:ro
    dns:
      - 1.1.1.1
      - 8.8.8.8
    restart: always
    user: root
```

### Ports
- `5050` — Nutify web UI
- `3493` — NUT daemon (for remote UPS clients)

### Setup wizard
On first access, the wizard walks through:
- Monitoring profile: `Single Monitor` or `Multi Monitor`
- Fleet topology: Standalone, Network Server, Network Client, or mixed
- Connection method: Manual config or auto-detect with nut-scanner
- Driver selection, UPS identifier, polling interval, timezone, currency

### ⚠️ Version 0.2.0 breaking change
Not backward compatible with earlier versions. Database must be recreated from scratch. Use a new empty folder — do not reuse data from older installs.

---

## Upgrade Procedure

1. Back up `./Nutify/` data directory
2. docker compose pull
3. docker compose up -d
4. Note: 0.2.0+ is not backward compatible — see breaking change note above

---

## Gotchas

- Requires `privileged: true` and `/dev` access for USB UPS detection
- Change `SECRET_KEY` from the default before deploying
- SSL disabled by default — set `SSL_ENABLED=true` and mount certs to `/app/ssl` to enable
- v0.2.0 is a breaking change — fresh install required when upgrading from older versions

---

## References
- Wiki: https://github.com/DartSteven/Nutify/wiki
- GitHub: https://github.com/DartSteven/Nutify#readme
