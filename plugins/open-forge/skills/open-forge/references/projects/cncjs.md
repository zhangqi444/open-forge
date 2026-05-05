# CNCjs

Full-featured web-based CNC controller interface. CNCjs provides a browser-accessible UI for controlling CNC machines running Grbl, Marlin, Smoothieware, TinyG, or g2core — with 3D tool path visualization, a 6-axis DRO, macros, pendant support, and a plugin/widget system.

**Official site:** https://cnc.js.org/

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Raspberry Pi / Linux | Docker (`cncjs/cncjs`) | Official Docker image; ARM64 supported |
| Raspberry Pi / Linux | npm global install | `npm install -g cncjs`; Node 14+ required |
| macOS / Windows | Desktop App | Electron-based desktop app available |
| Any Linux host | Docker Compose | Standard server deployment |

---

## Inputs to Collect

### Phase 1 — Planning
- CNC controller type: Grbl, Marlin, Smoothieware, TinyG, or g2core
- Serial port path of the CNC controller (e.g. `/dev/ttyUSB0`, `/dev/ttyACM0`)
- Baud rate for the serial connection (commonly 115200)
- Whether to expose the UI over the network (auth recommended)

### Phase 2 — Deployment
- Listen port (default `8000`)
- Config file path (`~/.cncrc`)
- User accounts (set via `--secret` for JWT auth)

---

## Software-Layer Concerns

### Docker Compose

```yaml
services:
  cncjs:
    image: cncjs/cncjs:latest
    container_name: cncjs
    restart: unless-stopped
    ports:
      - "8000:8000"
    devices:
      - "/dev/ttyUSB0:/dev/ttyUSB0"   # CNC controller serial port
    volumes:
      - cncjs-config:/root
    environment:
      - NODE_ENV=production

volumes:
  cncjs-config:
```

> **Note:** Adjust `/dev/ttyUSB0` to match your actual serial device. The container user needs access to the device — on the host, add the user to the `dialout` group: `sudo usermod -aG dialout $USER`.

### npm / Global Install

```bash
# Install Node.js 14+ first (via nvm recommended)
npm install -g cncjs

# Start the server
cncjs --port 8000

# With auth token
cncjs --port 8000 --secret your-secret-key

# Start on boot (PM2)
npm install -g pm2
pm2 start $(which cncjs) -- --port 8000
pm2 save && pm2 startup
```

### Config File (`~/.cncrc`)

```json
{
  "ports": [
    {
      "comName": "/dev/ttyUSB0",
      "manufacturer": ""
    }
  ],
  "baudrates": [115200, 250000],
  "secret": "your-secret-key",
  "allowedMountDirs": ["/home/pi/gcode"]
}
```

### CLI Options
| Flag | Default | Purpose |
|------|---------|---------|
| `-p, --port` | `8000` | HTTP listen port |
| `-H, --host` | `0.0.0.0` | Listen address |
| `--secret` | — | JWT secret for auth |
| `-c, --config` | `~/.cncrc` | Config file path |
| `-m, --mount` | — | Serve static files from a path |
| `-v` | — | Increase verbosity (stack for more) |

---

## Upgrade Procedure

**Docker:** `docker compose pull && docker compose up -d`

**npm:** `npm install -g cncjs@latest`

---

## Gotchas

- **Serial port access in Docker:** Pass the serial device with `devices:` in compose. On Raspberry Pi, the device is often `/dev/ttyACM0` (Arduino-based) or `/dev/ttyUSB0` (FTDI-based).
- **`dialout` group required:** The process user must be in the `dialout` (Linux) or `uucp` (macOS) group to access serial ports without `sudo`.
- **No built-in HTTPS** — run behind Nginx or use a tunnel (Tailscale, Cloudflare) for remote access.
- **Auth via `--secret`:** Without a secret, the UI is open to anyone on the network. Set a secret and use HTTPS for remote access.
- **File sharing:** Use `--mount` to expose a G-code directory in the browser file browser for easy file loading.
- **Multiple clients:** CNCjs supports simultaneous connections from multiple browsers — useful for phone/tablet monitoring.

---

## References
- GitHub: https://github.com/cncjs/cncjs
- Docs/Wiki: https://github.com/cncjs/cncjs/wiki
- Docker Hub: https://hub.docker.com/r/cncjs/cncjs
- Desktop app: https://github.com/cncjs/cncjs/wiki/Desktop-App
